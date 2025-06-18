#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour créer des comptes utilisateurs Active Directory dans une structure internationale
.DESCRIPTION
    Ce script crée des comptes utilisateurs dans différentes OUs organisées par ville/pays/continent
.NOTES
    Auteur: Assistant IA
    Version: 1.0
    Prérequis: Module ActiveDirectory et droits d'administration sur le domaine
#>

# Configuration - Modifiable facilement
$Configuration = @{
    Domain = "atp.local"
    BaseDN = "DC=atp,DC=local"
    BaseOU = "OU=International,OU=ATP,DC=atp,DC=local"
    DefaultPassword = "Password1234!"
    Cities = @(
        @{
            Name = "Londres"
            Country = "Angleterre" 
            Continent = "Europe"
            UserCount = 300
        },
        @{
            Name = "Monaco"
            Country = "France"
            Continent = "Europe" 
            UserCount = 150
        },
        @{
            Name = "Sydney"
            Country = "Australie"
            Continent = "Oceanie"
            UserCount = 200
        },
        @{
            Name = "Ponte-Vedra"
            Country = "Usa"
            Continent = "Amerique-du-Nord"
            UserCount = 50
        }
    )
}

# Listes de prénoms et noms pour génération aléatoire
$FirstNames = @(
    "Alexandre", "Marie", "Pierre", "Sophie", "Jean", "Catherine", "David", "Emma", "Michel", "Julie",
    "Thomas", "Laura", "Nicolas", "Sarah", "Antoine", "Camille", "Julien", "Marine", "Sebastien", "Celine",
    "Vincent", "Aurelie", "Philippe", "Melissa", "Olivier", "Stephanie", "Fabrice", "Nathalie", "Laurent", "Valerie",
    "Guillaume", "Caroline", "Christophe", "Isabelle", "Frederic", "Virginie", "Matthieu", "Sandrine", "Jerome", "Laure",
    "Benjamin", "Elodie", "Romain", "Pascale", "Maxime", "Karine", "Florian", "Delphine", "Cedric", "Emilie"
)

$LastNames = @(
    "Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit", "Durand", "Leroy", "Moreau",
    "Simon", "Laurent", "Lefebvre", "Michel", "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier",
    "Morel", "Girard", "Andre", "Lefevre", "Mercier", "Dupont", "Lambert", "Bonnet", "Francois", "Martinez",
    "Legrand", "Garnier", "Faure", "Rousseau", "Blanc", "Guerin", "Muller", "Henry", "Roussel", "Nicolas",
    "Perrin", "Morin", "Mathieu", "Clement", "Gauthier", "Dumont", "Lopez", "Fontaine", "Chevalier", "Robin"
)

function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-ADModule {
    if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-ColoredOutput "Le module ActiveDirectory n'est pas disponible. Installation en cours..." -Color "Yellow"
        Install-WindowsFeature -Name RSAT-AD-PowerShell
    }
    Import-Module ActiveDirectory -ErrorAction Stop
}

function New-OUStructure {
    param(
        [string]$City,
        [string]$Country,
        [string]$Continent,
        [string]$BaseOU
    )
    
    $ContinentOU = "OU=$Continent,$BaseOU"
    $CountryOU = "OU=$Country,OU=$Continent,$BaseOU"
    $CityOU = "OU=$City,OU=$Country,OU=$Continent,$BaseOU"
    
    # Vérifier que la base OU International existe
    try {
        Get-ADOrganizationalUnit -Identity $BaseOU -ErrorAction Stop | Out-Null
    } catch {
        Write-ColoredOutput "ERREUR: La base OU '$BaseOU' n'existe pas. Veuillez la créer d'abord." -Color "Red"
        throw "Base OU manquante"
    }
    
    # Créer OU Continent si elle n'existe pas
    try {
        Get-ADOrganizationalUnit -Identity $ContinentOU -ErrorAction Stop | Out-Null
    } catch {
        New-ADOrganizationalUnit -Name $Continent -Path $BaseOU
        Write-ColoredOutput "OU $Continent créée" -Color "Green"
    }
    
    # Créer OU Pays si elle n'existe pas
    try {
        Get-ADOrganizationalUnit -Identity $CountryOU -ErrorAction Stop | Out-Null
    } catch {
        New-ADOrganizationalUnit -Name $Country -Path $ContinentOU
        Write-ColoredOutput "OU $Country créée" -Color "Green"
    }
    
    # Créer OU Ville si elle n'existe pas
    try {
        Get-ADOrganizationalUnit -Identity $CityOU -ErrorAction Stop | Out-Null
    } catch {
        New-ADOrganizationalUnit -Name $City -Path $CountryOU
        Write-ColoredOutput "OU $City créée" -Color "Green"
    }
    
    return $CityOU
}

function New-RandomUser {
    param(
        [string]$City,
        [string]$TargetOU,
        [string]$DefaultPassword,
        [array]$FirstNames,
        [array]$LastNames,
        [array]$ExistingUsers
    )
    
    do {
        $FirstName = Get-Random -InputObject $FirstNames
        $LastName = Get-Random -InputObject $LastNames
        $Username = "$FirstName.$LastName.$City".ToLower()
        $Username = $Username -replace "é", "e" -replace "è", "e" -replace "à", "a" -replace "ç", "c" -replace "ô", "o"
    } while ($ExistingUsers -contains $Username)
    
    $UserParams = @{
        Name = "$FirstName $LastName"
        GivenName = $FirstName
        Surname = $LastName
        SamAccountName = $Username
        UserPrincipalName = "$Username@$($Configuration.Domain)"
        Path = $TargetOU
        AccountPassword = (ConvertTo-SecureString $DefaultPassword -AsPlainText -Force)
        Enabled = $true
        ChangePasswordAtLogon = $true
        DisplayName = "$FirstName $LastName ($City)"
        Description = "Utilisateur de $City"
        City = $City
        PasswordNeverExpires = $false
    }
    
    try {
        New-ADUser @UserParams
        return $Username
    } catch {
        Write-ColoredOutput "Erreur lors de la création de l'utilisateur $Username : $($_.Exception.Message)" -Color "Red"
        return $null
    }
}

# Script principal
try {
    Write-ColoredOutput "=== Début de la création des comptes utilisateurs internationaux ===" -Color "Cyan"
    
    # Vérifier et charger le module ActiveDirectory
    Test-ADModule
    
    $TotalUsers = ($Configuration.Cities | Measure-Object -Property UserCount -Sum).Sum
    Write-ColoredOutput "Création de $TotalUsers utilisateurs au total" -Color "Yellow"
    
    $CreatedUsers = @()
    $OverallProgress = 0
    
    foreach ($City in $Configuration.Cities) {
        Write-ColoredOutput "`n--- Traitement de $($City.Name) ($($City.UserCount) utilisateurs) ---" -Color "Magenta"
        
        # Créer la structure OU
        $TargetOU = New-OUStructure -City $City.Name -Country $City.Country -Continent $City.Continent -BaseOU $Configuration.BaseOU
        
        # Créer les utilisateurs
        $CityUsers = @()
        for ($i = 1; $i -le $City.UserCount; $i++) {
            $Username = New-RandomUser -City $City.Name -TargetOU $TargetOU -DefaultPassword $Configuration.DefaultPassword -FirstNames $FirstNames -LastNames $LastNames -ExistingUsers $CreatedUsers
            
            if ($Username) {
                $CreatedUsers += $Username
                $CityUsers += $Username
                $OverallProgress++
                
                if ($i % 50 -eq 0 -or $i -eq $City.UserCount) {
                    Write-Progress -Activity "Création des utilisateurs pour $($City.Name)" -Status "$i/$($City.UserCount) utilisateurs créés" -PercentComplete (($i / $City.UserCount) * 100)
                }
            }
        }
        
        Write-ColoredOutput "$($CityUsers.Count) utilisateurs créés pour $($City.Name)" -Color "Green"
    }
    
    Write-ColoredOutput "`n=== Résumé de la création ===" -Color "Cyan"
    Write-ColoredOutput "Total d'utilisateurs créés : $($CreatedUsers.Count)/$TotalUsers" -Color "Green"
    Write-ColoredOutput "Mot de passe par défaut : $($Configuration.DefaultPassword)" -Color "Yellow"
    Write-ColoredOutput "Changement de mot de passe requis à la première connexion" -Color "Yellow"
    
    # Afficher la répartition par ville
    foreach ($City in $Configuration.Cities) {
        $CityUserCount = ($CreatedUsers | Where-Object { $_ -like "*.$($City.Name.ToLower())" }).Count
        Write-ColoredOutput "- $($City.Name) : $CityUserCount utilisateurs" -Color "White"
    }
    
    Write-ColoredOutput "`n=== Script terminé avec succès ===" -Color "Green"
    
} catch {
    Write-ColoredOutput "Erreur fatale : $($_.Exception.Message)" -Color "Red"
    Write-ColoredOutput $_.ScriptStackTrace -Color "Red"
    exit 1
}
