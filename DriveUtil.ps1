param (
    [Parameter(Mandatory=$true, ParameterSetName='Install')]
    [Parameter(Mandatory=$true, ParameterSetName='Uninstall')]
    [ValidateSet('Install', 'Uninstall')]
    [string]$Action = 'Install',

    [Parameter(Mandatory=$true, ParameterSetName='Install')]
    [Parameter(Mandatory=$true, ParameterSetName='Uninstall')]
    [string]$Name,

    [Parameter(Mandatory=$true, ParameterSetName='Install')]
    [string]$Path,
    [boolean]$Persist = $true,
    [boolean]$Force =$false,
    [ValidateSet('FileSystem', 'Registry')]
    [string]$PsProvider = 'FileSystem',
    [ValidateSet('Global', 'Local', 'Script')]
    [string]$Scope = 'Global'
)

$TranscriptionFile = 'DriveUtil.txt'
$TranscriptionPath = Join-Path $env:ALLUSERSPROFILE $TranscriptionFile

$param = @{
    Name = $Name
    Root = $Path
    Persist = $Persist
    PSProvider = $PSProvider
    Scope = $Scope
}


if ($Action -eq 'Install') 
{
$message = "$((Get-Date).ToString()) - Trying to Map $Path on $Name for $env:USERNAME"
$Message | Out-File $TranscriptionPath -Append
Write-Host $Message
    try
    {
        if ($Force) {
            $Message = "$((Get-Date).ToString()) - Forcing removal of $Name to ensure it is available for mapping"
            $Message | Out-File $TranscriptionPath -Append
            Write-Host $Message   
            Start-Process ".\MapDrive.exe" -ArgumentList "-Action Uninstall -Name $Name" -Wait
        }
        New-PSDrive @param -ErrorAction Stop
        $Message = "$((Get-Date).ToString()) - Succefully Mapped $Path on $Name for $env:USERNAME"
        $Message | Out-File $TranscriptionPath -Append
        Write-Host $Message   
    }
    catch
    {
        $item = $PSitem
        switch ($PSitem.FullyQualifiedErrorId) {
            "DriveRootNotNetworkPath,Microsoft.PowerShell.Commands.NewPSDriveCommand" 
            {
                $Message = "$((Get-Date).ToString()) - $($item.Exception.message). Set '-Persist' to '$false' to correct the issue."
                $Message | Out-File $TranscriptionPath -Append
                Write-Error $Message
            }
            "DriveAlreadyExists,Microsoft.PowerShell.Commands.NewPSDriveCommand" 
            {
                $Message = "$((Get-Date).ToString()) - $($item.Exception.message). Set '-Force' to '$true' to overwrite the existing share."
                $Message | Out-File $TranscriptionPath -Append
                Write-Error $Message
            }
            "DriveRootError,Microsoft.PowerShell.Commands.NewPSDriveCommand" 
            {
                $Message = "$((Get-Date).ToString()) - $($item.Exception.message). Please check if the path $Path exist."
                $Message | Out-File $TranscriptionPath -Append
                Write-Error $Message
            }
            "DriveNameNotSupportedForPersistence,Microsoft.PowerShell.Commands.NewPSDriveCommand" 
            {
                $Message = "$((Get-Date).ToString()) - $($item.Exception.message). Set '-Persist' to '$false' or change the '-Name'."
                $Message | Out-File $TranscriptionPath -Append
                Write-Error $Message
            }
            "CouldNotMapNetworkDrive,Microsoft.PowerShell.Commands.NewPSDriveCommand" 
            {
                switch ($item.exception.message) {
                    "The local device name is already in use"
                    {
                        $Message = "$((Get-Date).ToString()) - $($item.Exception.message). Set '-Force' to '$true' to overwrite the existing share."
                        $Message | Out-File $TranscriptionPath -Append
                        Write-Error $Message
                    }
                    "The local device name has a remembered connection to another network resource"
                    {
                        $Message = "$((Get-Date).ToString()) - $($item.Exception.message). Set '-Force' to '$true' to overwrite the existing share."
                        $Message | Out-File $TranscriptionPath -Append
                        Write-Error $Message
                    }
                    "The network resource type is not correct"
                    {
                        $Message = "$((Get-Date).ToString()) - $($item.Exception.message). The path $Path does not exist or is not reachable."
                        $Message | Out-File $TranscriptionPath -Append
                        Write-Error $Message
                    }
                }
            }
            default {
                throw $item
            }
        }
    }
}

if ($Action -eq 'Uninstall') 
{
$Message = "$((Get-Date).ToString()) - Trying to Remove $Name for $env:USERNAME"
$Message | Out-File $TranscriptionPath -Append
Write-Host $Message
    try 
    {
        Remove-PSDrive -Name $Name -ErrorAction Stop
        $Message = "$((Get-Date).ToString()) - $($item.Exception.message)The Drive has been successfully Uninstalled"
        $Message | Out-File $TranscriptionPath -Append
        Write-Host $Message        
    }
    catch 
    {
        $item = $PSitem
        switch ($PSitem.FullyQualifiedErrorId) {
            "DriveNotFound,Microsoft.PowerShell.Commands.RemovePSDriveCommand"
            {
                $Message = "$((Get-Date).ToString()) - $($item.Exception.message)The Drive is not present"
                $Message | Out-File $TranscriptionPath -Append
                Write-Host $Message
            }
            default {
                throw $item
            }
        }
    }
}