# Determine Version and Do A Git Push w/ Tags

$addonName = Split-Path $PSScriptRoot -Leaf
$tocFile = "{0}\{1}.toc" -f ($PSScriptRoot, $addonName)

if (Test-Path -Path $tocFile) {
    $contents = Get-Content -Path $tocFile

    # determine the version line
    for ($i = 0; $i -lt $contents.Count; $i++) {
        if ($contents[$i] -match "Version") {
            break;
        }
    }

    # determine the TOC version
    for ($x = 0; $x -lt $contents.Count; $x++) {
        if ($contents[$x] -match "Interface") {
            break;
        }
    }

    # determine interface version
    if ($contents[$x] -match "## Interface: (\d+)") {
        git commit -am ("Updated TOC for {0}." -f $Matches[1])
        git push origin
    }

    # .*_(\d+(\.\d+){1,3})
    if ($contents[$i] -match "## Version: (\d+\.\d+\.\d+)") {
        git tag -a $Matches[1] -m ("{0} Release" -f $Matches[1])
        git push origin --tags
    }
    else {
        Write-Host "Unable to determine addon version."
        Exit
    }
}
else {
    Write-Host "Failed to determine TOC file."
}