#Ce programme permet de afficher, verifier l'état, mettre à jour, vérifier le besoin de redémarrer une liste de serveur.
#Veuillez changer le chemin de $hosts vers la liste de serveurs.

$ComputersList = [System.Collections.ArrayList]::new()


# Main Menu Function
function Main_Menu{  
   Write-Host "---------------------------------------------------------"  
   Write-Host "                                                         " -foregroundcolor black -backgroundcolor red  
   Write-Host "                                                         " -foregroundcolor white -backgroundcolor Black
   Write-Host "             Check State, Update, Reboot                 " -foregroundcolor white -backgroundcolor Black 
   write-host @"
                                                         
    [0] Afficher la liste des serveurs                   
    [1] Check de l'état des serveurs                     
    [2] Mettre à jour les serveurs                       
    [3] Vérifier si un serveur a besoin de redémarrer    
    [4] Arrêt/Reboot serveurs                            
    [5] Quitter                                          
"@ -foregroundcolor white -backgroundcolor Black 
   Write-Host "                                                         " -foregroundcolor white -backgroundcolor Black 
   Write-Host "                                                         " -foregroundcolor black -backgroundcolor red   
   Write-Host "---------------------------------------------------------"      
    
  $answer = read-host "Quelle action aimeriez-vous réaliser ?"
  Write-Host " "  
if ($answer -eq 0) {
	ShowServerList
	Main_Menu
} elseif ($answer -eq 1) {
    Server_Check_Status
	Write-Host " "
  Pause
  Main_Menu
} elseif ($answer -eq 2) {
	UpdateServers
	Write-Host " "
	Pause
	Main_Menu
} elseif ($answer -eq 3) {
      #nom fonction
	Write-Host "3"
  Pause
  Main_Menu
} elseif ($answer -eq 4) {
      ok
	Write-Host "4"
  Main_Menu
} elseif ($answer -eq 5) {
	Write-Host "5"

} 
}

# Pause Function
function Pause {
    Write-Host " "
    Write-Host "Appuyer sur n'importe quelle touche pour continuer..." -foregroundcolor gray -backgroundcolor blue
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
}

function ShowServerList {
	Write-Host $ComputersList
}

# Ping serveurs 
 function Server_Check_Status {
    Write-Host " "
    Write-Host "Vérification de l'état des serveurs..." -foregroundcolor white -backgroundcolor blue
    Write-Host "--------------------------------------"
foreach($ComputerName in $ComputersList){
		ping -n 3 $ComputerName >$null
		if($lastexitcode -eq 0) {
			write-host "$ComputerName est UP" -foregroundcolor black -backgroundcolor green
			Get-WUList -ComputerName $ComputerName
		} 
        else {
			write-host "$ComputerName est DOWN" -foregroundcolor black -backgroundcolor red
		}
	}
	Write-Host "---------------------------"
}

function UpdateWUOnServers {
	param (
        [string[]]$ComputerNames
    )
	
	Write-Host "Mise à jour du module PSWindowsUpdate sur les serveurs cibles..." -foregroundcolor white -backgroundcolor blue
    Write-Host "----------------------------------------------------------------"
	Update-WUModule -LocalPSWUSource "C:\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate" -ComputerName $ComputerNames
	Write-Host "----------------------------------------------------------------"
}

function UpdateServers {
    Write-Host " "
    Write-Host "Lancement des mises à jour..." -foregroundcolor white -backgroundcolor blue
    Write-Host "-----------------------------"
	foreach($ComputerName in $ComputersList){
		Install-WindowsUpdate -ComputerName $ComputerName -AcceptAll
		CheckRebootStatus ($ComputerName)
	}
	Write-Host "---------------------------"
}

function CheckRebootStatus {
	Get-WURebootStatus -ComputerName
}


#Add new Computer(s) to list
function AddComputersInList {
	param (
        [string[]]$ComputerNames
    )
    Write-Verbose "Adding $ComputerName."

    #Add to list
    foreach ($ComputerName in $ComputerNames) {
        $ComputerName = $ComputerName.Trim() #Remove any whitspace
        if ([System.String]::IsNullOrEmpty($ComputerName)) {continue} #Do not add if name empty

        $ComputersList.Add($ComputerName)
		Write-Verbose "$ComputerName added."
    }
}


function ReadFileAndAddComputer { #Add Computers from a file

    $FilePath = "C:\scripts\computerlist.txt"
    If( Test-Path -Path $FilePath )
    {
        $entries = (Get-Content $FilePath | Where {$_ -ne ''}) #Parse
        AddComputersInList ($entries)
    }
}

cls
ReadFileAndAddComputer
Main_menu
    