$appName = "timingPractice"  # Name of the app file, without extension
Remove-Item $appName -Recurse  # If exists, delete old unzipped folder
7z x "$appName.mlapp" -o"$appName" -r  # Unzip the .mlapp folder to a folder