#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour créer des comptes ordinateurs Active Directory dans la structure internationale
.DESCRIPTION
    Ce script crée des comptes ordinateurs dans les OUs Ordinateurs de chaque ville
.NOTES
    Auteur: Thibaut Maurras
    Version: 1.1
    Prérequis: Module ActiveDirectory et droits d'administration sur le domaine
#>

# Configuration
$Configuration = @{
    Domain           = "atp.local"
    BaseOU           = "OU=International,OU=ATP,DC=atp,DC=local"
    WorldStructure   = @{
        "Europe"           = @{
            "France"     = @("Paris", "Lyon", "Marseille", "Monaco", "Toulouse")
            "Angleterre" = @("Londres", "Manchester", "Birmingham")
            "Allemagne"  = @("Berlin", "Munich", "Hambourg")
            "Espagne"    = @("Madrid", "Barcelone", "Valence")
            "Italie"     = @("Rome", "Milan", "Naples")
        }
        "Amerique-du-Nord" = @{
            "USA"     = @("New-York", "Los-Angeles", "Chicago", "Houston", "Phoenix")
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

Write-Host "=== Création des ordinateurs mondiaux ===" -ForegroundColor Cyan
Write-Host "Villes à traiter: $($Cities.Count)" -ForegroundColor Yellow

$TotalComputers = ($Cities | ForEach-Object { $_.ComputerCount } | Measure-Object -Sum).Sum
Write-Host "Total ordinateurs à créer: $TotalComputers" -ForegroundColor Yellow

Import-Module ActiveDirectory -ErrorAction Stop
Write-Host "Module ActiveDirectory chargé" -ForegroundColor Green

$CreatedComputers = @{}

foreach ($City in $Cities) {
    Write-Host "`n--- Traitement de $($City.Name) ($($City.ComputerCount) ordinateurs) ---" -ForegroundColor Magenta
    
    try {
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
            try {
                $ComputerType = Get-Random -InputObject $ComputerTypes
                $Department = Get-Random -InputObject $Departments
                $ComputerName = "$($ComputerType.ToUpper())-$($City.Name.ToUpper())-$($Department.ToUpper())-$($i.ToString().PadLeft(3, '0'))"
                
                # Nettoyer le nom
                $ComputerName = $ComputerName -replace "-", "" -replace " ", ""
                $ComputerName = $ComputerName.Substring(0, [Math]::Min(15, $ComputerName.Length)) # Limite NetBIOS
                
                # Vérifier si l'ordinateur existe
                try {
                    Get-ADComputer -Identity $ComputerName -ErrorAction Stop | Out-Null
                    Write-Host "Ordinateur $ComputerName existe déjà" -ForegroundColor Yellow
                    continue
                } 
                catch {
                    # L'ordinateur n'existe pas, on peut le créer
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
                Write-Host "Erreur création ordinateur $i : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host "$($CityComputers.Count) ordinateurs créés pour $($City.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur traitement $($City.Name): $($_.Exception.Message)" -ForegroundColor Red
        continue
    }
}

Write-Host "`n=== Résumé ordinateurs ===" -ForegroundColor Cyan
Write-Host "Total ordinateurs créés: $($CreatedComputers.Keys.Count)" -ForegroundColor Green

foreach ($City in $Cities) {
    $Count = ($CreatedComputers.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Host "- $($City.Name): $Count ordinateurs" -ForegroundColor White
}

Write-Host "`n=== Script terminé ===" -ForegroundColor Green
Write-Host "`n=== Résumé ordinateurs ===" -ForegroundColor Cyan
Write-Host "Total ordinateurs créés: $($CreatedComputers.Keys.Count)" -ForegroundColor Green

foreach ($City in $Configuration.Cities) {
    $Count = ($CreatedComputers.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Host "- $($City.Name): $Count ordinateurs" -ForegroundColor White
}

Write-Host "`n=== Script terminé ===" -ForegroundColor Green
