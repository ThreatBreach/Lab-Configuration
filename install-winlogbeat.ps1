# create the template as Here-String
$template = @"
winlogbeat.event_logs:
  - name: Application

  - name: System

  - name: Security

  - name: ForwardedEvents
    tags: [forwarded]

  - name: Windows PowerShell


  - name: Microsoft-Windows-PowerShell/Operational

  - name: Microsoft-windows-sysmon/Operational


# ====================== Elasticsearch template settings =======================

setup.template.settings:
  index.number_of_shards: 1


output.logstash:
    hosts: ["{0}:5044"]

# ================================= Processors =================================
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~

path.data: "{1}"
path.home: "{1}"
path.logs: "{1}"
"@

param (
    [string]$IPAddress
)
# Get the directory of the script
$workdir = Split-Path $MyInvocation.MyCommand.Path

# Define the path of the directory you want to check/create
$pathString = "C:\Program Files\winlogbeat-elk"

# Check if the directory exists
if (-Not (Test-Path -Path $pathString -PathType Container)) {
    # If the directory does not exist, create it
    mkdir $pathString
    Write-Output "Directory created: $pathString"
} else {
    # If the directory exists, skip the creation
    Write-Output "Directory already exists: $pathString"
}

mkdir "$pathString\elk-fleet"

$template -f $IPAddress, "$pathString\elk-fleet" | Add-Content -Path "$pathString\elk-fleet\winlogbeat-elk.yml"
New-Service -name winlogbeat-elk `
  -displayName Winlogbeat-elk `
  -binaryPathName "`"$workdir\winlogbeat.exe`" --environment=windows_service -c `"$pathString\elk-$counter\winlogbeat-elk.yml`"  -E logging.files.redirect_stderr=true"


Try {
  Start-Process -FilePath sc.exe -ArgumentList 'config winlogbeat start= delayed-auto'
}
Catch { Write-Host -f red "An error occured setting the service to delayed start." }



