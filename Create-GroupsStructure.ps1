#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour créer des groupes Active Directory dans la structure internationale
.DESCRIPTION
    Ce script crée des groupes dans les OUs Groupes de chaque ville
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
}

# Types de groupes
$GroupTypes = @(
    @{ Name = "Administrateurs"; Scope = "DomainLocal"; Category = "Security"; Description = "Administrateurs locaux" },
    @{ Name = "Utilisateurs"; Scope = "DomainLocal"; Category = "Security"; Description = "Utilisateurs standard" },
    @{ Name = "Finance"; Scope = "Global"; Category = "Security"; Description = "Département Finance" },
    @{ Name = "RH"; Scope = "Global"; Category = "Security"; Description = "Ressources Humaines" },
    @{ Name = "IT"; Scope = "Global"; Category = "Security"; Description = "Technologies de l'Information" },
    @{ Name = "Marketing"; Scope = "Global"; Category = "Security"; Description = "Département Marketing" },
    @{ Name = "Operations"; Scope = "Global"; Category = "Security"; Description = "Département Opérations" },
    @{ Name = "Legal"; Scope = "Global"; Category = "Security"; Description = "Département Juridique" },
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

Write-Host "=== Création des groupes mondiaux ===" -ForegroundColor Cyan
Write-Host "Villes à traiter: $($Cities.Count)" -ForegroundColor Yellow

$TotalGroups = $Cities.Count * $GroupTypes.Count
Write-Host "Total groupes à créer: $TotalGroups" -ForegroundColor Yellow

Import-Module ActiveDirectory -ErrorAction Stop
Write-Host "Module ActiveDirectory chargé" -ForegroundColor Green

$CreatedGroups = @{}

foreach ($City in $Cities) {
    Write-Host "`n--- Traitement de $($City.Name) ---" -ForegroundColor Magenta
    
    try {
        $GroupsOU = "OU=Groupes,OU=$($City.Name),OU=$($City.Country),OU=$($City.Continent),$($Configuration.BaseOU)"
        
        # Vérifier que l'OU existe
        try {
            Get-ADOrganizationalUnit -Identity $GroupsOU -ErrorAction Stop | Out-Null
            Write-Host "OU Groupes trouvée: $GroupsOU" -ForegroundColor Green
        } 
        catch {
            Write-Host "ERREUR: OU Groupes non trouvée pour $($City.Name)" -ForegroundColor Red
            continue
        }
        
        $CityGroups = @()
        foreach ($GroupType in $GroupTypes) {
            try {
                $GroupName = "GRP_$($City.Name.ToUpper())_$($GroupType.Name.ToUpper())"
                
                # Vérifier si le groupe existe
                try {
                    Get-ADGroup -Identity $GroupName -ErrorAction Stop | Out-Null
                    Write-Host "Groupe $GroupName existe déjà" -ForegroundColor Yellow
                    continue
                } 
                catch {
                    # Le groupe n'existe pas, on peut le créer
                }
                
                New-ADGroup -Name $GroupName -Path $GroupsOU -GroupScope $GroupType.Scope -GroupCategory $GroupType.Category -Description "$($GroupType.Description) - $($City.Name)" -ErrorAction Stop
                $CreatedGroups[$GroupName] = @{
                    City = $City.Name
                    Type = $GroupType.Name
                    Scope = $GroupType.Scope
                }
                $CityGroups += $GroupName
                
                Write-Host "Créé: $GroupName" -ForegroundColor Green
            } 
            catch {
                Write-Host "Erreur création groupe $($GroupType.Name) : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host "$($CityGroups.Count) groupes créés pour $($City.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur traitement $($City.Name): $($_.Exception.Message)" -ForegroundColor Red
        continue
    }
}

Write-Host "`n=== Résumé groupes ===" -ForegroundColor Cyan
Write-Host "Total groupes créés: $($CreatedGroups.Keys.Count)" -ForegroundColor Green

foreach ($City in $Cities) {
    $Count = ($CreatedGroups.Values | Where-Object { $_.City -eq $City.Name }).Count
    Write-Host "- $($City.Name): $Count groupes" -ForegroundColor White
}

Write-Host "`n=== Script terminé ===" -ForegroundColor Green
