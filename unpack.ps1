$appName = "timingPractice"
Remove-Item $appName -Recurse
7z x "$appName.mlapp" -o"$appName" -r