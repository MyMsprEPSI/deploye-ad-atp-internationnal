#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour créer des comptes utilisateurs Active Directory dans une structure internationale
.DESCRIPTION
    Ce script crée des comptes utilisateurs dans différentes OUs organisées par ville/pays/continent
.NOTES
    Auteur: Thibaut Maurras
    Version: 1.3
    Prérequis: Module ActiveDirectory et droits d'administration sur le domaine
#>



# Configuration - Modifiable facilement
$Configuration = @{
    Domain          = "atp.local"
    BaseDN          = "DC=atp,DC=local"
    BaseOU          = "OU=International,OU=ATP,DC=atp,DC=local"
    DefaultPassword = "Epsi@2025."
    Cities          = @(
        @{
            Name      = "Londres"
            Country   = "Angleterre" 
            Continent = "Europe"
            UserCount = 300
        },
        @{
            Name      = "Monaco"
            Country   = "France"
            Continent = "Europe" 
            UserCount = 150
        },
        @{
            Name      = "Sydney"
            Country   = "Australie"
            Continent = "Oceanie"
            UserCount = 200
        },
        @{
            Name      = "Ponte-Vedra"
            Country   = "USA"
            Continent = "Amerique-du-Nord"
            UserCount = 50
        }
    )
}

# Listes de prénoms et noms
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

# Script principal

Write-Host "=== Début de la création des comptes utilisateurs internationaux ===" -ForegroundColor Cyan
    
# Vérifier le module ActiveDirectory
Write-Host "Vérification du module ActiveDirectory..." -ForegroundColor Yellow
    
if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "Le module ActiveDirectory n'est pas disponible." -ForegroundColor Red
    Write-Host "Veuillez installer RSAT-AD-PowerShell" -ForegroundColor Yellow
    exit 1
}
Import-Module ActiveDirectory -ErrorAction Stop
Write-Host "Module ActiveDirectory chargé avec succès" -ForegroundColor Green
    
# Vérifier la structure de base
Write-Host "Vérification de la structure de base..." -ForegroundColor Yellow
try {
    Get-ADOrganizationalUnit -Identity $Configuration.BaseOU -ErrorAction Stop | Out-Null
    Write-Host "Structure de base trouvée: $($Configuration.BaseOU)" -ForegroundColor Green
}
catch {
    Write-Host "ERREUR: La structure de base n'existe pas: $($Configuration.BaseOU)" -ForegroundColor Red
    Write-Host "Veuillez d'abord exécuter Create-BaseOUStructure.ps1" -ForegroundColor Yellow
    exit 1
}
    
# Calculer le total d'utilisateurs
$TotalUsers = 0
foreach ($City in $Configuration.Cities) {
    $TotalUsers += $City.UserCount
}
Write-Host "Création de $TotalUsers utilisateurs au total" -ForegroundColor Yellow
    
$CreatedUsers = @{}
    
# Fonction pour nettoyer les caractères spéciaux
function Clean-String {
    param([string]$InputString)
    
    $cleanString = $InputString.ToLower()
    $cleanString = $cleanString -replace "é", "e" -replace "è", "e" -replace "ê", "e" -replace "ë", "e"
    $cleanString = $cleanString -replace "à", "a" -replace "â", "a" -replace "ä", "a" -replace "á", "a"
    $cleanString = $cleanString -replace "ç", "c" -replace "ô", "o" -replace "ö", "o" -replace "ó", "o"
    $cleanString = $cleanString -replace "ù", "u" -replace "û", "u" -replace "ü", "u" -replace "ú", "u"
    $cleanString = $cleanString -replace "î", "i" -replace "ï", "i" -replace "í", "i"
    $cleanString = $cleanString -replace "-", "" -replace " ", "" -replace "'", ""
    $cleanString = $cleanString -replace "[^a-z0-9]", ""
    
    return $cleanString
}

foreach ($City in $Configuration.Cities) {
    Write-Host "" -ForegroundColor White
    Write-Host "--- Traitement de $($City.Name) ($($City.UserCount) utilisateurs) ---" -ForegroundColor Magenta
        
    try {
        # Définir les chemins OU
        $ContinentOU = "OU=$($City.Continent),$($Configuration.BaseOU)"
        $CountryOU = "OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"
        $CityOU = "OU=$($City.Name),OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"
        $UsersOU = "OU=Utilisateurs,OU=$($City.Name),OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"
            
        # Créer OU Continent
        try {
            Get-ADOrganizationalUnit -Identity $ContinentOU -ErrorAction Stop | Out-Null
            Write-Host "OU $($City.Continent) existe déjà" -ForegroundColor Yellow
        }
        catch {
            New-ADOrganizationalUnit -Name $City.Continent -Path $Configuration.BaseOU -ErrorAction Stop
            Write-Host "OU $($City.Continent) créée" -ForegroundColor Green
        }
            
        # Créer OU Pays
        try {
            Get-ADOrganizationalUnit -Identity $CountryOU -ErrorAction Stop | Out-Null
            Write-Host "OU $($City.Country) existe déjà" -ForegroundColor Yellow
        }
        catch {
            New-ADOrganizationalUnit -Name $City.Country -Path $ContinentOU -ErrorAction Stop
            Write-Host "OU $($City.Country) créée" -ForegroundColor Green
        }
            
        # Créer OU Ville
        try {
            Get-ADOrganizationalUnit -Identity $CityOU -ErrorAction Stop | Out-Null
            Write-Host "OU $($City.Name) existe déjà" -ForegroundColor Yellow
        }
        catch {
            New-ADOrganizationalUnit -Name $City.Name -Path $CountryOU -ErrorAction Stop
            Write-Host "OU $($City.Name) créée" -ForegroundColor Green
        }
        
        # Créer OU Utilisateurs dans la ville
        try {
            Get-ADOrganizationalUnit -Identity $UsersOU -ErrorAction Stop | Out-Null
            Write-Host "OU Utilisateurs existe déjà pour $($City.Name)" -ForegroundColor Yellow
        }
        catch {
            New-ADOrganizationalUnit -Name "Utilisateurs" -Path $CityOU -ErrorAction Stop
            Write-Host "OU Utilisateurs créée pour $($City.Name)" -ForegroundColor Green
        }
            
        Write-Host "Structure OU prête: $UsersOU" -ForegroundColor Green
            
        # Créer les utilisateurs
        $CityUsers = @()
        for ($i = 1; $i -le $City.UserCount; $i++) {
            $Attempts = 0
            $UsernameGenerated = $false
            
            do {
                $FirstName = Get-Random -InputObject $FirstNames
                $LastName = Get-Random -InputObject $LastNames
                
                # Nettoyer les noms
                $CleanFirstName = Clean-String -InputString $FirstName
                $CleanLastName = Clean-String -InputString $LastName
                
                # Format: première lettre du prénom + nom de famille
                $Username = $CleanFirstName.Substring(0, 1) + $CleanLastName
                
                $Attempts++
                if ($Attempts -gt 20) {
                    # Si trop de tentatives, ajouter un numéro
                    $Username = $CleanFirstName.Substring(0, 1) + $CleanLastName + $i.ToString().PadLeft(3, '0')
                    $UsernameGenerated = $true
                }
            } while ($CreatedUsers.ContainsKey($Username) -and -not $UsernameGenerated)

            # Vérifier encore si l'utilisateur existe dans AD
            $ExistingUser = $null
            try {
                $ExistingUser = Get-ADUser -Identity $Username -ErrorAction Stop
            }
            catch {
                # Utilisateur n'existe pas dans AD
            }

            if ($ExistingUser -or $CreatedUsers.ContainsKey($Username)) {
                # Générer un nom unique avec numéro
                $Counter = 1
                do {
                    $Username = $CleanFirstName.Substring(0, 1) + $CleanLastName + $Counter.ToString().PadLeft(3, '0')
                    $Counter++
                    
                    try {
                        $ExistingUser = Get-ADUser -Identity $Username -ErrorAction Stop
                    }
                    catch {
                        $ExistingUser = $null
                    }
                } while (($ExistingUser -or $CreatedUsers.ContainsKey($Username)) -and $Counter -lt 1000)
            }

            # Paramètres utilisateur
            $UserParams = @{
                Name                  = "$FirstName $LastName"
                GivenName             = $FirstName
                Surname               = $LastName
                SamAccountName        = $Username
                UserPrincipalName     = "$Username@$($Configuration.Domain)"
                Path                  = $UsersOU
                AccountPassword       = (ConvertTo-SecureString $Configuration.DefaultPassword -AsPlainText -Force)
                Enabled               = $true
                ChangePasswordAtLogon = $true
                DisplayName           = "$FirstName $LastName"
                Description           = "Utilisateur de $($City.Name)"
                City                  = $City.Name
                PasswordNeverExpires  = $false
            }

            try {
                New-ADUser @UserParams -ErrorAction Stop
                $CreatedUsers[$Username] = @{
                    City      = $City.Name
                    FirstName = $FirstName
                    LastName  = $LastName
                }
                $CityUsers += $Username
                
                if ($i % 10 -eq 0 -or $i -eq $City.UserCount) {
                    Write-Host "Créé: $Username ($FirstName $LastName)" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "Erreur création $Username : $($_.Exception.Message)" -ForegroundColor Red
                # Essayer avec un nom différent
                $i-- # Répéter cette itération
            }

            if ($i % 25 -eq 0 -or $i -eq $City.UserCount) {
                Write-Host "Progression: $i/$($City.UserCount) pour $($City.Name)" -ForegroundColor Gray
            }
        }
            
        Write-Host "$($CityUsers.Count) utilisateurs créés pour $($City.Name)" -ForegroundColor Green
            
    }
    catch {
        Write-Host "Erreur traitement $($City.Name): $($_.Exception.Message)" -ForegroundColor Red
        continue
    }
}
    
Write-Host "" -ForegroundColor White
Write-Host "=== Résumé de la création ===" -ForegroundColor Cyan
Write-Host "Total créés: $($CreatedUsers.Keys.Count)/$TotalUsers" -ForegroundColor Green
Write-Host "Mot de passe: $($Configuration.DefaultPassword)" -ForegroundColor Yellow
Write-Host "Changement requis à la première connexion" -ForegroundColor Yellow
    
# Répartition par ville
Write-Host "" -ForegroundColor White
Write-Host "Répartition par ville:" -ForegroundColor Cyan
foreach ($City in $Configuration.Cities) {
    $Count = ($CreatedUsers.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Host "- $($City.Name): $Count utilisateurs" -ForegroundColor White
}

Write-Host "" -ForegroundColor White
Write-Host "Exemples d'utilisateurs créés:" -ForegroundColor Cyan
$Examples = $CreatedUsers.Keys | Select-Object -First 5
foreach ($Example in $Examples) {
    $UserInfo = $CreatedUsers[$Example]
    Write-Host "- $Example ($($UserInfo.FirstName) $($UserInfo.LastName)) - $($UserInfo.City)" -ForegroundColor White
}

Write-Host "" -ForegroundColor White
Write-Host "=== Script terminé ===" -ForegroundColor Green
