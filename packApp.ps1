$appName = "timingPractice"  # Name of the app file, without extension
if (Test-Path "$appName.mlapp") {  # Check if .mlapp file exists
    7z d "$appName.mlapp" * -r  # Remove all contents of the zip archive
    7z a "$appName.mlapp" ".\$appName\*"  # Add everything from the unzipped folder to the archive
} else {
    # If the .mlapp is created by 7zip, MATLAB will not be able to open it.
    # Adding to an existing .mlapp file using 7zip works fine.
    Write-Error "Cannot pack without the .mlapp file. First create an empty/new app called $appName.mlapp using MATLAB's 'appdesigner' command."
}