#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour creer la structure de base des OUs ATP International
.DESCRIPTION
    Ce script cree la structure OU de base complete mondiale necessaire avant la creation des utilisateurs
.NOTES
    Auteur: Thibaut Maurras
    Version: 2025.06.18
    Prerequis: Module ActiveDirectory et droits d'administration sur le domaine
#>

# Configuration
$Configuration = @{
    BaseDN          = "DC=atp,DC=local"
    BaseOUStructure = @(
        @{ Name = "ATP"; Path = "DC=atp,DC=local"; Description = "Organisation ATP" },
        @{ Name = "International"; Path = "OU=ATP,DC=atp,DC=local"; Description = "Division Internationale ATP" }
    )
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
            "Argentine" = @("Buenos-Aires", "Tucuman")
            "Chili"     = @("Santiago", "Antofagasta")
            "Colombie"  = @("Bogota", "Medellin")
            "Perou"     = @("Lima", "Arequipa")
        }
        "Asie"             = @{
            "Chine"        = @("Pekin", "Shanghai")
            "Japon"        = @("Tokyo", "Yokohama", "Osaka")
            "Inde"         = @("Mumbai", "Delhi", "Ahmedabad")
            "Coree-du-Sud" = @("Seoul", "Busan", "Incheon")
            "Singapour"    = @("Singapour")
            "Malaisie"     = @("Kuala-Lumpur", "Johor-Bahru")
            "Thailande"    = @("Bangkok", "Chiang-Mai")
            "Vietnam"      = @("Ho-Chi-Minh-Ville", "Hanoi", "Hai-Phong")
        }
        "Afrique"          = @{
            "Afrique-du-Sud" = @("Le-Cap", "Johannesburg", "Port-Elizabeth")
            "Nigeria"        = @("Lagos", "Port-Harcourt")
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
}

# Script principal
Write-Information "=== Debut de la creation de la structure de base ===" -InformationAction Continue

# Verifier le module ActiveDirectory
Write-Information "Verification du module ActiveDirectory..." -InformationAction Continue

if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "Le module ActiveDirectory n'est pas disponible."
    Write-Information "Veuillez installer RSAT-AD-PowerShell" -InformationAction Continue
    exit 1
}
Import-Module ActiveDirectory -ErrorAction Stop
Write-Information "Module ActiveDirectory charge avec succes" -InformationAction Continue

# Verifier la connectivite au domaine
try {
    $Domain = Get-ADDomain -ErrorAction Stop
    Write-Information "Connecte au domaine: $($Domain.DNSRoot)" -InformationAction Continue
}
catch {
    Write-Error "Impossible de se connecter au domaine ATP: $($_.Exception.Message)"
    exit 1
}

# Creer la structure de base ATP et International
Write-Information "`n=== Creation de la structure de base ===" -InformationAction Continue
foreach ($OU in $Configuration.BaseOUStructure) {
    $FullPath = "OU=$($OU.Name),$($OU.Path)"

    try {
        Get-ADOrganizationalUnit -Identity $FullPath -ErrorAction Stop | Out-Null
        Write-Information "OU '$($OU.Name)' existe deja: $FullPath" -InformationAction Continue
    }
    catch {
        try {
            New-ADOrganizationalUnit -Name $OU.Name -Path $OU.Path -Description $OU.Description -ErrorAction Stop
            Write-Information "OU '$($OU.Name)' creee avec succes: $FullPath" -InformationAction Continue
        }
        catch {
            Write-Error "Erreur lors de la creation de l'OU '$($OU.Name)': $($_.Exception.Message)"
            exit 1
        }
    }
}

# Creer la structure mondiale complete
$BaseInternationalOU = "OU=International,OU=ATP,DC=atp,DC=local"
$TotalContinents = $Configuration.WorldStructure.Keys.Count
$CurrentContinent = 0

Write-Information "`n=== Creation de la structure mondiale ===" -InformationAction Continue
Write-Information "Creation de $TotalContinents continents avec leurs pays et villes..." -InformationAction Continue

foreach ($Continent in $Configuration.WorldStructure.Keys) {
    $CurrentContinent++
    Write-Information "`n[$CurrentContinent/$TotalContinents] Traitement du continent: $Continent" -InformationAction Continue

    # Creer OU Continent
    $ContinentOU = "OU=$Continent,$BaseInternationalOU"
    try {
        Get-ADOrganizationalUnit -Identity $ContinentOU -ErrorAction Stop | Out-Null
        Write-Information "  Continent $Continent existe deja" -InformationAction Continue
    }
    catch {
        New-ADOrganizationalUnit -Name $Continent -Path $BaseInternationalOU -Description "Continent $Continent" -ErrorAction Stop
        Write-Information "  Continent $Continent cree" -InformationAction Continue
    }

    $Countries = $Configuration.WorldStructure[$Continent]
    $TotalCountries = $Countries.Keys.Count
    $CurrentCountry = 0

    foreach ($Country in $Countries.Keys) {
        $CurrentCountry++
        Write-Information "    [$CurrentCountry/$TotalCountries] Pays: $Country" -InformationAction Continue

        # Creer OU Pays
        $CountryOU = "OU=$Country,$ContinentOU"
        try {
            Get-ADOrganizationalUnit -Identity $CountryOU -ErrorAction Stop | Out-Null
        }
        catch {
            New-ADOrganizationalUnit -Name $Country -Path $ContinentOU -Description "Pays $Country" -ErrorAction Stop
            Write-Information "      Pays $Country cree" -InformationAction Continue
        }

        $Cities = $Countries[$Country]
        $TotalCities = $Cities.Count

        # Creer les villes par batch pour ameliorer les performances
        $CreatedCities = 0
        foreach ($City in $Cities) {
            $CityOU = "OU=$City,$CountryOU"
            try {
                Get-ADOrganizationalUnit -Identity $CityOU -ErrorAction Stop | Out-Null
            }
            catch {
                try {
                    New-ADOrganizationalUnit -Name $City -Path $CountryOU -Description "Ville $City, $Country" -ErrorAction Stop
                    $CreatedCities++

                    # Creer les sous-OUs dans chaque ville
                    $SubOUs = @("Utilisateurs", "Ordinateurs", "Serveurs", "Groupes")
                    foreach ($SubOU in $SubOUs) {
                        try {
                            New-ADOrganizationalUnit -Name $SubOU -Path $CityOU -Description "$SubOU de $City" -ErrorAction Stop
                        }
                        catch {
                            Write-Warning "Erreur creation $SubOU dans $City : $($_.Exception.Message)"
                        }
                    }
                }
                catch {
                    Write-Warning "Erreur creation ville $City : $($_.Exception.Message)"
                }
            }
        }

        if ($CreatedCities -gt 0) {
            Write-Information "      $CreatedCities/$TotalCities villes creees pour $Country (avec sous-OUs)" -InformationAction Continue
        }
        else {
            Write-Information "      $TotalCities villes existantes pour $Country" -InformationAction Continue
        }
    }
}

Write-Information "`n=== Verification de la structure creee ===" -InformationAction Continue

# Statistiques finales
$TotalOUs = 0
$ContinentCount = 0
$CountryCount = 0
$CityCount = 0

foreach ($Continent in $Configuration.WorldStructure.Keys) {
    $ContinentCount++
    $Countries = $Configuration.WorldStructure[$Continent]
    foreach ($Country in $Countries.Keys) {
        $CountryCount++
        $Cities = $Countries[$Country]
        $CityCount += $Cities.Count
    }
}

$TotalOUs = 2 + $ContinentCount + $CountryCount + ($CityCount * 5) # ATP + International + Continents + Countries + (Cities * 5 sous-OUs chacune)

Write-Information "Structure mondiale creee:" -InformationAction Continue
Write-Information "  - OUs de base: 2 (ATP + International)" -InformationAction Continue
Write-Information "  - Continents: $ContinentCount" -InformationAction Continue
Write-Information "  - Pays: $CountryCount" -InformationAction Continue
Write-Information "  - Villes: $CityCount" -InformationAction Continue
Write-Information "  - Sous-OUs par ville: 4 (Utilisateurs, Ordinateurs, Serveurs, Groupes)" -InformationAction Continue
Write-Information "  - Total OUs: $TotalOUs" -InformationAction Continue

# Verifier la structure finale
$FinalOU = "OU=International,OU=ATP,DC=atp,DC=local"
try {
    $InternationalOU = Get-ADOrganizationalUnit -Identity $FinalOU -ErrorAction Stop
    Write-Information "`nStructure de base prete: $FinalOU" -InformationAction Continue
    Write-Information "  Description: $($InternationalOU.Description)" -InformationAction Continue
    Write-Information "  Creee le: $($InternationalOU.WhenCreated)" -InformationAction Continue
}
catch {
    Write-Error "La structure finale n'est pas accessible: $($_.Exception.Message)"
    exit 1
}

Write-Information "`n=== Structure mondiale complete creee avec succes ===" -InformationAction Continue
Write-Information "Vous pouvez maintenant executer le script Create-UserStructure.ps1" -InformationAction Continue
Write-Information "La structure couvre tous les continents avec leurs principales villes" -InformationAction Continue
