#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour créer des comptes serveurs Active Directory dans la structure internationale
.DESCRIPTION
    Ce script crée des comptes serveurs dans les OUs Serveurs de chaque ville
.NOTES
    Auteur: Thibaut Maurras
    Version: 1.1
    Prérequis: Module ActiveDirectory et droits d'administration sur le domaine
#>

# Configuration
$Configuration = @{
    Domain = "atp.local"
    BaseOU = "OU=International,OU=ATP,DC=atp,DC=local"
    WorldStructure = @{
        "Europe"           = @{
            "France"     = @("Paris", "Lyon", "Marseille")
            "Angleterre" = @("Londres", "Manchester", "Birmingham")
            "Allemagne"  = @("Berlin", "Munich", "Hambourg")
            "Espagne"    = @("Madrid", "Barcelone", "Valence")
            "Italie"     = @("Rome", "Milan", "Naples")
        }
        "Amerique-du-Nord" = @{
            "USA"     = @("New-York", "Los-Angeles", "Chicago")
            "Canada"  = @("Toronto", "Montreal", "Vancouver")
            "Mexique" = @("Mexico", "Guadalajara", "Monterrey")
        }
        "Amerique-du-Sud"  = @{
            "Bresil"    = @("Sao-Paulo", "Rio-de-Janeiro", "Brasilia")
            "Argentine" = @("Buenos-Aires", "Cordoba", "Rosario")
            "Chili"     = @("Santiago", "Valparaiso", "Concepcion")
        }
        "Asie"             = @{
            "Chine" = @("Pekin", "Shanghai", "Guangzhou")
            "Japon" = @("Tokyo", "Yokohama", "Osaka")
            "Inde"  = @("Mumbai", "Delhi", "Bangalore")
        }
        "Afrique"          = @{
            "Afrique-du-Sud" = @("Le-Cap", "Johannesburg", "Durban")
            "Nigeria"        = @("Lagos", "Kano", "Ibadan")
            "Egypte"         = @("Le-Caire", "Alexandrie", "Gizeh")
        }
        "Oceanie"          = @{
            "Australie"        = @("Sydney", "Melbourne", "Brisbane")
            "Nouvelle-Zelande" = @("Auckland", "Christchurch", "Wellington")
        }
    }
    ServersPerCity = @{
        "Major" = 15    # Grandes villes (centres de données)
        "Large" = 8     # Grandes villes
        "Medium" = 5    # Villes moyennes
        "Small" = 3     # Petites villes
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
                    Name = $City
                    Country = $Country
                    Continent = $Continent
                    ServerCount = $Configuration.ServersPerCity[$CitySize]
                }
            }
        }
    }
}

Write-Host "=== Création des serveurs mondiaux ===" -ForegroundColor Cyan
Write-Host "Villes à traiter: $($Cities.Count)" -ForegroundColor Yellow

$TotalServers = ($Cities | ForEach-Object { $_.ServerCount } | Measure-Object -Sum).Sum
Write-Host "Total serveurs à créer: $TotalServers" -ForegroundColor Yellow

Import-Module ActiveDirectory -ErrorAction Stop
Write-Host "Module ActiveDirectory chargé" -ForegroundColor Green

$CreatedServers = @{}

foreach ($City in $Cities) {
    Write-Host "`n--- Traitement de $($City.Name) ($($City.ServerCount) serveurs) ---" -ForegroundColor Magenta
    
    try {
        $ServersOU = "OU=Serveurs,OU=$($City.Name),OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"
        
        # Vérifier que l'OU existe
        try {
            Get-ADOrganizationalUnit -Identity $ServersOU -ErrorAction Stop | Out-Null
            Write-Host "OU Serveurs trouvée: $ServersOU" -ForegroundColor Green
        } 
        catch {
            Write-Host "ERREUR: OU Serveurs non trouvée pour $($City.Name)" -ForegroundColor Red
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
                
                # Vérifier si le serveur existe
                try {
                    Get-ADComputer -Identity $ServerName -ErrorAction Stop | Out-Null
                    Write-Host "Serveur $ServerName existe déjà" -ForegroundColor Yellow
                    continue
                } 
                catch {
                    # Le serveur n'existe pas, on peut le créer
                }
                
                New-ADComputer -Name $ServerName -Path $ServersOU -Description "Serveur $ServerRole - $($City.Name)" -Enabled $true -ErrorAction Stop
                $CreatedServers[$ServerName] = @{
                    City = $City.Name
                    Role = $ServerRole
                }
                $CityServers += $ServerName
                
                Write-Host "Créé: $ServerName ($ServerRole)" -ForegroundColor Green
            } 
            catch {
                Write-Host "Erreur création serveur $i : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host "$($CityServers.Count) serveurs créés pour $($City.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur traitement $($City.Name): $($_.Exception.Message)" -ForegroundColor Red
        continue
    }
}

Write-Host "`n=== Résumé serveurs ===" -ForegroundColor Cyan
Write-Host "Total serveurs créés: $($CreatedServers.Keys.Count)" -ForegroundColor Green

foreach ($City in $Cities) {
    $Count = ($CreatedServers.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Host "- $($City.Name): $Count serveurs" -ForegroundColor White
}

Write-Host "`n=== Script terminé ===" -ForegroundColor Green
    Write-Host "- $($City.Name): $Count serveurs" -ForegroundColor White
}

Write-Host "`n=== Script terminé ===" -ForegroundColor Green
