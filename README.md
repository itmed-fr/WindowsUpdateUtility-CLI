---------------------------------------------------------------------------------------------
											Pré-requis
---------------------------------------------------------------------------------------------

Réponse au requêtes ICMP (ping) des serveurs à gérer
-------------------------------------------------------------------------------

Installer sur les serveurs à gérer PowerShell 5.1
-------------------------------------------------------------------------------
Microsoft .NET Framework 4.5.2 : https://www.microsoft.com/fr-FR/download/details.aspx?id=42642
Windows Management Framework 5.1 : https://www.microsoft.com/en-us/download/details.aspx?id=54616

Pour Windows Server 2008 R2 (ou Windows 7)
Télécharger et installer Microsoft .NET Framework 4.5.2 (ceci nécessite un reboot)
Télécharger Windows Management Framework 5.1 (ceci nécessite un reboot)
Après cela, il faut décompresser le package au format zip et lancer, via PowerShell en mode administrateur, le script « Install-WMF5.1.ps1 »

Pour Windows Server 2012 et 2012 R2
Télécharger et installer Windows Management Framework 5.1 en lançant le fichier .msu (ceci nécessite un reboot)

Configurer le pare-feu des serveurs à gérer
-------------------------------------------------------------------------------
Ajouter une règle de pare-feu sur les machines à mettre à jour
Nouvelle règle -> Programme -> %SystemRoot%\System32\dllhost.exe -> Action : Autoriser la connexion -> Profile Domaine et/ou Privé -> Nom : Mise à jour à distance des serveurs

Configurer l'installation automatique des mises à jour par stratégie de groupe
-------------------------------------------------------------------------------
Une stratégie de groupe doit être en place afin que les serveurs vérifient, téléchargent et installent automatiquement les mises à jour

Installer sur la machine de gestion le module PSWindowsUpdate
-------------------------------------------------------------------------------
https://www.powershellgallery.com/packages/PSWindowsUpdate/

Lancer une invite de commande PowerShell en tant qu'administrateur
Install-Module -Name PSWindowsUpdate




---------------------------------------------------------------------------------------------
									Utilisation de l'outils
---------------------------------------------------------------------------------------------

Se connecter sur la machine de gestion avec un utilisateur ayant des droits d'administration sur les serveurs à gérer
Décompresser l'archive dans C:\Scripts
Dans C:\Scripts devrait de trouver le dossier WUU-CLI avec à l'interieur trois fichiers computerlist.txt, README.md et WUU-CLI.exe
Lister les serveurs à mettre à jour dans le fichier computerlist.txt (un serveur par ligne)
Depuis la machine de gestion lancer le programme WUU-CLI.exe en tant qu'administrateur : Clic droit -> Executer en tant qu'administrateur