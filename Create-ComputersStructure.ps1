#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour creer des comptes ordinateurs Active Directory dans la structure internationale
.DESCRIPTION
    Ce script cree des comptes ordinateurs dans les OUs Ordinateurs de chaque ville
.NOTES
    Auteur: Thibaut Maurras
    Version: 2025.06.18
    Prerequis: Module ActiveDirectory et droits d'administration sur le domaine
#>

# Configuration
$Configuration = @{
    Domain           = "atp.local"
    BaseOU           = "OU=International,OU=ATP,DC=atp,DC=local"
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
    ComputersPerCity = @{
        "Major"  = 100   # Grandes villes
        "Large"  = 50    # Grandes villes
        "Medium" = 25   # Villes moyennes
        "Small"  = 10    # Petites villes
    }
}

# Types d'ordinateurs
$ComputerTypes = @("PC", "Laptop", "Workstation")
$Departments = @("Finance", "RH", "IT", "Marketing", "Operations", "Legal")

# Générer automatiquement la liste des villes
$Cities = @()
foreach ($Continent in $Configuration.WorldStructure.Keys) {
    $Countries = $Configuration.WorldStructure[$Continent]
    foreach ($Country in $Countries.Keys) {
        $CountryCities = $Countries[$Country]
        # Prendre seulement les 3 premières villes de chaque pays pour éviter trop d'ordinateurs
        foreach ($City in $CountryCities[0..2]) {
            if ($City) {
                $CitySize = if ($CountryCities[0] -eq $City) { "Major" } 
                elseif ($CountryCities[1] -eq $City) { "Large" }
                else { "Medium" }
                
                $Cities += @{
                    Name          = $City
                    Country       = $Country
                    Continent     = $Continent
                    ComputerCount = $Configuration.ComputersPerCity[$CitySize]
                }
            }
        }
    }
}

Write-Information "=== Creation des ordinateurs mondiaux ===" -InformationAction Continue
Write-Information "Villes a traiter: $($Cities.Count)" -InformationAction Continue

$TotalComputers = ($Cities | ForEach-Object { $_.ComputerCount } | Measure-Object -Sum).Sum
Write-Information "Total ordinateurs a creer: $TotalComputers" -InformationAction Continue

Import-Module ActiveDirectory -ErrorAction Stop
Write-Information "Module ActiveDirectory charge" -InformationAction Continue

$CreatedComputers = @{}

foreach ($City in $Cities) {
    Write-Information "`n--- Traitement de $($City.Name) ($($City.ComputerCount) ordinateurs) ---" -InformationAction Continue

    try {
        $ComputersOU = "OU=Ordinateurs,OU=$($City.Name),OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"

        # Verifier que l'OU existe
        try {
            Get-ADOrganizationalUnit -Identity $ComputersOU -ErrorAction Stop | Out-Null
            Write-Information "OU Ordinateurs trouvee: $ComputersOU" -InformationAction Continue
        }
        catch {
            Write-Error "OU Ordinateurs non trouvee pour $($City.Name)"
            continue
        }

        $CityComputers = @()
        for ($i = 1; $i -le $City.ComputerCount; $i++) {
            try {
                $ComputerType = Get-Random -InputObject $ComputerTypes
                $Department = Get-Random -InputObject $Departments
                $ComputerName = "$($ComputerType.ToUpper())-$($City.Name.ToUpper())-$($Department.ToUpper())-$($i.ToString().PadLeft(3, '0'))"

                # Nettoyer le nom
                $ComputerName = $ComputerName -replace "-", "" -replace " ", ""
                $ComputerName = $ComputerName.Substring(0, [Math]::Min(15, $ComputerName.Length)) # Limite NetBIOS

                # Verifier si l'ordinateur existe
                try {
                    Get-ADComputer -Identity $ComputerName -ErrorAction Stop | Out-Null
                    Write-Information "Ordinateur $ComputerName existe deja" -InformationAction Continue
                    continue
                }
                catch {
                    # L'ordinateur n'existe pas, on peut le creer
                }

                New-ADComputer -Name $ComputerName -Path $ComputersOU -Description "$ComputerType - $Department - $($City.Name)" -Enabled $true -ErrorAction Stop
                $CreatedComputers[$ComputerName] = @{
                    City       = $City.Name
                    Type       = $ComputerType
                    Department = $Department
                }
                $CityComputers += $ComputerName

                if ($i % 10 -eq 0 -or $i -eq $City.ComputerCount) {
                    Write-Information "Cree: $ComputerName" -InformationAction Continue
                }
            }
            catch {
                Write-Warning "Erreur creation ordinateur $i : $($_.Exception.Message)"
            }
        }

        Write-Information "$($CityComputers.Count) ordinateurs crees pour $($City.Name)" -InformationAction Continue
    }
    catch {
        Write-Error "Erreur traitement $($City.Name): $($_.Exception.Message)"
        continue
    }
}

Write-Information "`n=== Resume ordinateurs ===" -InformationAction Continue
Write-Information "Total ordinateurs crees: $($CreatedComputers.Keys.Count)" -InformationAction Continue

foreach ($City in $Cities) {
    $Count = ($CreatedComputers.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Information "- $($City.Name): $Count ordinateurs" -InformationAction Continue
}

Write-Information "`n=== Script termine ===" -InformationAction Continue
Write-Host "`n=== Résumé ordinateurs ===" -ForegroundColor Cyan
Write-Host "Total ordinateurs créés: $($CreatedComputers.Keys.Count)" -ForegroundColor Green

foreach ($City in $Configuration.Cities) {
    $Count = ($CreatedComputers.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Host "- $($City.Name): $Count ordinateurs" -ForegroundColor White
}

Write-Host "`n=== Script terminé ===" -ForegroundColor Green
