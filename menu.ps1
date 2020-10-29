#Ce programme permet de afficher, verifier l'état, mettre à jour, vérifier le besoin de redémarrer une liste de serveur.
#Veuillez changer le chemin de $hosts vers la liste de serveurs.

 


# Main Menu Function
function Main_Menu{  
	Write-Host "---------------------------------------------------------"  
	Write-Host "                                                         " -foregroundcolor black -backgroundcolor red  
	Write-Host "                                                         " -foregroundcolor white -backgroundcolor Black
	Write-Host "             Check State, Update, Reboot                 " -foregroundcolor white -backgroundcolor Black 
	Write-Host @"
                                                         
    [0] Recharger et afficher la liste des serveurs                   
    [1] Vérification de l'état des serveurs              
    [2] Mettre à jour les serveurs                       
    [3] Vérifier si un serveur a besoin de redémarrer    
    [4] Arrêt/Reboot serveurs                            
    [5] Sélectionner un serveur                          
    [6] Quitter                                          
"@ -foregroundcolor white -backgroundcolor Black 
	Write-Host "                                                         " -foregroundcolor white -backgroundcolor Black 
	Write-Host "                                                         " -foregroundcolor black -backgroundcolor red   
	Write-Host "---------------------------------------------------------"      

	$choix = read-host "Quelle action aimeriez-vous réaliser ?"
	Write-Host " "  
	if ($choix -eq 0) {
		
		ShowServerList
		Main_Menu
	} elseif ($choix -eq 1) {
		ServerCheckStatus($ComputersList)
		Write-Host " "
	  Pause
	  Main_Menu
	} elseif ($choix -eq 2) {
		UpdateServers
		Write-Host " "
		Pause
		Main_Menu
	} elseif ($choix -eq 3) {
		  #nom fonction
		Write-Host "3"
	  Pause
	  Main_Menu
	} elseif ($choix -eq 4) {
		  ok
		Write-Host "4"
	  Main_Menu
	} elseif ($choix -eq 5) {
		Write-Host " "
		SelectServer
	} elseif ($choix -eq 6) {
		exit

	} 
}

function SelectServer {
	for ($i = 0; $i -lt $ComputersList.Count; $i++) {
		Write-Host "[$i]" $ComputersList[$i]
	}
	$serverid = Read-Host "Quel serveur voulez-vous cibler ?"
	Menu_2($ComputersList[$serverid])
}
#------------------------------------------------------------------------
#------------------------------------------------------------------------
#------------------------------------------------------------------------

function Menu_2{
	param(
		[String]$server
		)
   Write-Host "---------------------------------------------------------"  
   Write-Host "                    Check $server                        " -foregroundcolor Yellow 
   Write-Host "                                                         " -foregroundcolor DarkGray -backgroundcolor red  
   write-host @"
                                                         
    [0] Check de l'état du serveur                       
    [1] Vérifier les mises à jour                        
    [2] Mettre à jour le serveur                         
    [3] Vérifier si le serveur a besoin de redémarrer    
    [4] Revenir au menu principal                        
    [5] Quitter                                          
"@ -foregroundcolor white -backgroundcolor DarkGray 
	Write-Host "                                                         " -foregroundcolor white -backgroundcolor DarkGray 
	Write-Host "                                                         " -foregroundcolor DarkGray -backgroundcolor red   
	Write-Host "---------------------------------------------------------"      
    
	$choix = read-host "Quelle action aimeriez-vous réaliser ?"
	Write-Host " "  
	if ($choix -eq 0) {
		ServerCheckStatus($server)
		Menu_2($server)
	} elseif ($choix -eq 1) {
		#fonction
		Write-Host " "
		Pause
		Menu_2($server)
	} elseif ($choix -eq 2) {
		UpdateServers
		Write-Host " "
		Pause
		Menu_2($server)
	} elseif ($choix -eq 3) {
		CheckRebootStatus($server)
		Write-Host " "
		Pause
		Menu_2($server)
	} elseif ($choix -eq 4) {
		Write-Host " "
		Main_Menu
	} elseif ($choix -eq 5) {
		Exit
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
 function ServerCheckStatus {
	param (
        [string[]]$ComputerNames
    )
    Write-Host " "
    Write-Host "Vérification de l'état des serveurs..." -foregroundcolor white -backgroundcolor blue
    Write-Host "--------------------------------------"
	foreach($ComputerName in $ComputerNames){
		ping -n 3 $ComputerName >$null
		if($lastexitcode -eq 0) {
			Write-Host "$ComputerName est UP. Vérification dix des dernières mises à jour..." -foregroundcolor black -backgroundcolor green
			Get-WUHistory -ComputerName $ComputerName -Last 10
		} 
        else {
			Write-Host "$ComputerName est DOWN" -foregroundcolor black -backgroundcolor red
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
	param (
        [string[]]$ComputerNames
    )
	Write-Host " "
    Write-Host "Vérification de l'état des serveurs..." -foregroundcolor white -backgroundcolor blue
    Write-Host "--------------------------------------"
	foreach($ComputerName in $ComputerNames){
			$RebootRequired = Get-WURebootStatus -ComputerName $ComputerName -Silent
			if ($RebootRequired)
			{
				$choix = Read-Host  "Le serveur a besoin d'être redémarré. Voulez-vous le redémarrer tout de suite O/N ?"
				if ($choix -eq 'O') {Reboot-Computer $ComputerName}
			}
	}
	Write-Host "---------------------------"
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
	$ComputersList.Clear()
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
    