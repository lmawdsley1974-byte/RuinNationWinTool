& {
    $ErrorActionPreference = 'Stop'

    if ($env:OS -ne 'Windows_NT') {
        throw 'Ruin Nation Win Tool can only be installed on Windows.'
    }

    $repository = 'lmawdsley1974-byte/RuinNationWinTool'
    $releaseUri = "https://api.github.com/repos/$repository/releases/latest"
    $headers = @{
        'Accept' = 'application/vnd.github+json'
        'User-Agent' = 'RuinNationWinTool-Installer'
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    Write-Host 'Finding the latest Ruin Nation Win Tool release...'
    $release = Invoke-RestMethod -Uri $releaseUri -Headers $headers
    $assets = @($release.assets | Where-Object {
        $_.name -match '\ARuinNationWinToolSetup(?:\.\d+)?\.exe\z'
    })

    if ($assets.Count -ne 1) {
        throw "Expected one RuinNationWinToolSetup.exe release asset, but found $($assets.Count)."
    }

    $asset = $assets[0]
    if ($asset.digest -notmatch '\Asha256:([0-9a-fA-F]{64})\z') {
        throw 'GitHub did not provide a valid SHA-256 digest for the installer; refusing to run an unverified download.'
    }

    $expectedHash = $Matches[1].ToLowerInvariant()
    $downloadUri = [Uri]$asset.browser_download_url
    if ($downloadUri.Scheme -ne 'https' -or $downloadUri.Host -ne 'github.com') {
        throw 'GitHub returned an unexpected installer download URL.'
    }

    $temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) "RuinNationWinTool-$([Guid]::NewGuid().ToString('N'))"
    $installerPath = Join-Path $temporaryDirectory $asset.name
    $previousProgressPreference = $ProgressPreference

    try {
        $ProgressPreference = 'SilentlyContinue'
        New-Item -ItemType Directory -Path $temporaryDirectory -ErrorAction Stop | Out-Null

        Write-Host "Downloading $($release.name)..."
        Invoke-WebRequest -Uri $downloadUri.AbsoluteUri -OutFile $installerPath -Headers $headers

        if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
            throw 'The installer download did not create the expected file.'
        }

        $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            throw 'The installer SHA-256 hash does not match GitHub''s release metadata; the file will not be run.'
        }

        Write-Host 'Download verified. Starting the installer...'
        $process = Start-Process -FilePath $installerPath -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "The installer exited with code $($process.ExitCode)."
        }

        Write-Host 'Ruin Nation Win Tool was installed successfully.'
    }
    finally {
        $ProgressPreference = $previousProgressPreference
        if (Test-Path -LiteralPath $temporaryDirectory -PathType Container) {
            try {
                Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "Could not remove temporary installer files at '$temporaryDirectory': $($_.Exception.Message)"
            }
        }
    }
}
