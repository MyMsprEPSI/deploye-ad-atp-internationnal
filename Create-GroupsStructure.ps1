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
            "USA"     = @("New-York", "Los-Angeles", "Chicago", "Houston", "Phoenix", "Philadelphie", "San-Antonio", "San-Diego", "Dallas", "San-Jose", "Austin", "Jacksonville", "Fort-Worth", "Columbus", "Charlotte", "San-Francisco", "Indianapolis", "Seattle", "Denver", "Washington", "Boston", "El-Paso", "Nashville", "Detroit", "Oklahoma-City", "Portland", "Las-Vegas", "Memphis", "Louisville", "Baltimore", "Milwaukee", "Albuquerque", "Tucson", "Fresno", "Sacramento", "Kansas-City", "Mesa", "Atlanta", "Omaha", "Colorado-Springs", "Raleigh", "Miami", "Long-Beach", "Virginia-Beach", "Oakland", "Minneapolis", "Tampa", "Tulsa", "Arlington", "New-Orleans", "Wichita", "Cleveland", "Bakersfield", "Aurora", "Anaheim", "Honolulu", "Santa-Ana", "Riverside", "Corpus-Christi", "Lexington", "Henderson", "Stockton", "Saint-Paul", "Cincinnati", "Saint-Louis", "Pittsburgh", "Greensboro", "Lincoln", "Anchorage", "Plano", "Orlando", "Irvine", "Newark", "Durham", "Chula-Vista", "Toledo", "Fort-Wayne", "Saint-Petersburg", "Laredo", "Jersey-City", "Chandler", "Madison", "Lubbock", "Scottsdale", "Reno", "Buffalo", "Gilbert", "Glendale", "North-Las-Vegas", "Winston-Salem", "Chesapeake", "Norfolk", "Fremont", "Garland", "Irving", "Hialeah", "Richmond", "Boise", "Spokane", "Baton-Rouge", "Tacoma", "San-Bernardino", "Modesto", "Fontana", "Des-Moines", "Moreno-Valley", "Santa-Clarita", "Fayetteville", "Birmingham", "Oxnard", "Rochester", "Port-Saint-Lucie", "Grand-Rapids", "Huntsville", "Salt-Lake-City", "Frisco", "Yonkers", "Amarillo", "Glendale", "Huntington-Beach", "McKinney", "Montgomery", "Augusta", "Aurora", "Akron", "Little-Rock", "Tempe", "Columbus", "Overland-Park", "Grand-Prairie", "Tallahassee", "Cape-Coral", "Mobile", "Knoxville", "Shreveport", "Worcester", "Ontario", "Vancouver", "Sioux-Falls", "Chattanooga", "Brownsville", "Fort-Lauderdale", "Providence", "Newport-News", "Rancho-Cucamonga", "Santa-Rosa", "Peoria", "Oceanside", "Elk-Grove", "Salem", "Pembroke-Pines", "Eugene", "Garden-Grove", "Cary", "Fort-Collins", "Corona", "Springfield", "Jackson", "Alexandria", "Hayward", "Clarksville", "Lakewood", "Lancaster", "Salinas", "Palmdale", "Hollywood", "Springfield", "Macon", "Kansas-City", "Sunnyvale", "Pomona", "Killeen", "Escondido", "Pasadena", "Naperville", "Bellevue", "Joliet", "Murfreesboro", "Midland", "Rockford", "Paterson", "Savannah", "Bridgeport", "Torrance", "McAllen", "Syracuse", "Surprise", "Denton", "Roseville", "Thornton", "Miramar", "Pasadena", "Mesquite", "Olathe", "Dayton", "Carrollton", "Waco", "Orange", "Fullerton", "Charleston", "Warren", "Hampton", "Gainesville", "Visalia", "Coral-Springs", "Cedar-Rapids", "Round-Rock", "Sterling-Heights", "Kent", "Columbia", "Santa-Clara", "New-Haven", "Stamford", "Concord", "Elizabeth", "Thousand-Oaks", "Lafayette", "Simi-Valley", "Topeka", "Norman", "Fargo", "Wilmington", "Abilene", "Odessa", "Beaumont", "Wichita-Falls", "Cambridge", "Westminster", "Arvada", "Allentown", "Ann-Arbor", "Independence", "Rochester", "Elgin", "West-Valley-City", "Clearwater", "Inglewood", "Evansville", "Miami-Gardens", "Carlsbad", "Lowell", "Provo", "West-Jordan", "Gresham", "Temecula", "Lansing", "North-Charleston", "Costa-Mesa", "Peoria", "Ponte-Vedra")
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
