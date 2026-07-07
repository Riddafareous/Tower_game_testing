param(
    [ValidateSet("Up", "Down")]
    [string]$Direction = "Up",

    [int]$Start
)

Set-Location $PSScriptRoot

# Get all map folders
$folders = Get-ChildItem -Directory "map_*"

# Extract numeric indices
$indexedFolders = @()
foreach ($folder in $folders) {
    if ($folder.Name -match '^map_(\d+)$') {
        $indexedFolders += [PSCustomObject]@{
            Folder = $folder
            Index  = [int]$matches[1]
        }
    }
}

if ($indexedFolders.Count -eq 0) {
    Write-Host "No map folders found."
    return
}

# Determine default Start
if (-not $PSBoundParameters.ContainsKey('Start')) {
    if ($Direction -eq "Up") {
        $Start = 0
    }
    elseif ($Direction -eq "Down") {
        $Start = 1   # preserve map_00
    }
}

Write-Host "Direction: $Direction"
Write-Host "Start index: $Start"

# Sort
if ($Direction -eq "Up") {
    $sorted = $indexedFolders | Sort-Object Index -Descending
}
else {
    $sorted = $indexedFolders | Sort-Object Index
}

# -------------------------
# PASS 1: rename folders → temp
# -------------------------
foreach ($item in $sorted) {

    $num = $item.Index

    if ($num -lt $Start) { continue }
    if ($Direction -eq "Down" -and $num -eq 0) { continue }

    $oldPath = $item.Folder.FullName
    $tempPath = Join-Path $item.Folder.Parent.FullName ($item.Folder.Name + "_tmp")

    Rename-Item $oldPath $tempPath
}

# Refresh list of temp folders
$tempFolders = Get-ChildItem -Directory "map_*_tmp"

# -------------------------
# PASS 2: rename temp → final
# -------------------------
foreach ($folder in $tempFolders) {

    if ($folder.Name -match '^map_(\d+)_tmp$') {

        $num = [int]$matches[1]

        if ($Direction -eq "Up") {
            if ($num -lt $Start) { continue }
            $newNum = $num + 1
        }
        else {
            if ($num -lt $Start -or $num -eq 0) { continue }
            $newNum = $num - 1
        }

        $newFolderName = "map_{0:D2}" -f $newNum
        $newFolderPath = Join-Path $folder.Parent.FullName $newFolderName

        # Rename folder
        Rename-Item $folder.FullName $newFolderName

        # Rename internal file
        $oldFile = Join-Path $newFolderPath ("map_{0:D2}.txt" -f $num)
        $newFile = Join-Path $newFolderPath ("map_{0:D2}.txt" -f $newNum)

        if (Test-Path $oldFile) {
            Rename-Item $oldFile $newFile
        }
    }
}

Write-Host "Done."