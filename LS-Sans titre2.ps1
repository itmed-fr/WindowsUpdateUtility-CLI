$ComputersList = [System.Collections.ArrayList]::new()

$AddEntry = {
    Param ($ComputerName)
    Write-Verbose "Adding $ComputerName."

    #Add to list
    foreach ($Computer in $ComputerName) {
        $Computer = $Computer.Trim() #Remove any whitspace
        if ([System.String]::IsNullOrEmpty($Computer)) {continue} #Do not add if name empty
        #if (($ComputersList.Listview.Items | Select-Object -Expand Computer) -contains $Computer) {continue} #Do not add duplicate

        $ComputersList.Add($Computer)
		Write-Verbose "$ComputerName added."
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

$DownloadUpdates = {
    Param ($Computer)
	Write-Verbose "$Computer downloading updates."
    Try {
        #Set path for psexec, scripts
        Set-Location $Path
		Write-Host "Dans le try"

        #Copy script to remote Computer and execute
        if ( ! ( Test-Path -Path "\\$($Computer.Computer)\C$\Admin\Scripts") ) {
            New-Item -Path "\\$($Computer.Computer)\C$\Admin\Scripts" -ItemType Directory
        }
        Copy-Item '.\Scripts\UpdateDownloader.ps1' "\\$($Computer.Computer)\c$\Admin\Scripts" -Force
        [int]$DownloadCount = .\PsExec.exe -accepteula -nobanner -s "\\$($Computer.Computer)" cmd.exe /c 'echo . | powershell.exe -ExecutionPolicy Bypass -file C:\Admin\Scripts\UpdateDownloader.ps1'
		Write-Verbose $DownloadCount
        Remove-Item "\\$($Computer.Computer)\c$\Admin\Scripts\UpdateDownloader.ps1"
        if ($LASTEXITCODE -ne 0) {
            throw "PsExec failed with error code $LASTEXITCODE"
        }
    }
    catch {
        #Cancel any remaining actions
		Write-Verbose "exit"
        exit
    }
}

#Install downloaded updates
$InstallUpdates = {
    Param ($Computer)
    Try {
        #Set path for psexec, scripts
        Set-Location $path

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

        #Check if any updates require reboot
        $rebootRequired = (.\PsExec.exe -accepteula -nobanner -s "\\$($Computer.Computer)" cmd.exe /c 'echo . | powershell.exe -ExecutionPolicy Bypass -Command "&{return (New-Object -ComObject "Microsoft.Update.SystemInfo").RebootRequired}"') -eq $true
        if ($LASTEXITCODE -ne 0) {
            throw "PsExec failed with error code $LASTEXITCODE"
        }
    }
    catch {
        #Cancel any remaining actions
        exit
    }
}


&$ReadFileAndAddComputer

ForEach($Computer in $ComputersList) {
Write-Host $Computer
}
