
# Main Menu Function
function Main_Menu{  
	Write-Host "---------------------------------------------------------"  
	Write-Host "             Check State, Update, Reboot                 " -foregroundcolor Yellow 
	Write-Host "                                                         " -foregroundcolor Black -backgroundcolor red  
	write-host @"
                                                         
    [0] Afficher la liste des serveurs                   
    [1] Check de l'état des serveurs                     
    [2] Mettre à jour les serveurs                       
    [3] Vérifier si un serveur a besoin de redémarrer    
    [4] menu ciblé                                       
    [5] Quitter                                          
"@ -foregroundcolor white -backgroundcolor Black 
	Write-Host "                                                         " -foregroundcolor white -backgroundcolor Black 
	Write-Host "                                                         " -foregroundcolor Black -backgroundcolor red   
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
    cible
	Write-Host " "
	Main_Menu
} elseif ($answer -eq 5) {
	Write-Host "Good Bye"

} 
}
#------------------------------------------------------------------------
#------------------------------------------------------------------------
#------------------------------------------------------------------------
function cible {
	for ($i = 0; $i -lt $ComputerNames.Length; $i++) {
		Write-Host "[$i]" $ComputerNames[$i]
	}
	$serverid = Read-Host "Quel serveur voulez-vous cibler ?"
	Menu_2($ComputerNames[$serverid])
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
    
	$answer = read-host "Quelle action aimeriez-vous réaliser ?"
	Write-Host " "  
	if ($answer -eq 0) {
		Server_Check_Status
		Menu_2($server)
	} elseif ($answer -eq 1) {
		#fonction
		Write-Host " "
		Pause
		Menu_2($server)
	} elseif ($answer -eq 2) {
		UpdateServers
		Write-Host " "
		Pause
		Menu_2($server)
	} elseif ($answer -eq 3) {
		#nom fonction
		Write-Host "3"
		Pause
		Menu_2($server)
	} elseif ($answer -eq 4) {
		Write-Host " "
		Main_Menu
	} elseif ($answer -eq 5) {
		Exit
	} 
}


Main_menu
    