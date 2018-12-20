$appName = "timingPractice"
7z d "$appName.mlapp" * -r
7z a "$appName.mlapp" ".\$appName\*"