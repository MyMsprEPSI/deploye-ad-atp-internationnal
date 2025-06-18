# deploye-ad-atp-internationnal

# Script de Création d'Utilisateurs AD International

## Prérequis

1. **PowerShell 5.1** ou **PowerShell 7+**
2. **Module ActiveDirectory** installé
3. **Droits d'administrateur** sur le contrôleur de domaine
4. **Structure OU de base** : `OU=International,OU=ATP,DC=atp,DC=local` doit exister

## Vérifications avant exécution

```powershell
# Vérifier la version PowerShell
$PSVersionTable.PSVersion

# Vérifier le module ActiveDirectory
Get-Module -ListAvailable ActiveDirectory

# Vérifier les droits AD
Get-ADDomain
```

## Installation du module ActiveDirectory (si nécessaire)

### Windows Server
```powershell
Install-WindowsFeature -Name RSAT-AD-PowerShell
```

### Windows 10/11
```powershell
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

## Exécution du script

### Méthode 1 : Depuis PowerShell ISE
1. Ouvrir **PowerShell ISE en tant qu'administrateur**
2. Ouvrir le fichier `Create-InternationalUsers.ps1`
3. Appuyer sur **F5** pour exécuter

### Méthode 2 : Depuis PowerShell
```powershell
# Ouvrir PowerShell en tant qu'administrateur
cd "c:\Users\thiba\Documents\DEV\Projet\deploye-ad-atp-internationnal"

# Modifier la politique d'exécution si nécessaire
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Exécuter le script
.\Create-InternationalUsers.ps1
```

### Méthode 3 : Exécution avec paramètres personnalisés
```powershell
# Si vous voulez modifier la configuration à la volée
.\Create-InternationalUsers.ps1
```

## Configuration

Pour modifier le nombre d'utilisateurs ou ajouter des villes, éditez la section `$Configuration` dans le script :

```powershell
$Configuration = @{
    # Modifier ici le nombre d'utilisateurs par ville
    Cities = @(
        @{ Name = "Londres"; Country = "Angleterre"; Continent = "Europe"; UserCount = 300 },
        @{ Name = "Monaco"; Country = "France"; Continent = "Europe"; UserCount = 150 }
        # Ajouter d'autres villes ici
    )
}
```

## Dépannage

### Erreur "Execution Policy"
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Erreur "Module ActiveDirectory not found"
```powershell
Import-Module ActiveDirectory -Force
```

### Erreur "Access Denied"
- Vérifier que vous êtes **administrateur du domaine**
- Exécuter PowerShell **en tant qu'administrateur**

## Résultat attendu

Le script créera :
- **700 utilisateurs** au total (300+150+200+50)
- Structure OU automatique
- Noms d'utilisateur format : `prenom.nom.ville`
- Mot de passe : `Password123!` (changement requis à la première connexion)

## Structure créée

```
OU=International,OU=ATP,DC=atp,DC=local
├── OU=Europe
│   ├── OU=Angleterre
│   │   └── OU=Londres (300 utilisateurs)
│   └── OU=France
│       └── OU=Monaco (150 utilisateurs)
├── OU=Oceanie
│   └── OU=Australie
│       └── OU=Sydney (200 utilisateurs)
└── OU=Amerique-du-Nord
    └── OU=USA
        └── OU=Ponte-Vedra (50 utilisateurs)
```