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
