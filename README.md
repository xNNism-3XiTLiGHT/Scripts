# Powershell scripts

| script | description |
|----------|--------|
| drive-speedtest.ps1 | Test USB flash drives to measure read and write speed |

#

### drive-speedtest.ps1

Set Execution policy before: 
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```


Execute with:
 ```
 .\drive-speedtest.ps1
 ```
- Enter the USB drive letter, e.g. E: D 
- Enter the test file size in MB, e.g. 1024, 512, 128
#