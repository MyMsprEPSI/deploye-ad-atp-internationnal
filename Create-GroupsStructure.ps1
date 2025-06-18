#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour creer des groupes Active Directory dans la structure internationale
.DESCRIPTION
    Ce script cree des groupes dans les OUs Groupes de chaque ville
.NOTES
    Auteur: Thibaut Maurras
    Version: 2025.06.18
    Prerequis: Module ActiveDirectory et droits d'administration sur le domaine
#>

# Configuration
$Configuration = @{
    Domain = "atp.local"
    BaseOU = "OU=International,OU=ATP,DC=atp,DC=local"
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
}

# Types de groupes
$GroupTypes = @(
    @{ Name = "Administrateurs"; Scope = "DomainLocal"; Category = "Security"; Description = "Administrateurs locaux" },
    @{ Name = "Utilisateurs"; Scope = "DomainLocal"; Category = "Security"; Description = "Utilisateurs standard" },
    @{ Name = "Finance"; Scope = "Global"; Category = "Security"; Description = "Departement Finance" },
    @{ Name = "RH"; Scope = "Global"; Category = "Security"; Description = "Ressources Humaines" },
    @{ Name = "IT"; Scope = "Global"; Category = "Security"; Description = "Technologies de l'Information" },
    @{ Name = "Marketing"; Scope = "Global"; Category = "Security"; Description = "Departement Marketing" },
    @{ Name = "Operations"; Scope = "Global"; Category = "Security"; Description = "Departement Operations" },
    @{ Name = "Legal"; Scope = "Global"; Category = "Security"; Description = "Departement Juridique" },
    @{ Name = "Managers"; Scope = "Global"; Category = "Security"; Description = "Managers et superviseurs" },
    @{ Name = "Support"; Scope = "Global"; Category = "Security"; Description = "Support technique" }
)

# Générer automatiquement la liste des villes
$Cities = @()
foreach ($Continent in $Configuration.WorldStructure.Keys) {
    $Countries = $Configuration.WorldStructure[$Continent]
    foreach ($Country in $Countries.Keys) {
        $CountryCities = $Countries[$Country]
        # Créer des groupes pour toutes les villes
        foreach ($City in $CountryCities) {
            if ($City) {
                $Cities += @{
                    Name = $City
                    Country = $Country
                    Continent = $Continent
                }
            }
        }
    }
}

Write-Information "=== Creation des groupes mondiaux ===" -InformationAction Continue
Write-Information "Villes a traiter: $($Cities.Count)" -InformationAction Continue

$TotalGroups = $Cities.Count * $GroupTypes.Count
Write-Information "Total groupes a creer: $TotalGroups" -InformationAction Continue

Import-Module ActiveDirectory -ErrorAction Stop
Write-Information "Module ActiveDirectory charge" -InformationAction Continue

$CreatedGroups = @{}

foreach ($City in $Cities) {
    Write-Information "`n--- Traitement de $($City.Name) ---" -InformationAction Continue

    try {
        $GroupsOU = "OU=Groupes,OU=$($City.Name),OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"

        # Verifier que l'OU existe
        try {
            Get-ADOrganizationalUnit -Identity $GroupsOU -ErrorAction Stop | Out-Null
            Write-Information "OU Groupes trouvee: $GroupsOU" -InformationAction Continue
        }
        catch {
            Write-Error "OU Groupes non trouvee pour $($City.Name)"
            continue
        }

        $CityGroups = @()
        foreach ($GroupType in $GroupTypes) {
            try {
                $GroupName = "GRP_$($City.Name.ToUpper())_$($GroupType.Name.ToUpper())"

                # Verifier si le groupe existe
                try {
                    Get-ADGroup -Identity $GroupName -ErrorAction Stop | Out-Null
                    Write-Information "Groupe $GroupName existe deja" -InformationAction Continue
                    continue
                }
                catch {
                    # Le groupe n'existe pas, on peut le creer
                }

                New-ADGroup -Name $GroupName -Path $GroupsOU -GroupScope $GroupType.Scope -GroupCategory $GroupType.Category -Description "$($GroupType.Description) - $($City.Name)" -ErrorAction Stop
                $CreatedGroups[$GroupName] = @{
                    City = $City.Name
                    Type = $GroupType.Name
                    Scope = $GroupType.Scope
                }
                $CityGroups += $GroupName

                Write-Information "Cree: $GroupName" -InformationAction Continue
            }
            catch {
                Write-Warning "Erreur creation groupe $($GroupType.Name) : $($_.Exception.Message)"
            }
        }

        Write-Information "$($CityGroups.Count) groupes crees pour $($City.Name)" -InformationAction Continue
    }
    catch {
        Write-Error "Erreur traitement $($City.Name): $($_.Exception.Message)"
        continue
    }
}

Write-Information "`n=== Resume groupes ===" -InformationAction Continue
Write-Information "Total groupes crees: $($CreatedGroups.Keys.Count)" -InformationAction Continue

foreach ($City in $Cities) {
    $Count = ($CreatedGroups.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Information "- $($City.Name): $Count groupes" -InformationAction Continue
}

Write-Information "`n=== Script termine ===" -InformationAction Continue
