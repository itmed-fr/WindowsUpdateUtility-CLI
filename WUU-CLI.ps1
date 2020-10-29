<#
.SYNOPSIS
This script provides a GUI for remotely managing Windows Updates.

.DESCRIPTION
This script provides a GUI for remotely managing Windows Updates. You can check for, download, and install updates remotely. There is also an option to automatically reboot the Computer after installing updates if required.

.EXAMPLE
.\WUU-CLI.ps1

This example open the Windows Update Utility.

.NOTES
Author: Tyler Siegrist
Date: 12/14/2016

This script needs to be run as an administrator with the credentials of an administrator on the remote Computers.

There is limited feedback on the download and install processes due to Microsoft restricting the ability to remotely download or install Windows Updates. This is done by using psexec to run a script locally on the remote machine.
#>

#region collections
$ComputersList = [System.Collections.ArrayList]::new()
#endregion collections

#region Environment validation
#Validate user is an Administrator
Write-Verbose 'Checking Administrator credentials.'
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script must be elevated!`nNow attempting to elevate."
    Start-Process -Verb 'Runas' -FilePath 'PowerShell.exe' -ArgumentList "-STA -NoProfile -WindowStyle Hidden -File `"$($MyInvocation.MyCommand.Definition)`""
    Break
}

#Ensure that we are running the GUI from the correct location so that scripts & psexec can be accessed.
Set-Location $(Split-Path $MyInvocation.MyCommand.Path)

#Check for PsExec
Write-Verbose 'Checking for psexec.exe.'
if (-Not (Test-Path psexec.exe)) {
    Write-Warning ("Psexec.exe missing from {0}!`n Please place file in the path so WUU can work properly" -f (Split-Path $MyInvocation.MyCommand.Path))
    Break
}

#Determine if this instance of PowerShell can run WPF (required for GUI)
Write-Verbose 'Checking the apartment state.'
if ($host.Runspace.ApartmentState -ne 'STA') {
    Write-Warning "This script must be run in PowerShell started using -STA switch!`nScript will attempt to open PowerShell in STA and run re-run script."
    Start-Process -File PowerShell.exe -Argument "-STA -NoProfile -WindowStyle Hidden -File `"$($myinvocation.mycommand.definition)`""
    Break
}
#endregion Environment validation


#region ScriptBlocks
#Add new Computer(s) to list
$AddEntry = {
    Param ($ComputerName)
    Write-Verbose "Adding $ComputerName."

    #Add to list
    foreach ($Computer in $ComputerName) {
        $Computer = $Computer.Trim() #Remove any whitspace
        if ([System.String]::IsNullOrEmpty($Computer)) {continue} #Do not add if name empty
        if (($DisplayHash.Listview.Items | Select-Object -Expand Computer) -contains $Computer) {continue} #Do not add duplicate

        $ComputersList.Add((
                        New-Object PSObject -Property @{
                            Computer       = $Computer
                            Available      = 0 -as [int]
                            Downloaded     = 0 -as [int]
                            InstallErrors  = 0 -as [int]
                            Status         = "Initalizing."
                            RebootRequired = $false -as [bool]
                            Runspace       = $null
                        }))
    }
}


#Download available updates
$DownloadUpdates = {
    Param ($Computer)
    Try {
        #Set path for psexec, scripts
        Set-Location $Path

        #Check download size
        $DownloadStats = ($UpdatesHash[$Computer.Computer] | Where-Object {$_.IsDownloaded -eq $false} | Select-Object -ExpandProperty MaxDownloadSize | Measure-Object -Sum)

        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = "Downloading $($DownloadStats.Count) Updates ($([math]::Round($DownloadStats.Sum/1MB))MB)."
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Copy script to remote Computer and execute
        if ( ! ( Test-Path -Path "\\$($Computer.Computer)\C$\Admin\Scripts") ) {
            New-Item -Path "\\$($Computer.Computer)\C$\Admin\Scripts" -ItemType Directory
        }
        Copy-Item '.\Scripts\UpdateDownloader.ps1' "\\$($Computer.Computer)\c$\Admin\Scripts" -Force
        [int]$DownloadCount = .\PsExec.exe -accepteula -nobanner -s "\\$($Computer.Computer)" cmd.exe /c 'echo . | powershell.exe -ExecutionPolicy Bypass -file C:\Admin\Scripts\UpdateDownloader.ps1'
        Remove-Item "\\$($Computer.Computer)\c$\Admin\Scripts\UpdateDownloader.ps1"
        if ($LASTEXITCODE -ne 0) {
            throw "PsExec failed with error code $LASTEXITCODE"
        }

        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Download complete.'
                $Computer.Downloaded += $DownloadCount
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })
    }
    catch {
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = "Error occured: $($_.Exception.Message)"
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Cancel any remaining actions
        exit
    }
}

#Check for available updates
$GetUpdates = {
    Param ($Computer)
    Try {
        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Checking for updates, this may take some time.'
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        Set-Location $path

        #Check for updates
        $UpdateSession = [activator]::CreateInstance([type]::GetTypeFromProgID('Microsoft.Update.Session', $Computer.Computer))
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
        $SearchResult = $UpdateSearcher.Search('IsInstalled=0 and IsHidden=0')

        #Save update info in hash to view with 'Show Available Updates'
        $UpdatesHash[$Computer.Computer] = $SearchResult.Updates

        #Update status
        $DownloadCount = @($SearchResult.Updates | Where-Object {$_.IsDownloaded -eq $true}).Count
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Available = $SearchResult.Updates.Count
                $Computer.Downloaded = $DownloadCount
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Don't bother checking for reboot if there is nothing to be pending.
        # if ($DownloadCount -gt 0) {
        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Checking for a pending reboot.'
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Check if there is a pending update

        $rebootRequired = (.\PsExec.exe -accepteula -nobanner -s "\\$($Computer.Computer)" cmd.exe /c 'echo . | powershell.exe -ExecutionPolicy Bypass -Command "&{return (New-Object -ComObject "Microsoft.Update.SystemInfo").RebootRequired}"') -eq $true

        if ($LASTEXITCODE -ne 0) {
            throw "PsExec failed with error code $LASTEXITCODE"
        }

        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.RebootRequired = [bool]$rebootRequired
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })
        # }

        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Finished checking for updates.'
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })
    }
    catch {
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = "Error occured: $($_.Exception.Message)"
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Cancel any remaining actions
        exit
    }
}

#
#Install downloaded updates
$InstallUpdates = {
    Param ($Computer)
    Try {
        #Set path for psexec, scripts
        Set-Location $path

        #Update status
        $installCount = ($UpdatesHash[$Computer.Computer] | Where-Object {$_.IsDownloaded -eq $true -and $_.InstallationBehavior.CanRequestUserInput -eq $false} | Measure-Object).Count
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = "Installing $installCount Updates, this may take some time."
                $Computer.InstallErrors = 0
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Copy script to remote Computer and execute
        if ( ! ( Test-Path -Path "\\$($Computer.Computer)\C$\Admin\Scripts") ) {
            New-Item -Path "\\$($Computer.Computer)\C$\Admin\Scripts" -ItemType Directory
        }
        Copy-Item .\Scripts\UpdateInstaller.ps1 "\\$($Computer.Computer)\C$\Admin\Scripts" -Force
        [int]$installErrors = .\PsExec.exe -accepteula -nobanner -s "\\$($Computer.Computer)" cmd.exe /c 'echo . | powershell.exe -ExecutionPolicy Bypass -file C:\Admin\Scripts\UpdateInstaller.ps1'
        Remove-Item "\\$($Computer.Computer)\C$\Admin\Scripts\UpdateInstaller.ps1"
        if ($LASTEXITCODE -ne 0) {
            throw "PsExec failed with error code $LASTEXITCODE"
        }

        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Checking if a reboot is required.'
                $Computer.InstallErrors = $installErrors
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Check if any updates require reboot
        $rebootRequired = (.\PsExec.exe -accepteula -nobanner -s "\\$($Computer.Computer)" cmd.exe /c 'echo . | powershell.exe -ExecutionPolicy Bypass -Command "&{return (New-Object -ComObject "Microsoft.Update.SystemInfo").RebootRequired}"') -eq $true
        if ($LASTEXITCODE -ne 0) {
            throw "PsExec failed with error code $LASTEXITCODE"
        }

        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Install complete.'
                $Computer.RebootRequired = [bool]$rebootRequired
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })
    }
    catch {
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = "Error occured: $($_.Exception.Message)"
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Cancel any remaining actions
        exit
    }
}

#Remove Computer(s) from list
$RemoveEntry = {
    Param ($Computers)

    #Remove Computers from list
    foreach ($Computer in $Computers) {
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $DisplayHash.clientObservable.Remove($Computer)
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })
    }

    $CleanUp = {
        Param($Computers)
        foreach ($Computer in $Computers) {
            $UpdatesHash.Remove($Computer.Computer)
            $Computer.Runspace.Dispose()
        }
    }

    $NewRunspace = [runspacefactory]::CreateRunspace()
    $NewRunspace.ApartmentState = "STA"
    $NewRunspace.ThreadOptions = "ReuseThread"
    $NewRunspace.Open()
    $NewRunspace.SessionStateProxy.SetVariable("DisplayHash", $DisplayHash)
    $NewRunspace.SessionStateProxy.SetVariable("UpdatesHash", $UpdatesHash)

    $PowerShell = [powershell]::Create().AddScript($CleanUp).AddArgument($Computers)
    $PowerShell.Runspace = $NewRunspace

    #Save handle so we can later end the runspace
    $Temp = New-Object PSObject -Property @{
        PowerShell = $PowerShell
        Runspace   = $PowerShell.BeginInvoke()
    }

    $Jobs.Add($Temp) | Out-Null
}

#Remove Computer that cannot be pinged
$RemoveOfflineComputer = {
    Param ($Computer, $RemoveEntry)
    try {
        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Testing Connectivity.'
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })
        #Verify connectivity
        if (Test-Connection -Count 1 -ComputerName $Computer.Computer -Quiet) {
            $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                    $DisplayHash.Listview.Items.EditItem($Computer)
                    $Computer.Status = 'Online.'
                    $DisplayHash.Listview.Items.CommitEdit()
                    $DisplayHash.Listview.Items.Refresh()
                })
        }
        else {
            #Remove unreachable Computers
            $UpdatesHash.Remove($Computer.Computer)
            $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                    $DisplayHash.Listview.Items.EditItem($Computer)
                    $DisplayHash.clientObservable.Remove($Computer)
                    $DisplayHash.Listview.Items.CommitEdit()
                    $DisplayHash.Listview.Items.Refresh()
                })
        }
    }
    catch {
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = "Error occured: $($_.Exception.Message)"
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Cancel any remaining actions
        exit
    }
}

#Report status to WSUS server
$ReportStatus = {
    Param ($Computer)
    try {
        #Set path for psexec, scripts
        Set-Location $Path

        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Reporting status to WSUS server.'
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        $ExecStatus = .\PsExec.exe -accepteula -nobanner -s "\\$($Computer.Computer)" cmd.exe /c 'echo . | wuauclt /reportnow'
        if ($LASTEXITCODE -ne 0) {
            throw "PsExec failed with error code $LASTEXITCODE"
        }

        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Finished updating status.'
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })
    }
    catch {
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = "Error occured: $($_.Exception.Message)"
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Cancel any remaining actions
        exit
    }
}

#Reboot remote Computer
$RestartComputer = {
    Param ($Computer, $afterInstall)
    try {
        #Avoid auto reboot if not enabled and required
        if ($afterInstall -and (-not $Computer.RebootRequired -or -not $DisplayHash.AutoRebootCheckBox.IsChecked)) {return}
        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Restarting... Waiting for Computer to shutdown.'
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Restart and wait until remote COM can be connected
        Restart-Computer $Computer.Computer -Force
        while (Test-Connection -Count 1 -ComputerName $Computer.Computer -Quiet) { Start-Sleep -Milliseconds 500 } #Wait for Computer to go offline

        #Update status
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Restarting... Waiting for Computer to come online.'
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        while ($true) {
            #Wait for Computer to come online
            Start-Sleep -Seconds 5
            try {
                [activator]::CreateInstance([type]::GetTypeFromProgID('Microsoft.Update.Session', $Computer.Computer))
                Break
            }
            catch {
                Start-Sleep -Seconds 5
            }
        }
    }
    catch {
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = 'Error occured: $($_.Exception.Message)'
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Cancel any remaining actions
        exit
    }
}

#Start, stop, or restart Windows Update Service
$WUServiceAction = {
    Param($Computer, $Action)
    try {
        #Start Windows Update Service
        if ($Action -eq 'Start') {
            #Update status
            $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                    $DisplayHash.Listview.Items.EditItem($Computer)
                    $Computer.Status = 'Starting Windows Update Service'
                    $DisplayHash.Listview.Items.CommitEdit()
                    $DisplayHash.Listview.Items.Refresh()
                })

            #Start service
            Get-Service -ComputerName $($Computer.Computer) -Name 'wuauserv' -ErrorAction Stop | Start-Service -ErrorAction Stop

            #Update status
            $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                    $DisplayHash.Listview.Items.EditItem($Computer)
                    $Computer.Status = 'Windows Update Service Started'
                    $DisplayHash.Listview.Items.CommitEdit()
                    $DisplayHash.Listview.Items.Refresh()
                })
        }

        #Stop Windows Update Service
        elseif ($Action -eq 'Stop') {
            #Update status
            $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                    $DisplayHash.Listview.Items.EditItem($Computer)
                    $Computer.Status = 'Stopping Windows Update Service'
                    $DisplayHash.Listview.Items.CommitEdit()
                    $DisplayHash.Listview.Items.Refresh()
                })

            #Stop service
            Get-Service -ComputerName $Computer.Computer -Name wuauserv -ErrorAction Stop | Stop-Service -ErrorAction Stop

            #Update status
            $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                    $DisplayHash.Listview.Items.EditItem($Computer)
                    $Computer.Status = 'Windows Update Service Stopped'
                    $DisplayHash.Listview.Items.CommitEdit()
                    $DisplayHash.Listview.Items.Refresh()
                })
        }

        #Restart Windows Update Service
        elseif ($Action -eq 'Restart') {
            #Update status
            $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                    $DisplayHash.Listview.Items.EditItem($Computer)
                    $Computer.Status = 'Restarting Windows Update Service'
                    $DisplayHash.Listview.Items.CommitEdit()
                    $DisplayHash.Listview.Items.Refresh()
                })

            #Restart service
            Get-Service -ComputerName $Computer.Computer -Name wuauserv -ErrorAction Stop | Restart-Service -ErrorAction Stop

            #Update status
            $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                    $DisplayHash.Listview.Items.EditItem($Computer)
                    $Computer.Status = 'Windows Update Service Restarted'
                    $DisplayHash.Listview.Items.CommitEdit()
                    $DisplayHash.Listview.Items.Refresh()
                })
        }

        #Invalid action
        else {
            Write-Error 'Invalid action specified.'
        }
    }
    catch {
        $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                $DisplayHash.Listview.Items.EditItem($Computer)
                $Computer.Status = "Error occured: $($_.Exception.Message)"
                $DisplayHash.Listview.Items.CommitEdit()
                $DisplayHash.Listview.Items.Refresh()
            })

        #Cancel any remaining actions
        exit
    }
}

$ReadFileAndAddComputer = { #Add Computers from a file

    $FilePath = "C:\scripts\computerlist.txt"
    If( Test-Path -Path $FilePath )
    {
        $entries = (Get-Content $FilePath | Where {$_ -ne ''}) #Parse
        &$AddEntry $entries #Add Computers
    }
}
#endregion ScriptBlocks




$eventGetUpdates = {
    $DisplayHash.Listview.SelectedItems | % {
        $Temp = "" | Select-Object PowerShell, Runspace
        $Temp.PowerShell = [powershell]::Create().AddScript($GetUpdates).AddArgument($_)
        $Temp.PowerShell.Runspace = $_.Runspace
        $Temp.Runspace = $Temp.PowerShell.BeginInvoke()
        $Jobs.Add($Temp) | Out-Null
    }
}
$eventDownloadUpdates = {
    $DisplayHash.Listview.SelectedItems | % {
        #Don't bother downloading if nothing available.
        if ($_.Available -eq $_.Downloaded) {
            #Update status
            $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                    $DisplayHash.Listview.Items.EditItem($_)
                    $_.Status = 'There are no updates available to download.'
                    $DisplayHash.Listview.Items.CommitEdit()
                    $DisplayHash.Listview.Items.Refresh()
                })
            return
        }

        $Temp = "" | Select-Object PowerShell, Runspace
        $Temp.PowerShell = [powershell]::Create().AddScript($DownloadUpdates).AddArgument($_)
        $Temp.PowerShell.Runspace = $_.Runspace
        $Temp.Runspace = $Temp.PowerShell.BeginInvoke()
        $Jobs.Add($Temp) | Out-Null
    }
}
$eventInstallUpdates = {
    $DisplayHash.Listview.SelectedItems | % {
        #Check if there are any updates that are downloaded and don't require user input
        if (-not ($UpdatesHash[$_.Computer] | Where-Object {$_.IsDownloaded -and $_.InstallationBehavior.CanRequestUserInput -eq $false})) {
            #Update status
            $DisplayHash.ListView.Dispatcher.Invoke('Background', [action] {
                    $DisplayHash.Listview.Items.EditItem($_)
                    $_.Status = 'There are no updates available that can be installed remotely.'
                    $DisplayHash.Listview.Items.CommitEdit()
                    $DisplayHash.Listview.Items.Refresh()
                })

            #No need to continue if there are no updates to install.
            return
        }

        $Temp = "" | Select-Object PowerShell, Runspace
        $Temp.PowerShell = [powershell]::Create().AddScript($InstallUpdates).AddArgument($_)
        $Temp.PowerShell.AddScript($RestartComputer).AddArgument($_).AddArgument($true)
        # $Temp.PowerShell.AddScript($GetUpdates).AddArgument($_)
        $Temp.PowerShell.Runspace = $_.Runspace
        $Temp.Runspace = $Temp.PowerShell.BeginInvoke()
        $Jobs.Add($Temp) | Out-Null
    }
}

$eventWUServiceAction = {
    Param ($Action)
    $DisplayHash.Listview.SelectedItems | % {
        $Temp = "" | Select-Object PowerShell, Runspace
        $Temp.PowerShell = [powershell]::Create().AddScript($WUServiceAction).AddArgument($_).AddArgument($Action)
        $Temp.PowerShell.Runspace = $_.Runspace
        $Temp.Runspace = $Temp.PowerShell.BeginInvoke()
        $Jobs.Add($Temp) | Out-Null
    }
}
#endregion Event ScriptBlocks

&$ReadFileAndAddComputer
