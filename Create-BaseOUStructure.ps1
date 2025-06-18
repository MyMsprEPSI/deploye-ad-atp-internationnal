#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour créer la structure de base des OUs ATP International
.DESCRIPTION
    Ce script crée la structure OU de base complète mondiale nécessaire avant la création des utilisateurs
.NOTES
    Auteur: Thibaut Maurras
    Version: 2.0
    Prérequis: Module ActiveDirectory et droits d'administration sur le domaine
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

try {
    Write-Host "=== Création de la structure mondiale complète OU ATP ===" -ForegroundColor Cyan
    
    # Vérifier le module ActiveDirectory
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Host "Module ActiveDirectory chargé" -ForegroundColor Green
    
    # Vérifier la connectivité au domaine
    try {
        $Domain = Get-ADDomain -ErrorAction Stop
        Write-Host "Connecté au domaine: $($Domain.DNSRoot)" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur: Impossible de se connecter au domaine ATP" -ForegroundColor Red
        exit 1
    }
    
    # Créer la structure de base ATP et International
    Write-Host "`n=== Création de la structure de base ===" -ForegroundColor Yellow
    foreach ($OU in $Configuration.BaseOUStructure) {
        $FullPath = "OU=$($OU.Name),$($OU.Path)"
        
        try {
            Get-ADOrganizationalUnit -Identity $FullPath -ErrorAction Stop | Out-Null
            Write-Host "OU '$($OU.Name)' existe déjà: $FullPath" -ForegroundColor Yellow
        }
        catch {
            try {
                New-ADOrganizationalUnit -Name $OU.Name -Path $OU.Path -Description $OU.Description -ErrorAction Stop
                Write-Host "OU '$($OU.Name)' créée avec succès: $FullPath" -ForegroundColor Green
            }
            catch {
                Write-Host "Erreur lors de la création de l'OU '$($OU.Name)': $($_.Exception.Message)" -ForegroundColor Red
                exit 1
            }
        }
    }
    
    # Créer la structure mondiale complète
    $BaseInternationalOU = "OU=International,OU=ATP,DC=atp,DC=local"
    $TotalContinents = $Configuration.WorldStructure.Keys.Count
    $CurrentContinent = 0
    
    Write-Host "`n=== Création de la structure mondiale ===" -ForegroundColor Yellow
    Write-Host "Création de $TotalContinents continents avec leurs pays et villes..." -ForegroundColor Cyan
    
    foreach ($Continent in $Configuration.WorldStructure.Keys) {
        $CurrentContinent++
        Write-Host "`n[$CurrentContinent/$TotalContinents] Traitement du continent: $Continent" -ForegroundColor Magenta
        
        # Créer OU Continent
        $ContinentOU = "OU=$Continent,$BaseInternationalOU"
        try {
            Get-ADOrganizationalUnit -Identity $ContinentOU -ErrorAction Stop | Out-Null
            Write-Host "  Continent $Continent existe déjà" -ForegroundColor Yellow
        }
        catch {
            New-ADOrganizationalUnit -Name $Continent -Path $BaseInternationalOU -Description "Continent $Continent" -ErrorAction Stop
            Write-Host "  Continent $Continent créé" -ForegroundColor Green
        }
        
        $Countries = $Configuration.WorldStructure[$Continent]
        $TotalCountries = $Countries.Keys.Count
        $CurrentCountry = 0
        
        foreach ($Country in $Countries.Keys) {
            $CurrentCountry++
            Write-Host "    [$CurrentCountry/$TotalCountries] Pays: $Country" -ForegroundColor White
            
            # Créer OU Pays
            $CountryOU = "OU=$Country,$ContinentOU"
            try {
                Get-ADOrganizationalUnit -Identity $CountryOU -ErrorAction Stop | Out-Null
            }
            catch {
                New-ADOrganizationalUnit -Name $Country -Path $ContinentOU -Description "Pays $Country" -ErrorAction Stop
                Write-Host "      Pays $Country créé" -ForegroundColor Green
            }
            
            $Cities = $Countries[$Country]
            $TotalCities = $Cities.Count
            
            # Créer les villes par batch pour améliorer les performances
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
                        
                        # Créer les sous-OUs dans chaque ville
                        $SubOUs = @("Utilisateurs", "Ordinateurs", "Serveurs", "Groupes")
                        foreach ($SubOU in $SubOUs) {
                            try {
                                New-ADOrganizationalUnit -Name $SubOU -Path $CityOU -Description "$SubOU de $City" -ErrorAction Stop
                            }
                            catch {
                                Write-Host "        Erreur création $SubOU dans $City : $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                    }
                    catch {
                        Write-Host "        Erreur création ville $City : $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
            
            if ($CreatedCities -gt 0) {
                Write-Host "      $CreatedCities/$TotalCities villes créées pour $Country (avec sous-OUs)" -ForegroundColor Green
            }
            else {
                Write-Host "      $TotalCities villes existantes pour $Country" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "`n=== Vérification de la structure créée ===" -ForegroundColor Cyan
    
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
    
    Write-Host "Structure mondiale créée:" -ForegroundColor Green
    Write-Host "  - OUs de base: 2 (ATP + International)" -ForegroundColor White
    Write-Host "  - Continents: $ContinentCount" -ForegroundColor White
    Write-Host "  - Pays: $CountryCount" -ForegroundColor White
    Write-Host "  - Villes: $CityCount" -ForegroundColor White
    Write-Host "  - Sous-OUs par ville: 4 (Utilisateurs, Ordinateurs, Serveurs, Groupes)" -ForegroundColor White
    Write-Host "  - Total OUs: $TotalOUs" -ForegroundColor Cyan
    
    # Vérifier la structure finale
    $FinalOU = "OU=International,OU=ATP,DC=atp,DC=local"
    try {
        $InternationalOU = Get-ADOrganizationalUnit -Identity $FinalOU -ErrorAction Stop
        Write-Host "`n✓ Structure de base prête: $FinalOU" -ForegroundColor Green
        Write-Host "  Description: $($InternationalOU.Description)" -ForegroundColor Gray
        Write-Host "  Créée le: $($InternationalOU.WhenCreated)" -ForegroundColor Gray
    }
    catch {
        Write-Host "`n✗ Erreur: La structure finale n'est pas accessible" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n=== Structure mondiale complète créée avec succès ===" -ForegroundColor Green
    Write-Host "Vous pouvez maintenant exécuter le script Create-UserStructure.ps1" -ForegroundColor Yellow
    Write-Host "La structure couvre tous les continents avec leurs principales villes" -ForegroundColor Cyan
    
}
catch {
    Write-Host "`nErreur fatale: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
