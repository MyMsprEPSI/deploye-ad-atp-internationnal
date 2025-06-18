#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour créer des comptes ordinateurs Active Directory dans la structure internationale
.DESCRIPTION
    Ce script crée des comptes ordinateurs dans les OUs Ordinateurs de chaque ville
.NOTES
    Auteur: Thibaut Maurras
    Version: 1.0
    Prérequis: Module ActiveDirectory et droits d'administration sur le domaine
#>

# Configuration
$Configuration = @{
    Domain           = "atp.local"
    BaseOU           = "OU=International,OU=ATP,DC=atp,DC=local"
    WorldStructure   = @{
        "Europe"           = @{
            "France"     = @("Paris", "Lyon", "Marseille", "Monaco", "Toulouse", "Nice", "Nantes", "Strasbourg", "Montpellier", "Bordeaux")
            "Angleterre" = @("Londres", "Manchester", "Birmingham", "Liverpool", "Leeds", "Sheffield", "Bristol", "Newcastle", "Nottingham", "Leicester")
            "Allemagne"  = @("Berlin", "Munich", "Hambourg", "Cologne", "Francfort", "Stuttgart", "Dusseldorf", "Dortmund", "Essen", "Leipzig")
            "Espagne"    = @("Madrid", "Barcelone", "Valence", "Seville", "Saragosse", "Malaga", "Murcie", "Palma", "Las-Palmas", "Bilbao")
            "Italie"     = @("Rome", "Milan", "Naples", "Turin", "Palermo", "Genes", "Bologne", "Florence", "Bari", "Catane")
            "Pays-Bas"   = @("Amsterdam", "Rotterdam", "La-Haye", "Utrecht", "Eindhoven", "Tilburg", "Groningue", "Almere", "Breda", "Nimegue")
            "Belgique"   = @("Bruxelles", "Anvers", "Gand", "Charleroi", "Liege", "Bruges", "Namur", "Louvain", "Mons", "Alost")
            "Suisse"     = @("Zurich", "Geneve", "Bale", "Berne", "Lausanne", "Winterthour", "Lucerne", "Saint-Gall", "Lugano", "Bienne")
        }
        "Amerique-du-Nord" = @{
            "USA"     = @("New-York", "Los-Angeles", "Chicago", "Houston", "Phoenix", "San-Francisco", "Seattle", "Denver", "Boston", "Miami")
            "Canada"  = @("Toronto", "Montreal", "Vancouver", "Calgary", "Edmonton", "Ottawa", "Winnipeg", "Quebec", "Hamilton", "Kitchener")
            "Mexique" = @("Mexico", "Guadalajara", "Monterrey", "Puebla", "Tijuana", "Leon", "Juarez", "Torreon", "Queretaro", "San-Luis-Potosi")
        }
        "Amerique-du-Sud"  = @{
            "Bresil"    = @("Sao-Paulo", "Rio-de-Janeiro", "Brasilia", "Salvador", "Fortaleza", "Belo-Horizonte", "Manaus", "Curitiba", "Recife", "Porto-Alegre")
            "Argentine" = @("Buenos-Aires", "Cordoba", "Rosario", "Mendoza", "Tucuman", "La-Plata", "Mar-del-Plata", "Salta", "Santa-Fe", "San-Juan")
            "Chili"     = @("Santiago", "Valparaiso", "Concepcion", "La-Serena", "Antofagasta", "Temuco", "Rancagua", "Talca", "Arica", "Chillan")
            "Colombie"  = @("Bogota", "Medellin", "Cali", "Barranquilla", "Cartagena", "Cucuta", "Bucaramanga", "Pereira", "Santa-Marta", "Ibague")
            "Perou"     = @("Lima", "Arequipa", "Trujillo", "Chiclayo", "Huancayo", "Piura", "Iquitos", "Cusco", "Chimbote", "Tacna")
        }
        "Asie"             = @{
            "Chine"        = @("Pekin", "Shanghai", "Guangzhou", "Shenzhen", "Tianjin", "Wuhan", "Dongguan", "Chengdu", "Nanjing", "Foshan")
            "Japon"        = @("Tokyo", "Yokohama", "Osaka", "Nagoya", "Sapporo", "Fukuoka", "Kobe", "Kawasaki", "Kyoto", "Saitama")
            "Inde"         = @("Mumbai", "Delhi", "Bangalore", "Hyderabad", "Ahmedabad", "Chennai", "Kolkata", "Surat", "Pune", "Jaipur")
            "Coree-du-Sud" = @("Seoul", "Busan", "Incheon", "Daegu", "Daejeon", "Gwangju", "Suwon", "Ulsan", "Changwon", "Goyang")
            "Singapour"    = @("Singapour")
            "Malaisie"     = @("Kuala-Lumpur", "Johor-Bahru", "Ipoh", "Shah-Alam", "Petaling-Jaya", "Klang", "Seremban", "Iskandar-Puteri", "Kuantan", "Selayang")
            "Thailande"    = @("Bangkok", "Nonthaburi", "Pak-Kret", "Hat-Yai", "Chiang-Mai", "Laem-Chabang", "Khon-Kaen", "Udon-Thani", "Nakhon-Ratchasima", "Rayong")
            "Vietnam"      = @("Ho-Chi-Minh-Ville", "Hanoi", "Hai-Phong", "Da-Nang", "Bien-Hoa", "Hue", "Nha-Trang", "Can-Tho", "Rach-Gia", "Quy-Nhon")
        }
        "Afrique"          = @{
            "Afrique-du-Sud" = @("Le-Cap", "Johannesburg", "Durban", "Pretoria", "Port-Elizabeth", "Pietermaritzburg", "Benoni", "Tembisa", "East-London", "Vereeniging")
            "Nigeria"        = @("Lagos", "Kano", "Ibadan", "Abuja", "Port-Harcourt", "Benin-City", "Maiduguri", "Zaria", "Aba", "Jos")
            "Egypte"         = @("Le-Caire", "Alexandrie", "Gizeh", "Shubra-el-Kheima", "Port-Said", "Suez", "Luxor", "al-Mahalla-al-Kubra", "Tanta", "Asyut")
            "Maroc"          = @("Casablanca", "Rabat", "Fes", "Sale", "Marrakech", "Agadir", "Tanger", "Meknes", "Oujda", "Kenitra")
            "Kenya"          = @("Nairobi", "Mombasa", "Nakuru", "Eldoret", "Kisumu", "Thika", "Malindi", "Kitale", "Garissa", "Kakamega")
            "Ghana"          = @("Accra", "Kumasi", "Tamale", "Sekondi-Takoradi", "Ashaiman", "Sunyani", "Cape-Coast", "Obuasi", "Teshi", "Madina")
        }
        "Oceanie"          = @{
            "Australie"                 = @("Sydney", "Melbourne", "Brisbane", "Perth", "Adelaide", "Gold-Coast", "Newcastle", "Canberra", "Sunshine-Coast", "Wollongong")
            "Nouvelle-Zelande"          = @("Auckland", "Christchurch", "Wellington", "Hamilton", "Tauranga", "Napier-Hastings", "Dunedin", "Palmerston-North", "Nelson", "Rotorua")
            "Papouasie-Nouvelle-Guinee" = @("Port-Moresby", "Lae", "Mount-Hagen", "Popondetta", "Madang", "Wewak", "Vanimo", "Kerema", "Daru", "Mendi")
            "Fidji"                     = @("Suva", "Nadi", "Lautoka", "Labasa", "Ba", "Tavua", "Sigatoka", "Nausori", "Savusavu", "Rakiraki")
        }
    }
    ComputersPerCity = @{
        "Major"  = 100   # Grandes villes
        "Large"  = 50    # Grandes villes
        "Medium" = 25   # Villes moyennes  
        "Small"  = 10    # Petites villes
    }
}

# Générer automatiquement la liste des villes
$Cities = @()
foreach ($Continent in $Configuration.WorldStructure.Keys) {
    $Countries = $Configuration.WorldStructure[$Continent]
    foreach ($Country in $Countries.Keys) {
        $CountryCities = $Countries[$Country]
        # Prendre seulement les 3 premières villes de chaque pays pour éviter trop d'ordinateurs
        foreach ($City in $CountryCities[0..2]) {
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

Write-Host "=== Création des ordinateurs mondiaux ===" -ForegroundColor Cyan
Write-Host "Villes à traiter: $($Cities.Count)" -ForegroundColor Yellow

$TotalComputers = ($Cities | ForEach-Object { $_.ComputerCount } | Measure-Object -Sum).Sum
Write-Host "Total ordinateurs à créer: $TotalComputers" -ForegroundColor Yellow

# Types d'ordinateurs
$ComputerTypes = @("PC", "Laptop", "Workstation")
$Departments = @("Finance", "RH", "IT", "Marketing", "Operations", "Legal")

Write-Host "=== Création des comptes ordinateurs internationaux ===" -ForegroundColor Cyan

Import-Module ActiveDirectory -ErrorAction Stop
Write-Host "Module ActiveDirectory chargé" -ForegroundColor Green

$CreatedComputers = @{}

foreach ($City in $Cities) {
    Write-Host "`n--- Traitement de $($City.Name) ($($City.ComputerCount) ordinateurs) ---" -ForegroundColor Magenta
    
    $ComputersOU = "OU=Ordinateurs,OU=$($City.Name),OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"
    
    # Vérifier que l'OU existe
    try {
        Get-ADOrganizationalUnit -Identity $ComputersOU -ErrorAction Stop | Out-Null
        Write-Host "OU Ordinateurs trouvée: $ComputersOU" -ForegroundColor Green
    }
    catch {
        Write-Host "ERREUR: OU Ordinateurs non trouvée pour $($City.Name)" -ForegroundColor Red
        continue
    }
    
    $CityComputers = @()
    for ($i = 1; $i -le $City.ComputerCount; $i++) {
        $ComputerType = Get-Random -InputObject $ComputerTypes
        $Department = Get-Random -InputObject $Departments
        $ComputerName = "$($ComputerType.ToUpper())-$($City.Name.ToUpper())-$($Department.ToUpper())-$($i.ToString().PadLeft(3, '0'))"
        
        # Nettoyer le nom
        $ComputerName = $ComputerName -replace "-", "" -replace " ", ""
        $ComputerName = $ComputerName.Substring(0, [Math]::Min(15, $ComputerName.Length)) # Limite NetBIOS
        
        try {
            # Vérifier si l'ordinateur existe
            try {
                Get-ADComputer -Identity $ComputerName -ErrorAction Stop | Out-Null
                Write-Host "Ordinateur $ComputerName existe déjà" -ForegroundColor Yellow
                continue
            }
            catch {
                # L'ordinateur n'existe pas
            }
            
            New-ADComputer -Name $ComputerName -Path $ComputersOU -Description "$ComputerType - $Department - $($City.Name)" -Enabled $true -ErrorAction Stop
            $CreatedComputers[$ComputerName] = @{
                City       = $City.Name
                Type       = $ComputerType
                Department = $Department
            }
            $CityComputers += $ComputerName
            
            if ($i % 10 -eq 0 -or $i -eq $City.ComputerCount) {
                Write-Host "Créé: $ComputerName" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Erreur création $ComputerName : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "$($CityComputers.Count) ordinateurs créés pour $($City.Name)" -ForegroundColor Green
}

Write-Host "`n=== Résumé ordinateurs ===" -ForegroundColor Cyan
Write-Host "Total ordinateurs créés: $($CreatedComputers.Keys.Count)" -ForegroundColor Green

foreach ($City in $Configuration.Cities) {
    $Count = ($CreatedComputers.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Host "- $($City.Name): $Count ordinateurs" -ForegroundColor White
}

Write-Host "`n=== Script terminé ===" -ForegroundColor Green
