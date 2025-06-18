#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour creer des comptes utilisateurs Active Directory dans une structure internationale
.DESCRIPTION
    Ce script cree des comptes utilisateurs dans differentes OUs organisees par ville/pays/continent
.NOTES
    Auteur: Thibaut Maurras
    Version: 2025.06.18
    Prerequis: Module ActiveDirectory et droits d'administration sur le domaine
#>



# Configuration - Modifiable facilement
$Configuration = @{
    Domain          = "atp.local"
    BaseDN          = "DC=atp,DC=local"
    BaseOU          = "OU=International,OU=ATP,DC=atp,DC=local"
    DefaultPassword = "Epsi@2025."
    SecurePassword  = $null  # Sera initialise plus tard
    WorldStructure  = @{
        "Europe"           = @{
            "France"     = @("Paris", "Lyon", "Marseille", "Monaco", "Toulouse")
            "Angleterre" = @("Londres", "Manchester")
            "Allemagne"  = @("Berlin", "Munich")
            "Espagne"    = @("Madrid", "Barcelone")
            "Italie"     = @("Rome", "Milan", "Naples", "Turin")
            "Pays-Bas"   = @("Amsterdam", "Rotterdam")
            "Belgique"   = @("Bruxelles", "Anvers")
            "Suisse"     = @("Zurich", "Geneve")
        }
        "Amerique-du-Nord" = @{
            "USA"     = @("New-York", "Los-Angeles", "Chicago", "Houston", "Ponte-Vedra")
            "Canada"  = @("Toronto", "Montreal")
            "Mexique" = @("Mexico", "Guadalajara")
        }
        "Amerique-du-Sud"  = @{
            "Bresil"    = @("Sao-Paulo", "Rio-de-Janeiro")
            "Argentine" = @("Buenos-Aires","Tucuman")
            "Chili"     = @("Santiago","Antofagasta")
            "Colombie"  = @("Bogota", "Medellin")
            "Perou"     = @("Lima", "Arequipa")
        }
        "Asie"             = @{
            "Chine"        = @("Pekin", "Shanghai")
            "Japon"        = @("Tokyo", "Yokohama", "Osaka")
            "Inde"         = @("Mumbai", "Delhi","Ahmedabad")
            "Coree-du-Sud" = @("Seoul", "Busan", "Incheon")
            "Singapour"    = @("Singapour")
            "Malaisie"     = @("Kuala-Lumpur", "Johor-Bahru")
            "Thailande"    = @("Bangkok","Chiang-Mai")
            "Vietnam"      = @("Ho-Chi-Minh-Ville", "Hanoi", "Hai-Phong")
        }
        "Afrique"          = @{
            "Afrique-du-Sud" = @("Le-Cap", "Johannesburg","Port-Elizabeth")
            "Nigeria"        = @("Lagos","Port-Harcourt")
            "Egypte"         = @("Le-Caire")
            "Maroc"          = @("Casablanca", "Marrakech")
            "Kenya"          = @("Nairobi", "Mombasa")
            "Ghana"          = @("Accra", "Kumasi")
        }
        "Oceanie"          = @{
            "Australie"                 = @("Sydney", "Melbourne")
            "Nouvelle-Zelande"          = @("Wellington")
            "Papouasie-Nouvelle-Guinee" = @("Port-Moresby")
            "Fidji"                     = @("Suva")
        }
    }
    # Parametres de generation automatique
    UsersPerCity    = @{
        "Major"  = 50     # Grandes villes (capitales, metropoles)
        "Large"  = 20     # Grandes villes
        "Medium" = 10    # Villes moyennes
        "Small"  = 5      # Petites villes
    }
}

# Initialiser le mot de passe securise
$Configuration.SecurePassword = ConvertTo-SecureString -String $Configuration.DefaultPassword -AsPlainText -Force

# Fonction pour determiner la taille d'une ville
function Get-CitySize {
    param([string]$CityName, [string]$Country)

    $MajorCities = @("Paris", "Londres", "Berlin", "Madrid", "Rome", "Amsterdam", "Bruxelles", "Zurich", "New-York", "Los-Angeles", "Chicago", "Toronto", "Montreal", "Mexico", "Sao-Paulo", "Buenos-Aires", "Santiago", "Bogota", "Lima", "Pekin", "Shanghai", "Tokyo", "Mumbai", "Delhi", "Seoul", "Singapour", "Bangkok", "Le-Cap", "Lagos", "Le-Caire", "Sydney", "Melbourne")

    $LargeCities = @("Lyon", "Marseille", "Manchester", "Birmingham", "Munich", "Hambourg", "Barcelone", "Valence", "Milan", "Naples", "Rotterdam", "Anvers", "Geneve", "Houston", "Phoenix", "San-Francisco", "Vancouver", "Calgary", "Guadalajara", "Rio-de-Janeiro", "Cordoba", "Valparaiso", "Medellin", "Arequipa", "Guangzhou", "Osaka", "Bangalore", "Busan", "Kuala-Lumpur", "Ho-Chi-Minh-Ville", "Johannesburg", "Kano", "Alexandrie", "Brisbane", "Auckland")

    if ($MajorCities -contains $CityName) { return "Major" }
    if ($LargeCities -contains $CityName) { return "Large" }

    # Les 3 premieres villes de chaque pays sont considerees comme moyennes
    $CountryCities = $Configuration.WorldStructure.Values | ForEach-Object { $_.GetEnumerator() | Where-Object { $_.Key -eq $Country } } | ForEach-Object { $_.Value }
    if ($CountryCities -and ($CountryCities[0..2] -contains $CityName)) { return "Medium" }

    return "Small"
}

# Generer automatiquement la liste des villes avec utilisateurs
$Cities = @()
foreach ($Continent in $Configuration.WorldStructure.Keys) {
    $Countries = $Configuration.WorldStructure[$Continent]
    foreach ($Country in $Countries.Keys) {
        $CountryCities = $Countries[$Country]
        foreach ($City in $CountryCities) {
            $CitySize = Get-CitySize -CityName $City -Country $Country
            $UserCount = $Configuration.UsersPerCity[$CitySize]

            $Cities += @{
                Name      = $City
                Country   = $Country
                Continent = $Continent
                UserCount = $UserCount
            }
        }
    }
}

Write-Information "=== Configuration generation mondiale ===" -InformationAction Continue
Write-Information "Villes a traiter: $($Cities.Count)" -InformationAction Continue

$TotalUsers = ($Cities | ForEach-Object { $_.UserCount } | Measure-Object -Sum).Sum
Write-Information "Total utilisateurs a creer: $TotalUsers" -InformationAction Continue

# Listes de prenoms et noms
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
Write-Information "=== Debut de la creation des comptes utilisateurs internationaux ===" -InformationAction Continue

# Verifier le module ActiveDirectory
Write-Information "Verification du module ActiveDirectory..." -InformationAction Continue

if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "Le module ActiveDirectory n'est pas disponible."
    Write-Information "Veuillez installer RSAT-AD-PowerShell" -InformationAction Continue
    exit 1
}
Import-Module ActiveDirectory -ErrorAction Stop
Write-Information "Module ActiveDirectory charge avec succes" -InformationAction Continue

# Verifier la structure de base
Write-Information "Verification de la structure de base..." -InformationAction Continue
try {
    Get-ADOrganizationalUnit -Identity $Configuration.BaseOU -ErrorAction Stop | Out-Null
    Write-Information "Structure de base trouvee: $($Configuration.BaseOU)" -InformationAction Continue
}
catch {
    Write-Error "La structure de base n'existe pas: $($Configuration.BaseOU)"
    Write-Information "Veuillez d'abord executer Create-BaseOUStructure.ps1" -InformationAction Continue
    exit 1
}

# Calculer le total d'utilisateurs
$TotalUsers = ($Cities | ForEach-Object { $_.UserCount } | Measure-Object -Sum).Sum
Write-Information "Creation de $TotalUsers utilisateurs au total" -InformationAction Continue

$CreatedUsers = @{}

# Fonction pour nettoyer les caracteres speciaux
function ConvertTo-CleanString {
    param([string]$InputString)

    $cleanString = $InputString.ToLower()
    $cleanString = $cleanString -replace "e", "e" -replace "e", "e" -replace "e", "e" -replace "e", "e"
    $cleanString = $cleanString -replace "a", "a" -replace "a", "a" -replace "a", "a" -replace "a", "a"
    $cleanString = $cleanString -replace "c", "c" -replace "o", "o" -replace "o", "o" -replace "o", "o"
    $cleanString = $cleanString -replace "u", "u" -replace "u", "u" -replace "u", "u" -replace "u", "u"
    $cleanString = $cleanString -replace "i", "i" -replace "i", "i" -replace "i", "i"
    $cleanString = $cleanString -replace "-", "" -replace " ", "" -replace "'", ""
    $cleanString = $cleanString -replace "[^a-z0-9]", ""

    return $cleanString
}

foreach ($City in $Cities) {
    Write-Information "" -InformationAction Continue
    Write-Information "--- Traitement de $($City.Name) ($($City.UserCount) utilisateurs) ---" -InformationAction Continue

    try {
        # Definir les chemins OU
        $UsersOU = "OU=Utilisateurs,OU=$($City.Name),OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"

        # Verifier que l'OU Utilisateurs existe
        try {
            Get-ADOrganizationalUnit -Identity $UsersOU -ErrorAction Stop | Out-Null
            Write-Information "OU Utilisateurs trouvee pour $($City.Name)" -InformationAction Continue
        }
        catch {
            Write-Error "OU Utilisateurs non trouvee pour $($City.Name)"
            Write-Information "Veuillez d'abord executer Create-BaseOUStructure.ps1" -InformationAction Continue
            continue
        }

        # Creer les utilisateurs
        $CityUsers = @()
        for ($i = 1; $i -le $City.UserCount; $i++) {
            $Attempts = 0
            $UsernameGenerated = $false

            do {
                $FirstName = Get-Random -InputObject $FirstNames
                $LastName = Get-Random -InputObject $LastNames

                # Nettoyer les noms
                $CleanFirstName = ConvertTo-CleanString -InputString $FirstName
                $CleanLastName = ConvertTo-CleanString -InputString $LastName

                # Format: premiere lettre du prenom + nom de famille
                $Username = $CleanFirstName.Substring(0, 1) + $CleanLastName

                $Attempts++
                if ($Attempts -gt 20) {
                    # Si trop de tentatives, ajouter un numero
                    $Username = $CleanFirstName.Substring(0, 1) + $CleanLastName + $i.ToString().PadLeft(3, '0')
                    $UsernameGenerated = $true
                }
            } while ($CreatedUsers.ContainsKey($Username) -and -not $UsernameGenerated)

            # Verifier encore si l'utilisateur existe dans AD
            $ExistingUser = $null
            try {
                $ExistingUser = Get-ADUser -Identity $Username -ErrorAction Stop
            }
            catch {
                # Utilisateur n'existe pas dans AD
                $ExistingUser = $null
            }

            if ($ExistingUser -or $CreatedUsers.ContainsKey($Username)) {
                # Generer un nom unique avec numero
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

            # Parametres utilisateur
            $UserParams = @{
                Name                  = "$FirstName $LastName"
                GivenName             = $FirstName
                Surname               = $LastName
                SamAccountName        = $Username
                UserPrincipalName     = "$Username@$($Configuration.Domain)"
                Path                  = $UsersOU
                AccountPassword       = $Configuration.SecurePassword
                Enabled               = $true
                ChangePasswordAtLogon = $false
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
                    Write-Information "Cree: $Username ($FirstName $LastName)" -InformationAction Continue
                }
            }
            catch {
                Write-Warning "Erreur creation $Username : $($_.Exception.Message)"
                # Continuer avec l'utilisateur suivant
            }

            if ($i % 25 -eq 0 -or $i -eq $City.UserCount) {
                Write-Information "Progression: $i/$($City.UserCount) pour $($City.Name)" -InformationAction Continue
            }
        }

        Write-Information "$($CityUsers.Count) utilisateurs crees pour $($City.Name)" -InformationAction Continue

    }
    catch {
        Write-Error "Erreur traitement $($City.Name): $($_.Exception.Message)"
        continue
    }
}

Write-Information "" -InformationAction Continue
Write-Information "=== Resume de la creation ===" -InformationAction Continue
Write-Information "Total crees: $($CreatedUsers.Keys.Count)/$TotalUsers" -InformationAction Continue
Write-Information "Mot de passe: $($Configuration.DefaultPassword)" -InformationAction Continue
Write-Information "Pas de changement requis a la premiere connexion" -InformationAction Continue
    
# Répartition par ville
Write-Information "" -InformationAction Continue
Write-Information "Repartition par ville:" -InformationAction Continue
foreach ($City in $Cities) {
    $Count = ($CreatedUsers.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Information "- $($City.Name): $Count utilisateurs" -InformationAction Continue
}

Write-Information "" -InformationAction Continue
Write-Information "Exemples d'utilisateurs crees:" -InformationAction Continue
$Examples = $CreatedUsers.Keys | Select-Object -First 5
foreach ($Example in $Examples) {
    $UserInfo = $CreatedUsers[$Example]
    Write-Information "- $Example ($($UserInfo.FirstName) $($UserInfo.LastName)) - $($UserInfo.City)" -InformationAction Continue
}

Write-Information "" -InformationAction Continue
Write-Information "=== Script termine ===" -InformationAction Continue
            
Write-Host "$($CityUsers.Count) utilisateurs crees pour $($City.Name)" -ForegroundColor Green
catch {
    Write-Host "Erreur traitement $($City.Name): $($_.Exception.Message)" -ForegroundColor Red
    continue
}

Write-Host "" -ForegroundColor White
Write-Host "=== Resume de la creation ===" -ForegroundColor Cyan
Write-Host "Total crees: $($CreatedUsers.Keys.Count)/$TotalUsers" -ForegroundColor Green
Write-Host "Mot de passe: $($Configuration.DefaultPassword)" -ForegroundColor Yellow
Write-Host "Pas de changement requis à la première connexion" -ForegroundColor Green
    
# Répartition par ville
Write-Host "" -ForegroundColor White
Write-Host "Repartition par ville:" -ForegroundColor Cyan
foreach ($City in $Configuration.Cities) {
    $Count = ($CreatedUsers.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Host "- $($City.Name): $Count utilisateurs" -ForegroundColor White
}

Write-Host "" -ForegroundColor White
Write-Host "Exemples d'utilisateurs crees:" -ForegroundColor Cyan
$Examples = $CreatedUsers.Keys | Select-Object -First 5
foreach ($Example in $Examples) {
    $UserInfo = $CreatedUsers[$Example]
    Write-Host "- $Example ($($UserInfo.FirstName) $($UserInfo.LastName)) - $($UserInfo.City)" -ForegroundColor White
}

Write-Host "" -ForegroundColor White
Write-Host "=== Script termine ===" -ForegroundColor Green
