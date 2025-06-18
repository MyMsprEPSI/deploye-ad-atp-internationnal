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
            "Angleterre" = @("Londres", "Manchester", "Birmingham", "Liverpool", "Leeds")
            "Allemagne"  = @("Berlin", "Munich", "Hambourg", "Cologne", "Francfort")
            "Espagne"    = @("Madrid", "Barcelone", "Valence", "Seville", "Saragosse")
            "Italie"     = @("Rome", "Milan", "Naples", "Turin", "Palermo")
            "Pays-Bas"   = @("Amsterdam", "Rotterdam", "La-Haye", "Utrecht", "Eindhoven")
            "Belgique"   = @("Bruxelles", "Anvers", "Gand", "Charleroi", "Liege")
            "Suisse"     = @("Zurich", "Geneve", "Bale", "Berne", "Lausanne")
        }
        "Amerique-du-Nord" = @{
            "USA"     = @("New-York", "Los-Angeles", "Chicago", "Houston", "Ponte-Vedra")
            "Canada"  = @("Toronto", "Montreal", "Vancouver", "Calgary", "Edmonton")
            "Mexique" = @("Mexico", "Guadalajara", "Monterrey", "Puebla", "Tijuana")
        }
        "Amerique-du-Sud"  = @{
            "Bresil"    = @("Sao-Paulo", "Rio-de-Janeiro", "Brasilia", "Salvador", "Fortaleza")
            "Argentine" = @("Buenos-Aires", "Cordoba", "Rosario", "Mendoza", "Tucuman")
            "Chili"     = @("Santiago", "Valparaiso", "Concepcion", "La-Serena", "Antofagasta")
            "Colombie"  = @("Bogota", "Medellin", "Cali", "Barranquilla", "Cartagena")
            "Perou"     = @("Lima", "Arequipa", "Trujillo", "Chiclayo", "Huancayo")
        }
        "Asie"             = @{
            "Chine"        = @("Pekin", "Shanghai", "Guangzhou", "Shenzhen", "Tianjin")
            "Japon"        = @("Tokyo", "Yokohama", "Osaka", "Nagoya", "Sapporo")
            "Inde"         = @("Mumbai", "Delhi", "Bangalore", "Hyderabad", "Ahmedabad")
            "Coree-du-Sud" = @("Seoul", "Busan", "Incheon", "Daegu", "Daejeon")
            "Singapour"    = @("Singapour")
            "Malaisie"     = @("Kuala-Lumpur", "Johor-Bahru", "Ipoh", "Shah-Alam", "Petaling-Jaya")
            "Thailande"    = @("Bangkok", "Nonthaburi", "Pak-Kret", "Hat-Yai", "Chiang-Mai")
            "Vietnam"      = @("Ho-Chi-Minh-Ville", "Hanoi", "Hai-Phong", "Da-Nang", "Bien-Hoa")
        }
        "Afrique"          = @{
            "Afrique-du-Sud" = @("Le-Cap", "Johannesburg", "Durban", "Pretoria", "Port-Elizabeth")
            "Nigeria"        = @("Lagos", "Kano", "Ibadan", "Abuja", "Port-Harcourt")
            "Egypte"         = @("Le-Caire", "Alexandrie", "Gizeh", "Shubra-el-Kheima", "Port-Said")
            "Maroc"          = @("Casablanca", "Rabat", "Fes", "Sale", "Marrakech")
            "Kenya"          = @("Nairobi", "Mombasa", "Nakuru", "Eldoret", "Kisumu")
            "Ghana"          = @("Accra", "Kumasi", "Tamale", "Sekondi-Takoradi", "Ashaiman")
        }
        "Oceanie"          = @{
            "Australie"                 = @("Sydney", "Melbourne", "Brisbane", "Perth", "Adelaide")
            "Nouvelle-Zelande"          = @("Auckland", "Christchurch", "Wellington", "Hamilton", "Tauranga")
            "Papouasie-Nouvelle-Guinee" = @("Port-Moresby", "Lae", "Mount-Hagen", "Popondetta", "Madang")
            "Fidji"                     = @("Suva", "Nadi", "Lautoka", "Labasa", "Ba")
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
