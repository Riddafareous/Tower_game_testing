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
    if ($folder.Name -match 'map_(\d+)') {
        $indexedFolders += [PSCustomObject]@{
            Folder = $folder
            Index  = [int]$matches[1]
        }
    }
}

# Determine default Start if not provided
if (-not $PSBoundParameters.ContainsKey('Start')) {
    if ($Direction -eq "Up") {
        $Start = 0
    }
    elseif ($Direction -eq "Down") {
        $Start = ($indexedFolders | Measure-Object -Property Index -Maximum).Maximum
    }
}

Write-Host "Direction: $Direction"
Write-Host "Start index: $Start"

if ($Direction -eq "Up") {

    # Process descending
    $sorted = $indexedFolders | Sort-Object Index -Descending

    foreach ($item in $sorted) {

        $folder = $item.Folder
        $num = $item.Index

        if ($num -ge $Start) {

            $newNum = $num + 1

            $oldFolderPath = $folder.FullName
            $newFolderName = "map_{0:D2}" -f $newNum
            $newFolderPath = Join-Path (Split-Path $oldFolderPath) $newFolderName

            Rename-Item $oldFolderPath $newFolderName

            $oldFile = Join-Path $newFolderPath ("map_{0:D2}.txt" -f $num)
            $newFile = Join-Path $newFolderPath ("map_{0:D2}.txt" -f $newNum)

            if (Test-Path $oldFile) {
                Rename-Item $oldFile $newFile
            }
        }
    }
}

elseif ($Direction -eq "Down") {

    # Process ascending
    $sorted = $indexedFolders | Sort-Object Index

    foreach ($item in $sorted) {

        $folder = $item.Folder
        $num = $item.Index

        if ($num -ge $Start) {

            if ($num -eq 0) { continue }

            $newNum = $num - 1

            $oldFolderPath = $folder.FullName
            $newFolderName = "map_{0:D2}" -f $newNum
            $newFolderPath = Join-Path (Split-Path $oldFolderPath) $newFolderName

            # Prevent overwrite
            if (Test-Path $newFolderPath) {
                Write-Host "Skipping $($folder.Name) → $newFolderName (target exists)"
                continue
            }

            Rename-Item $oldFolderPath $newFolderName

            $oldFile = Join-Path $newFolderPath ("map_{0:D2}.txt" -f $num)
            $newFile = Join-Path $newFolderPath ("map_{0:D2}.txt" -f $newNum)

            if (Test-Path $oldFile) {
                Rename-Item $oldFile $newFile
            }
        }
    }
}