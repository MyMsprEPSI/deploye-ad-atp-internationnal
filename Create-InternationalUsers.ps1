#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour créer des comptes utilisateurs Active Directory dans une structure internationale
.DESCRIPTION
    Ce script crée des comptes utilisateurs dans différentes OUs organisées par ville/pays/continent
.NOTES
    Auteur: Thibaut Maurras
    Version: 1.2
    Prérequis: Module ActiveDirectory et droits d'administration sur le domaine
#>

# Configuration - Modifiable facilement
$Configuration = @{
    Domain = "atp.local"
    BaseDN = "DC=atp,DC=local"
    BaseOU = "OU=International,OU=ATP,DC=atp,DC=local"
    DefaultPassword = "Password123!"
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
            Country = "USA"
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
        try {
            Install-WindowsFeature -Name RSAT-AD-PowerShell -ErrorAction Stop
        } catch {
            Write-ColoredOutput "Impossible d'installer le module ActiveDirectory automatiquement." -Color "Red"
            throw "Module ActiveDirectory requis"
        }
    }
    Import-Module ActiveDirectory -ErrorAction Stop
}

# Script principal
try {
    Write-Host "=== Début de la création des comptes utilisateurs internationaux ===" -ForegroundColor Cyan
    
    # Vérifier et charger le module ActiveDirectory
    Write-Host "Vérification du module ActiveDirectory..." -ForegroundColor Yellow
    
    if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "Le module ActiveDirectory n'est pas disponible." -ForegroundColor Red
        exit 1
    }
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Host "Module ActiveDirectory chargé avec succès" -ForegroundColor Green
    
    # Calculer le total d'utilisateurs
    $TotalUsers = 0
    foreach ($City in $Configuration.Cities) {
        $TotalUsers += $City.UserCount
    }
    Write-Host "Création de $TotalUsers utilisateurs au total" -ForegroundColor Yellow
    
    $CreatedUsers = @()
    
    foreach ($City in $Configuration.Cities) {
        Write-Host "`n--- Traitement de $($City.Name) ($($City.UserCount) utilisateurs) ---" -ForegroundColor Magenta
        
        try {
            # Définir les chemins OU
            $ContinentOU = "OU=$($City.Continent),$($Configuration.BaseOU)"
            $CountryOU = "OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"
            $CityOU = "OU=$($City.Name),OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"
            
            # Vérifier que la base OU International existe
            try {
                Get-ADOrganizationalUnit -Identity $Configuration.BaseOU -ErrorAction Stop | Out-Null
                Write-Host "Base OU trouvée: $($Configuration.BaseOU)" -ForegroundColor Green
            } catch {
                Write-Host "ERREUR: La base OU '$($Configuration.BaseOU)' n'existe pas." -ForegroundColor Red
                continue
            }
            
            # Créer OU Continent si elle n'existe pas
            try {
                Get-ADOrganizationalUnit -Identity $ContinentOU -ErrorAction Stop | Out-Null
                Write-Host "OU $($City.Continent) existe déjà" -ForegroundColor Yellow
            } catch {
                New-ADOrganizationalUnit -Name $City.Continent -Path $Configuration.BaseOU -ErrorAction Stop
                Write-Host "OU $($City.Continent) créée" -ForegroundColor Green
            }
            
            # Créer OU Pays si elle n'existe pas
            try {
                Get-ADOrganizationalUnit -Identity $CountryOU -ErrorAction Stop | Out-Null
                Write-Host "OU $($City.Country) existe déjà" -ForegroundColor Yellow
            } catch {
                New-ADOrganizationalUnit -Name $City.Country -Path $ContinentOU -ErrorAction Stop
                Write-Host "OU $($City.Country) créée" -ForegroundColor Green
            }
            
            # Créer OU Ville si elle n'existe pas
            try {
                Get-ADOrganizationalUnit -Identity $CityOU -ErrorAction Stop | Out-Null
                Write-Host "OU $($City.Name) existe déjà" -ForegroundColor Yellow
            } catch {
                New-ADOrganizationalUnit -Name $City.Name -Path $CountryOU -ErrorAction Stop
                Write-Host "OU $($City.Name) créée" -ForegroundColor Green
            }
            
            Write-Host "Structure OU prête pour $($City.Name): $CityOU" -ForegroundColor Green
            
            # Créer les utilisateurs
            $CityUsers = @()
            for ($i = 1; $i -le $City.UserCount; $i++) {
                # Générer un nom d'utilisateur unique
                do {
                    $FirstName = Get-Random -InputObject $FirstNames
                    $LastName = Get-Random -InputObject $LastNames
                    $Username = "$FirstName.$LastName.$($City.Name)".ToLower()
                    $Username = $Username -replace "é", "e" -replace "è", "e" -replace "à", "a" -replace "ç", "c" -replace "ô", "o"
                } while ($CreatedUsers -contains $Username)
                
                $UserParams = @{
                    Name = "$FirstName $LastName"
                    GivenName = $FirstName
                    Surname = $LastName
                    SamAccountName = $Username
                    UserPrincipalName = "$Username@$($Configuration.Domain)"
                    Path = $CityOU
                    AccountPassword = (ConvertTo-SecureString $Configuration.DefaultPassword -AsPlainText -Force)
                    Enabled = $true
                    ChangePasswordAtLogon = $true
                    DisplayName = "$FirstName $LastName ($($City.Name))"
                    Description = "Utilisateur de $($City.Name)"
                    City = $City.Name
                    PasswordNeverExpires = $false
                }
                
                try {
                    # Vérifier si l'utilisateur existe déjà
                    try {
                        Get-ADUser -Identity $Username -ErrorAction Stop | Out-Null
                        Write-Host "L'utilisateur $Username existe déjà - génération d'un nouveau nom" -ForegroundColor Yellow
                        continue
                    } catch {
                        # L'utilisateur n'existe pas, on peut le créer
                    }
                    
                    New-ADUser @UserParams -ErrorAction Stop
                    $CreatedUsers += $Username
                    $CityUsers += $Username
                    
                } catch {
                    Write-Host "Erreur lors de la création de l'utilisateur $Username : $($_.Exception.Message)" -ForegroundColor Red
                }
                
                if ($i % 25 -eq 0 -or $i -eq $City.UserCount) {
                    Write-Host "  Progression: $i/$($City.UserCount) utilisateurs traités pour $($City.Name)" -ForegroundColor Gray
                }
            }
            
            Write-Host "$($CityUsers.Count) utilisateurs créés avec succès pour $($City.Name)" -ForegroundColor Green
            
        } catch {
            Write-Host "Erreur lors du traitement de $($City.Name): $($_.Exception.Message)" -ForegroundColor Red
            continue
        }
    }
    
    Write-Host "`n=== Résumé de la création ===" -ForegroundColor Cyan
    Write-Host "Total d'utilisateurs créés : $($CreatedUsers.Count)/$TotalUsers" -ForegroundColor Green
    Write-Host "Mot de passe par défaut : $($Configuration.DefaultPassword)" -ForegroundColor Yellow
    Write-Host "Changement de mot de passe requis à la première connexion" -ForegroundColor Yellow
    
    # Afficher la répartition par ville
    Write-Host "`nRépartition par ville :" -ForegroundColor Cyan
    foreach ($City in $Configuration.Cities) {
        $CityUserCount = ($CreatedUsers | Where-Object { $_ -like "*.$($City.Name.ToLower())*" }).Count
        Write-Host "- $($City.Name) : $CityUserCount utilisateurs" -ForegroundColor White
    }
    
    Write-Host "`n=== Script terminé avec succès ===" -ForegroundColor Green
    
} catch {
    Write-Host "`nErreur fatale : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Détails: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
        
        try {
            # Créer la structure OU
            $TargetOU = New-OUStructure -City $City.Name -Country $City.Country -Continent $City.Continent -BaseOU $Configuration.BaseOU
            Write-ColoredOutput "Structure OU créée pour $($City.Name): $TargetOU" -Color "Green"
            
            # Créer les utilisateurs
            $CityUsers = @()
            for ($i = 1; $i -le $City.UserCount; $i++) {
                $Username = New-RandomUser -City $City.Name -TargetOU $TargetOU -DefaultPassword $Configuration.DefaultPassword -FirstNames $FirstNames -LastNames $LastNames -ExistingUsers $CreatedUsers
                
                if ($Username) {
                    $CreatedUsers += $Username
                    $CityUsers += $Username
                }
                
                $OverallProgress++
                
                if ($i % 25 -eq 0 -or $i -eq $City.UserCount) {
                    Write-Progress -Activity "Création des utilisateurs pour $($City.Name)" -Status "$i/$($City.UserCount) utilisateurs traités" -PercentComplete (($i / $City.UserCount) * 100)
                    Write-ColoredOutput "  Progression: $i/$($City.UserCount) utilisateurs traités pour $($City.Name)" -Color "Gray"
                }
            }
            
            Write-ColoredOutput "$($CityUsers.Count) utilisateurs créés avec succès pour $($City.Name)" -Color "Green"
            
        } catch {
            Write-ColoredOutput "Erreur lors du traitement de $($City.Name): $($_.Exception.Message)" -Color "Red"
            continue
        }
    }
    
    Write-ColoredOutput "`n=== Résumé de la création ===" -Color "Cyan"
    Write-ColoredOutput "Total d'utilisateurs créés : $($CreatedUsers.Count)/$TotalUsers" -Color "Green"
    Write-ColoredOutput "Mot de passe par défaut : $($Configuration.DefaultPassword)" -Color "Yellow"
    Write-ColoredOutput "Changement de mot de passe requis à la première connexion" -Color "Yellow"
    
    # Afficher la répartition par ville
    Write-ColoredOutput "`nRépartition par ville :" -Color "Cyan"
    foreach ($City in $Configuration.Cities) {
        $CityUserCount = ($CreatedUsers | Where-Object { $_ -like "*.$($City.Name.ToLower())*" }).Count
        Write-ColoredOutput "- $($City.Name) : $CityUserCount utilisateurs" -Color "White"
    }
    
    Write-ColoredOutput "`n=== Script terminé avec succès ===" -Color "Green"
    
} catch {
    Write-ColoredOutput "`nErreur fatale : $($_.Exception.Message)" -Color "Red"
    Write-ColoredOutput "Détails: $($_.ScriptStackTrace)" -Color "Red"
    Write-ColoredOutput "`nVeuillez vérifier :" -Color "Yellow"
    Write-ColoredOutput "1. Que vous êtes administrateur du domaine" -Color "Yellow"
    Write-ColoredOutput "2. Que la base OU existe : $($Configuration.BaseOU)" -Color "Yellow"
    Write-ColoredOutput "3. Que le module ActiveDirectory est installé" -Color "Yellow"
    exit 1
}
