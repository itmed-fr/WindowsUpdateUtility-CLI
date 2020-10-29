#Ce programme permet de afficher, verifier l'état, mettre à jour, vérifier le besoin de redémarrer une liste de serveur.
#Veuillez changer le chemin de $hosts vers la liste de serveurs.

$hosts	= "C:\past\hosts.txt"
$servers	= get-content "$hosts"


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
	Write-Host "Serveurs présents dans le fichier hosts.txt :   " -foregroundcolor black -backgroundcolor yellow
	Write-Host " "
    $servers
  Main_Menu
} elseif ($answer -eq 1) {
    Server_Check_Status
	Write-Host " "
  Pause
  Main_Menu
} elseif ($answer -eq 2) {
      #nom fonction
	Write-Host "2"
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

# Ping serveurs 
 function Server_Check_Status {
    Write-Host " "
    write-host "Vérification de l'état des serveurs..." -foregroundcolor white -backgroundcolor blue
    Write-Host "--------------------------------------"
foreach($server in $servers){
		ping -n 3 $server >$null
		if($lastexitcode -eq 0) {
			write-host "$server est UP" -foregroundcolor black -backgroundcolor green
		} 
        else {
			write-host "$server est DOWN" -foregroundcolor black -backgroundcolor red
		}
	}
	Write-Host "---------------------------"
}

function ok {
    Write-Host " "
    write-host "Vérification des dernieres sauvegardes..." -foregroundcolor white -backgroundcolor blue
    Write-Host "--------------------------------------"
foreach($server in $servers){
		$u = ping -n 3 $server >$null
		if($lastexitcode -eq 0) {
			write-host "$u" -foregroundcolor black -backgroundcolor green
		} 
        else {
			write-host "$server error" -foregroundcolor black -backgroundcolor red
		}
	}
	Write-Host "---------------------------"
}

cls
Main_menu
    