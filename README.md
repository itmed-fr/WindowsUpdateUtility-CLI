Pré-requis :
Installer PowerShell 5.1 : 
Installer le module PSWindowsUpdate depuis https://www.powershellgallery.com/packages/PSWindowsUpdate/


Ajouter une règle de pare-feu sur les machines à mettre à jour
Nouvelle règle -> Programme -> %SystemRoot%\System32\dllhost.exe -> Action : Autoriser la connexion -> Profile Domaine et/ou Privé -> Nom : Mise à jour à distance des serveurs