#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour creer des comptes serveurs Active Directory dans la structure internationale
.DESCRIPTION
    Ce script cree des comptes serveurs dans les OUs Serveurs de chaque ville
.NOTES
    Auteur: Thibaut Maurras
    Version: 2025.06.18
    Prerequis: Module ActiveDirectory et droits d'administration sur le domaine
#>

# Configuration
$Configuration = @{
    Domain         = "atp.local"
    BaseOU         = "OU=International,OU=ATP,DC=atp,DC=local"
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
    ServersPerCity = @{
        "Major"  = 15    # Grandes villes (centres de donnees)
        "Large"  = 8     # Grandes villes
        "Medium" = 5    # Villes moyennes
        "Small"  = 3     # Petites villes
    }
}

# Types de serveurs
$ServerRoles = @("DC", "FILE", "PRINT", "WEB", "DB", "APP", "MAIL", "DNS", "DHCP", "BACKUP")

# Générer automatiquement la liste des villes avec serveurs
$Cities = @()
foreach ($Continent in $Configuration.WorldStructure.Keys) {
    $Countries = $Configuration.WorldStructure[$Continent]
    foreach ($Country in $Countries.Keys) {
        $CountryCities = $Countries[$Country]
        # Prendre seulement les 2 premières villes de chaque pays pour les serveurs
        foreach ($City in $CountryCities[0..1]) {
            if ($City) {
                $CitySize = if ($CountryCities[0] -eq $City) { "Major" } else { "Large" }
                
                $Cities += @{
                    Name        = $City
                    Country     = $Country
                    Continent   = $Continent
                    ServerCount = $Configuration.ServersPerCity[$CitySize]
                }
            }
        }
    }
}

Write-Information "=== Creation des serveurs mondiaux ===" -InformationAction Continue
Write-Information "Villes a traiter: $($Cities.Count)" -InformationAction Continue

$TotalServers = ($Cities | ForEach-Object { $_.ServerCount } | Measure-Object -Sum).Sum
Write-Information "Total serveurs a creer: $TotalServers" -InformationAction Continue

Import-Module ActiveDirectory -ErrorAction Stop
Write-Information "Module ActiveDirectory charge" -InformationAction Continue

$CreatedServers = @{}

foreach ($City in $Cities) {
    Write-Information "`n--- Traitement de $($City.Name) ($($City.ServerCount) serveurs) ---" -InformationAction Continue

    try {
        $ServersOU = "OU=Serveurs,OU=$($City.Name),OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"

        # Verifier que l'OU existe
        try {
            Get-ADOrganizationalUnit -Identity $ServersOU -ErrorAction Stop | Out-Null
            Write-Information "OU Serveurs trouvee: $ServersOU" -InformationAction Continue
        }
        catch {
            Write-Error "OU Serveurs non trouvee pour $($City.Name)"
            continue
        }

        $CityServers = @()
        for ($i = 1; $i -le $City.ServerCount; $i++) {
            try {
                $ServerRole = Get-Random -InputObject $ServerRoles
                $CityCode = $City.Name.Substring(0, [Math]::Min(3, $City.Name.Length)).ToUpper()
                $ServerName = "$CityCode-$ServerRole-$($i.ToString().PadLeft(2, '0'))"

                # Nettoyer le nom
                $ServerName = $ServerName -replace "-", "" -replace " ", ""
                $ServerName = $ServerName.Substring(0, [Math]::Min(15, $ServerName.Length))

                # Verifier si le serveur existe
                try {
                    Get-ADComputer -Identity $ServerName -ErrorAction Stop | Out-Null
                    Write-Information "Serveur $ServerName existe deja" -InformationAction Continue
                    continue
                }
                catch {
                    # Le serveur n'existe pas, on peut le creer
                }

                New-ADComputer -Name $ServerName -Path $ServersOU -Description "Serveur $ServerRole - $($City.Name)" -Enabled $true -ErrorAction Stop
                $CreatedServers[$ServerName] = @{
                    City = $City.Name
                    Role = $ServerRole
                }
                $CityServers += $ServerName

                Write-Information "Cree: $ServerName ($ServerRole)" -InformationAction Continue
            }
            catch {
                Write-Warning "Erreur creation serveur $i : $($_.Exception.Message)"
            }
        }

        Write-Information "$($CityServers.Count) serveurs crees pour $($City.Name)" -InformationAction Continue
    }
    catch {
        Write-Error "Erreur traitement $($City.Name): $($_.Exception.Message)"
        continue
    }
}

Write-Information "`n=== Resume serveurs ===" -InformationAction Continue
Write-Information "Total serveurs crees: $($CreatedServers.Keys.Count)" -InformationAction Continue

foreach ($City in $Cities) {
    $Count = ($CreatedServers.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Information "- $($City.Name): $Count serveurs" -InformationAction Continue
}

Write-Information "`n=== Script termine ===" -InformationAction Continue
Write-Host "- $($City.Name): $Count serveurs" -ForegroundColor White
Write-Host "`n=== Script terminé ===" -ForegroundColor Green
