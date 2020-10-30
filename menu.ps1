#Ce programme permet de afficher, verifier l'état, mettre à jour, vérifier le besoin de redémarrer une liste de serveur.
#Veuillez changer le chemin de $LogPath.

$Date = Get-Date -Format "dd-MM-yyyy"
$LogPath = "C:\Scripts\"+$Date+"_CheckServerLog.txt"




# Main Menu Function
function Main_Menu{  
	Write-Host "------------------------------------------------------------"  
	Write-Host "                                                            " -foregroundcolor black -backgroundcolor red  
	Write-Host "                                                            " -foregroundcolor white -backgroundcolor Black
	Write-Host "              Check State, Update, Reboot                   " -foregroundcolor white -backgroundcolor Black 
	Write-Host @"
                                                            
   [0] Recharger et afficher la liste des serveurs          
   [1] Check des serveurs (mises à jours et/ou redemarrage) 
   [2] Vérifier l'état des serveurs (ping + service)        
   [3] Sélectionner un serveur                              
   [4] Quitter                                              
"@ -foregroundcolor white -backgroundcolor Black      
	Write-Host "                                                            " -foregroundcolor white -backgroundcolor Black 
	Write-Host "                                                            " -foregroundcolor black -backgroundcolor red   
	Write-Host "------------------------------------------------------------"      

	$choix = read-host "Quelle action aimeriez-vous réaliser ?"
	Write-Host " "  
	if ($choix -eq 0) {
		ShowServerList
		Main_Menu
	} elseif ($choix -eq 1) {
		MAJList($ComputersList)
		CheckRebootStatus($ComputersList)
		Write-Host " "
		Pause
		Main_Menu
	} elseif ($choix -eq 2) {
		CheckServerStatus($ComputersList)
		Write-Host " "
		SelectServer
	} elseif ($choix -eq 3) {
		Write-Host " "
		SelectServer
	} elseif ($choix -eq 4) {
		Write-Host "Good Bye"
		exit
	} 
}

#------------------------------------------------------------------------
#------------------------------------------------------------------------
#------------------------------------------------------------------------

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
    [1] Vérifier les dernières mises à jour                        
    [2] Vérifier si le serveur a besoin de redémarrer    
    [3] Revenir au menu principal                        
    [4] Quitter                                          
"@ -foregroundcolor white -backgroundcolor DarkGray 
	Write-Host "                                                         " -foregroundcolor white -backgroundcolor DarkGray 
	Write-Host "                                                         " -foregroundcolor DarkGray -backgroundcolor red   
	Write-Host "---------------------------------------------------------"      
    
	$choix = read-host "Quelle action aimeriez-vous réaliser ?"
	Write-Host " "  
	if ($choix -eq 0) {
		CheckServerStatus($server)
		Menu_2($server)
	} elseif ($choix -eq 1) {
		MAJList($server)
		CheckRebootStatus($server)
		Write-Host " "
		Pause
		Menu_2($server)
	}  elseif ($choix -eq 2) {
		CheckRebootStatus($server)
		Write-Host " "
		Pause
		Menu_2($server)
	} elseif ($choix -eq 3) {
		Write-Host " "
		Main_Menu
	} elseif ($choix -eq 4) {
		Exit
	} 
}

#------------------------------------------------------------------------
#------------------------------------------------------------------------
#------------------------------------------------------------------------

# Pause Function
function Pause {
    Write-Host " "
    Write-Host "Appuyer sur n'importe quelle touche pour continuer..." -foregroundcolor gray -backgroundcolor blue
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host " "
}

function ShowServerList {
	Write-Host $ComputersList
}

# Ping serveurs et vérification du service Workstation
 function CheckServerStatus {
	param (
        [string[]]$ComputerNames
    )
    Write-Host " "
    Write-Host "Vérification de l'état des serveurs..." -foregroundcolor white -backgroundcolor blue
    Write-Host "--------------------------------------"
	foreach($ComputerName in $ComputerNames){
		ping -n 3 $ComputerName >$null
		if($lastexitcode -eq 0) {
			get-service Workstation -ComputerName $ComputerName
			if($? -eq "True") {
				Write-Host " $ComputerName est UP " -foregroundcolor black -backgroundcolor green
				Write-Host "|" -NoNewline
				Write-Host " Workstation est en marche... " -foregroundcolor black -backgroundcolor green
			}
			else {
				Write-Host " $ComputerName est UP " -foregroundcolor black -backgroundcolor green -NoNewline
				Write-Host "|" -NoNewline
				Write-Host " Workstation ne marche pas... " -foregroundcolor black -backgroundcolor red
			}
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

#Verifier si un serveur a besoin de redemarrer
function CheckRebootStatus {
	param (
        [string[]]$ComputerName
    )
	Write-Host " "
    Write-Host "Vérification de l'état des serveurs..." -foregroundcolor white -backgroundcolor blue
    Write-Host "--------------------------------------"
	#foreach($ComputerName in $ComputerNames){
			$RebootRequired = Get-WURebootStatus -ComputerName $ComputerName -Silent
			if ($RebootRequired)
			{
				$choix = Read-Host  "$ComputerName a besoin d'être redémarré. Voulez-vous le redémarrer tout de suite O/N ?"
				if ($choix -eq 'O') {Reboot-Computer $ComputerName}
			}
	#}
	Write-Host "---------------------------"
}

function MAJList {
	param (
        [string[]]$ComputerNames
    )
	$NumberMAJ = read-host "Combien voulez-voir de mises à jour (veuillez entrer un chiffre) ?"
	
	foreach($ComputerName in $ComputerNames){
		Write-Host "Affichage des $NumberMAJ dernières mises à jour de $ComputerName " -foregroundcolor white -backgroundcolor blue
		Get-WUHistory -ComputerName $ComputerName -Last $NumberMAJ
		Write-Host "---------------------------------------------------------" -foregroundcolor white -backgroundcolor blue
	}
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

#------------------------------------------------------------------------
#------------------------------------------------------------------------
#------------------------------------------------------------------------

cls
Write-Host "Le fichier de log se trouve dans $Path"
ReadFileAndAddComputer
Main_menu
