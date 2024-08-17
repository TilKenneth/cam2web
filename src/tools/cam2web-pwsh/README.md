# Cam2Web-Pwsh

A tooling attempt to use Powershell to manage cam2web on Windows.

## Examples

- Start cam2web.exe normally, set up your settings so that cam2web.cfg gets created.
- Use the Powershell of your system.

### Normal start / stop

```pwsh
# $cam is a [System.Diagnostics.Process] object, it's for convenience for now.
$cam = (Start-Cam2Web -ConfigFilePath "$Env:UserProfile\cam2web\cam2web.cfg")
$url = Get-Cam2WebUrl
Stop-Cam2web
```

### Auto start / stop

```pwsh
$cam = (Start-Cam2Web -ConfigFilePath "$Env:UserProfile\cam2web\cam2web.cfg" -AutoStart)
$url = Get-Cam2WebUrl
Stop-Cam2web
```

### Hidden auto start / forced stop

```pwsh
$cam = (Start-Cam2Web -ConfigFilePath "$Env:UserProfile\cam2web\cam2web.cfg" -AutoStart -StartHidden)
$url = Get-Cam2WebUrl
Stop-Cam2web -Force
```
