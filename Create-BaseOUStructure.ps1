#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Script pour créer la structure de base des OUs ATP International
.DESCRIPTION
    Ce script crée la structure OU de base nécessaire avant la création des utilisateurs
.NOTES
    Auteur: Thibaut Maurras
    Version: 1.0
    Prérequis: Module ActiveDirectory et droits d'administration sur le domaine
#>

# Configuration
$Configuration = @{
    BaseDN = "DC=atp,DC=local"
    OUStructure = @(
        @{ Name = "ATP"; Path = "DC=atp,DC=local"; Description = "Organisation ATP" },
        @{ Name = "International"; Path = "OU=ATP,DC=atp,DC=local"; Description = "Division Internationale ATP" }
    )
}

try {
    Write-Host "=== Création de la structure de base OU ATP ===" -ForegroundColor Cyan
    
    # Vérifier le module ActiveDirectory
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Host "Module ActiveDirectory chargé" -ForegroundColor Green
    
    # Vérifier la connectivité au domaine
    try {
        $Domain = Get-ADDomain -ErrorAction Stop
        Write-Host "Connecté au domaine: $($Domain.DNSRoot)" -ForegroundColor Green
    } catch {
        Write-Host "Erreur: Impossible de se connecter au domaine ATP" -ForegroundColor Red
        exit 1
    }
    
    # Créer chaque OU de la structure de base
    foreach ($OU in $Configuration.OUStructure) {
        $FullPath = "OU=$($OU.Name),$($OU.Path)"
        
        try {
            # Vérifier si l'OU existe déjà
            Get-ADOrganizationalUnit -Identity $FullPath -ErrorAction Stop | Out-Null
            Write-Host "OU '$($OU.Name)' existe déjà: $FullPath" -ForegroundColor Yellow
        } catch {
            try {
                # Créer l'OU
                New-ADOrganizationalUnit -Name $OU.Name -Path $OU.Path -Description $OU.Description -ErrorAction Stop
                Write-Host "OU '$($OU.Name)' créée avec succès: $FullPath" -ForegroundColor Green
            } catch {
                Write-Host "Erreur lors de la création de l'OU '$($OU.Name)': $($_.Exception.Message)" -ForegroundColor Red
                exit 1
            }
        }
    }
    
    Write-Host "`n=== Vérification de la structure créée ===" -ForegroundColor Cyan
    
    # Vérifier la structure finale
    $FinalOU = "OU=International,OU=ATP,DC=atp,DC=local"
    try {
        $InternationalOU = Get-ADOrganizationalUnit -Identity $FinalOU -ErrorAction Stop
        Write-Host "✓ Structure de base prête: $FinalOU" -ForegroundColor Green
        Write-Host "  Description: $($InternationalOU.Description)" -ForegroundColor Gray
        Write-Host "  Créée le: $($InternationalOU.WhenCreated)" -ForegroundColor Gray
    } catch {
        Write-Host "✗ Erreur: La structure finale n'est pas accessible" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n=== Structure de base créée avec succès ===" -ForegroundColor Green
    Write-Host "Vous pouvez maintenant exécuter le script Create-InternationalUsers.ps1" -ForegroundColor Yellow
    
} catch {
    Write-Host "`nErreur fatale: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
