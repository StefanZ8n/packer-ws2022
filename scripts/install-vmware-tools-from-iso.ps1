$exe = "E:\setup64.exe"
Write-Output "***** Wait for VMware Tools ISO to be mounted and available"
do {
    $exeAvailable = Test-Path $exe
    Start-Sleep -Seconds 5    
} until ($exeAvailable)

$parametersInstall = '/S /l C:\Windows\Temp\vmw-tools.log /v "/qn REBOOT=R ADDLOCAL=ALL"'
$parametersUninstall = '/S /v "/qn REBOOT=R REMOVE=ALL"'
Write-Output "***** Installing VMWare Guest Tools"

while ($true) {
    Start-Process $exe $parametersInstall -Wait

    Start-Sleep -s 10
    $Service = Get-Service "VMTools" -ErrorAction SilentlyContinue
    if ($Service.Status -notlike "Running") {
        Start-Process $exe $parametersUninstall -Wait
    } else {
        break
    }
}
