# ATP International - Active Directory Structure Deployment

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Active Directory](https://img.shields.io/badge/Active%20Directory-Windows%20Server-green.svg)](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📋 Description

Ce projet automatise le déploiement d'une structure Active Directory internationale complète pour l'organisation ATP. Il permet de créer une hiérarchie organisationnelle mondiale avec des unités d'organisation (OUs), des utilisateurs, des ordinateurs, des serveurs et des groupes répartis sur 6 continents et leurs principales villes.

## 🌍 Structure Mondiale

Le projet couvre les continents suivants :

- **Europe** : France, Angleterre, Allemagne, Espagne, Italie, Pays-Bas, Belgique, Suisse
- **Amérique du Nord** : USA, Canada, Mexique
- **Amérique du Sud** : Brésil, Argentine, Chili, Colombie, Pérou
- **Asie** : Chine, Japon, Inde, Corée du Sud, Singapour, Malaisie, Thaïlande, Vietnam
- **Afrique** : Afrique du Sud, Nigeria, Égypte, Maroc, Kenya, Ghana
- **Océanie** : Australie, Nouvelle-Zélande, Papouasie-Nouvelle-Guinée, Fidji

## 🚀 Fonctionnalités

### ✅ Structure Organisationnelle

- Création automatique de la hiérarchie OU ATP → International → Continents → Pays → Villes
- Plus de 500 villes réparties sur 6 continents
- Sous-OUs standardisées : Utilisateurs, Ordinateurs, Serveurs, Groupes

### 👥 Gestion des Utilisateurs

- Génération automatique de **~40,000 utilisateurs** avec prénoms/noms français réalistes
- Répartition intelligente basée sur la taille des villes (Major: 500, Large: 200, Medium: 100, Small: 50)
- Noms d'utilisateur uniques avec gestion des doublons
- Attributs complets (DisplayName, UPN, Description, City)

### 💻 Ordinateurs et Serveurs

- Création d'ordinateurs par type (PC, Laptop, Workstation) et département
- Serveurs spécialisés par rôle (DC, FILE, PRINT, WEB, DB, APP, MAIL, DNS, DHCP, BACKUP)
- Nomenclature standardisée et noms NetBIOS compatibles

### 🔐 Groupes de Sécurité

- Groupes par département : Finance, RH, IT, Marketing, Operations, Legal
- Groupes administratifs : Administrateurs, Utilisateurs, Managers, Support
- Scopes appropriés (Global, DomainLocal) selon les meilleures pratiques

## 📁 Structure du Projet

```
deploye-ad-atp-internationnal/
├── README.md                        # Ce fichier
├── Create-BaseOUStructure.ps1       # Création structure OU de base
├── Create-UserStructure.ps1         # Création des utilisateurs
├── Create-ComputersStructure.ps1    # Création des ordinateurs
├── Create-ServersStructure.ps1      # Création des serveurs
├── Create-GroupsStructure.ps1       # Création des groupes
└── docs/
    ├── DEPLOYMENT-GUIDE.md          # Guide de déploiement détaillé
    ├── ARCHITECTURE.md              # Documentation architecture
    └── TROUBLESHOOTING.md           # Guide de résolution de problèmes
```

## 🔧 Prérequis

### Système

- **OS** : Windows Server 2016/2019/2022 ou Windows 10/11 avec RSAT
- **PowerShell** : Version 5.1 ou supérieure
- **Module** : ActiveDirectory PowerShell Module

### Permissions

- Droits d'administration sur le domaine Active Directory
- Permissions de création d'objets dans l'Active Directory
- Accès en écriture aux OUs de destination

### Infrastructure

- Contrôleur de domaine accessible
- Domaine configuré : `atp.local`
- Structure de base existante : `DC=atp,DC=local`

## 📦 Installation

### 1. Cloner le Repository

```powershell
git clone https://github.com/votre-organisation/deploye-ad-atp-internationnal.git
cd deploye-ad-atp-internationnal
```

### 2. Vérifier les Prérequis

```powershell
# Vérifier le module Active Directory
Get-Module -ListAvailable ActiveDirectory

# Installer si nécessaire (Windows 10/11)
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

### 3. Configuration

Modifier les paramètres dans chaque script selon votre environnement :

```powershell
# Exemple de configuration
$Configuration = @{
    Domain = "votre-domaine.local"
    BaseOU = "OU=International,OU=ATP,DC=votre-domaine,DC=local"
    DefaultPassword = "VotreMotDePasse@2025"
}
```

## 🚀 Déploiement

### Ordre d'Exécution Recommandé

#### 1. Structure de Base (Obligatoire en premier)

```powershell
.\Create-BaseOUStructure.ps1
```

**Résultat** : Création de ~3,000 OUs (ATP + International + Continents + Pays + Villes + Sous-OUs)

#### 2. Utilisateurs

```powershell
.\Create-UserStructure.ps1
```

**Résultat** : Création de ~40,000 utilisateurs répartis mondialement

#### 3. Ordinateurs

```powershell
.\Create-ComputersStructure.ps1
```

**Résultat** : Création de ~3,000 ordinateurs (3 premiers villes par pays)

#### 4. Serveurs

```powershell
.\Create-ServersStructure.ps1
```

**Résultat** : Création de ~600 serveurs (2 premières villes par pays)

#### 5. Groupes

```powershell
.\Create-GroupsStructure.ps1
```

**Résultat** : Création de ~5,000 groupes (10 groupes par ville)

### Exécution Complète

```powershell
# Script de déploiement complet
$Scripts = @(
    "Create-BaseOUStructure.ps1",
    "Create-UserStructure.ps1",
    "Create-ComputersStructure.ps1",
    "Create-ServersStructure.ps1",
    "Create-GroupsStructure.ps1"
)

foreach ($Script in $Scripts) {
    Write-Host "Exécution de $Script..." -ForegroundColor Green
    & ".\$Script"
    Write-Host "$Script terminé.`n" -ForegroundColor Green
}
```

## 📊 Statistiques de Déploiement

| Élément          | Quantité Approximative | Description                                  |
| ---------------- | ---------------------- | -------------------------------------------- |
| **OUs Total**    | ~3,000                 | Base + Continents + Pays + Villes + Sous-OUs |
| **Utilisateurs** | ~40,000                | Répartis selon la taille des villes          |
| **Ordinateurs**  | ~3,000                 | PC, Laptops, Workstations                    |
| **Serveurs**     | ~600                   | Serveurs spécialisés par rôle                |
| **Groupes**      | ~5,000                 | 10 groupes par ville                         |
| **Continents**   | 6                      | Europe, Amériques, Asie, Afrique, Océanie    |
| **Pays**         | 26                     | Principales puissances économiques           |
| **Villes**       | ~500                   | Métropoles et villes importantes             |

## ⚙️ Configuration Avancée

### Personnalisation des Quantités

```powershell
# Dans Create-UserStructure.ps1
$UsersPerCity = @{
    "Major"  = 1000    # Grandes métropoles
    "Large"  = 500     # Grandes villes
    "Medium" = 250     # Villes moyennes
    "Small"  = 100     # Petites villes
}
```

### Ajout de Nouveaux Pays/Villes

```powershell
# Exemple d'ajout dans la WorldStructure
"Nouveau-Continent" = @{
    "Nouveau-Pays" = @("Ville1", "Ville2", "Ville3")
}
```

### Personnalisation des Mots de Passe

```powershell
# Politique de mot de passe personnalisée
$DefaultPassword = "VotreMotDePasse@$(Get-Date -Format 'yyyy')"
```

## 🔍 Monitoring et Validation

### Vérification Post-Déploiement

```powershell
# Compter les objets créés
$Stats = @{
    OUs = (Get-ADOrganizationalUnit -Filter * -SearchBase "OU=International,OU=ATP,DC=atp,DC=local").Count
    Users = (Get-ADUser -Filter * -SearchBase "OU=International,OU=ATP,DC=atp,DC=local").Count
    Computers = (Get-ADComputer -Filter * -SearchBase "OU=International,OU=ATP,DC=atp,DC=local").Count
    Groups = (Get-ADGroup -Filter * -SearchBase "OU=International,OU=ATP,DC=atp,DC=local").Count
}

$Stats | Format-Table -AutoSize
```

### Scripts de Validation

```powershell
# Vérifier la structure par continent
foreach ($Continent in @("Europe", "Amerique-du-Nord", "Asie")) {
    $OU = "OU=$Continent,OU=International,OU=ATP,DC=atp,DC=local"
    $Count = (Get-ADUser -Filter * -SearchBase $OU).Count
    Write-Host "$Continent : $Count utilisateurs" -ForegroundColor Cyan
}
```

## 🛠️ Résolution de Problèmes

### Problèmes Courants

#### Erreur de Permissions

```powershell
# Vérifier les permissions actuelles
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
Write-Host "Utilisateur actuel : $($CurrentUser.Name)"

# Test de connexion au domaine
try {
    Get-ADDomain -ErrorAction Stop
    Write-Host "✅ Connexion au domaine réussie" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur de connexion au domaine" -ForegroundColor Red
}
```

#### Gestion des Doublons

```powershell
# Rechercher les doublons d'utilisateurs
$AllUsers = Get-ADUser -Filter * -SearchBase "OU=International,OU=ATP,DC=atp,DC=local"
$Duplicates = $AllUsers | Group-Object SamAccountName | Where-Object {$_.Count -gt 1}

if ($Duplicates) {
    Write-Warning "Doublons détectés : $($Duplicates.Count)"
    $Duplicates | Select-Object Name, Count
}
```

#### Performance et Optimisation

```powershell
# Exécution en mode batch pour de meilleures performances
$BatchSize = 100
$Users = 1..1000

for ($i = 0; $i -lt $Users.Count; $i += $BatchSize) {
    $Batch = $Users[$i..([Math]::Min($i + $BatchSize - 1, $Users.Count - 1))]
    # Traitement du batch
    Write-Progress -Activity "Création utilisateurs" -PercentComplete (($i / $Users.Count) * 100)
}
```

## 🔐 Sécurité

### Bonnes Pratiques

- Les mots de passe par défaut doivent être changés après le déploiement
- Utiliser des comptes de service dédiés pour l'exécution des scripts
- Audit et logging de toutes les créations d'objets
- Mise en place de politiques de groupe appropriées

### Nettoyage Post-Déploiement

```powershell
# Script de nettoyage (à utiliser avec précaution)
# Remove-ADOrganizationalUnit -Identity "OU=International,OU=ATP,DC=atp,DC=local" -Recursive -Confirm:$false
```

## 📈 Évolutivité

### Ajout de Nouvelles Régions

Le système est conçu pour être facilement extensible :

1. Ajouter de nouveaux continents/pays dans `WorldStructure`
2. Relancer `Create-BaseOUStructure.ps1`
3. Exécuter les autres scripts pour peupler les nouvelles structures

### Intégration avec d'Autres Systèmes

- Export CSV pour systèmes RH
- Intégration avec Azure AD Connect
- Synchronisation avec systèmes de gestion d'identité

## 🤝 Contribution

### Comment Contribuer

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit des changements (`git commit -am 'Ajout nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Créer une Pull Request

### Standards de Code

- Utiliser `Write-Information` au lieu de `Write-Host`
- Gestion d'erreur avec `try/catch` appropriée
- Commentaires en français pour la documentation
- Respect des conventions PowerShell

## 📄 Licence

Ce projet est sous licence Apache 2.0 - voir le fichier [LICENSE](LICENSE) pour plus de détails.


## 🏆 Remerciements

- Équipe Microsoft Active Directory pour la documentation
- Communauté PowerShell pour les bonnes pratiques
- Contributeurs du projet pour leurs améliorations

---

**⚠️ Avertissement** : Ce projet est destiné à des environnements de test et de développement. Pour une utilisation en production, veuillez adapter les configurations selon vos politiques de sécurité et effectuer des tests approfondis.

**📅 Dernière mise à jour** : 18/06/2025  
**🔖 Version** : 2025.06.18
