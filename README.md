# ATP International - Active Directory Structure Deployment

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Active Directory](https://img.shields.io/badge/Active%20Directory-Windows%20Server-green.svg)](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📋 Description

Ce projet automatise le deploiement d'une structure Active Directory internationale complete pour l'organisation ATP. Il permet de creer une hierarchie organisationnelle mondiale avec des unites d'organisation (OUs), des utilisateurs, des ordinateurs, des serveurs et des groupes repartis sur 6 continents et leurs principales villes.

## 🌍 Structure Mondiale Reduite

Le projet couvre une selection strategique de continents et villes :

- **Europe** : France (5 villes), Angleterre (2), Allemagne (2), Espagne (2), Italie (4), Pays-Bas (2), Belgique (2), Suisse (2)
- **Amerique du Nord** : USA (5 villes), Canada (2), Mexique (2)
- **Amerique du Sud** : Bresil (2), Argentine (2), Chili (2), Colombie (2), Perou (2)
- **Asie** : Chine (2), Japon (3), Inde (3), Coree du Sud (3), Singapour (1), Malaisie (2), Thailande (2), Vietnam (3)
- **Afrique** : Afrique du Sud (3), Nigeria (2), Egypte (1), Maroc (2), Kenya (2), Ghana (2)
- **Oceanie** : Australie (2), Nouvelle-Zelande (1), Papouasie-Nouvelle-Guinee (1), Fidji (1)

**Total** : 6 continents, 26 pays, 67 villes

## 🚀 Fonctionnalites

### ✅ Structure Organisationnelle

- Creation automatique de la hierarchie OU ATP → International → Continents → Pays → Villes
- 67 villes strategiquement selectionnees
- Sous-OUs standardisees : Utilisateurs, Ordinateurs, Serveurs, Groupes

### 👥 Gestion des Utilisateurs

- Generation automatique de **~4,000 utilisateurs** avec prenoms/noms francais realistes
- Repartition intelligente basee sur la taille des villes :
  - **Major** : 150 utilisateurs (capitales, metropoles)
  - **Large** : 50 utilisateurs (grandes villes)
  - **Medium** : 25 utilisateurs (villes moyennes)
  - **Small** : 15 utilisateurs (petites villes)
- Noms d'utilisateur uniques avec gestion des doublons
- Mot de passe par defaut : `Epsi@2025.`

### 💻 Ordinateurs et Serveurs

- **Ordinateurs** : ~1,500 machines (3 premieres villes par pays)
  - Major : 100, Large : 50, Medium : 25 ordinateurs
  - Types : PC, Laptop, Workstation
  - Departements : Finance, RH, IT, Marketing, Operations, Legal
- **Serveurs** : ~400 serveurs (2 premieres villes par pays)
  - Major : 15, Large : 8 serveurs
  - Roles : DC, FILE, PRINT, WEB, DB, APP, MAIL, DNS, DHCP, BACKUP

### 🔐 Groupes de Securite

- **~670 groupes** (10 groupes par ville)
- Types : Administrateurs, Utilisateurs, Finance, RH, IT, Marketing, Operations, Legal, Managers, Support
- Scopes appropries (Global, DomainLocal) selon les meilleures pratiques

## 📁 Structure du Projet

```
deploye-ad-atp-internationnal/
├── README.md                        # Ce fichier
├── Create-BaseOUStructure.ps1       # Creation structure OU de base
├── Create-UserStructure.ps1         # Creation des utilisateurs
├── Create-ComputersStructure.ps1    # Creation des ordinateurs
├── Create-ServersStructure.ps1      # Creation des serveurs
└── Create-GroupsStructure.ps1       # Creation des groupes
```

## 🔧 Prerequis

### Systeme

- **OS** : Windows Server 2016/2019/2022 ou Windows 10/11 avec RSAT
- **PowerShell** : Version 5.1 ou superieure
- **Module** : ActiveDirectory PowerShell Module

### Permissions

- Droits d'administration sur le domaine Active Directory
- Permissions de creation d'objets dans l'Active Directory
- Acces en ecriture aux OUs de destination

### Infrastructure

- Controleur de domaine accessible
- Domaine configure : `atp.local`
- Structure de base existante : `DC=atp,DC=local`

## 📦 Installation

### 1. Cloner le Repository

```powershell
git clone https://github.com/votre-organisation/deploye-ad-atp-internationnal.git
cd deploye-ad-atp-internationnal
```

### 2. Verifier les Prerequis

```powershell
# Verifier le module Active Directory
Get-Module -ListAvailable ActiveDirectory

# Installer si necessaire (Windows 10/11)
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

### 3. Configuration

Les scripts utilisent une configuration optimisee pour les tests :

```powershell
# Configuration automatique
$Configuration = @{
    Domain = "atp.local"
    BaseOU = "OU=International,OU=ATP,DC=atp,DC=local"
    DefaultPassword = "Epsi@2025."
    UsersPerCity = @{
        "Major"  = 150    # Grandes metropoles
        "Large"  = 50     # Grandes villes
        "Medium" = 25     # Villes moyennes
        "Small"  = 15     # Petites villes
    }
}
```

## 🚀 Deploiement

### Ordre d'Execution Recommande

#### 1. Structure de Base (Obligatoire en premier)

```powershell
.\Create-BaseOUStructure.ps1
```

**Resultat** : Creation de ~400 OUs (ATP + International + Continents + Pays + Villes + Sous-OUs)

#### 2. Utilisateurs

```powershell
.\Create-UserStructure.ps1
```

**Resultat** : Creation de ~4,000 utilisateurs repartis mondialement

#### 3. Ordinateurs

```powershell
.\Create-ComputersStructure.ps1
```

**Resultat** : Creation de ~1,500 ordinateurs (3 premieres villes par pays)

#### 4. Serveurs

```powershell
.\Create-ServersStructure.ps1
```

**Resultat** : Creation de ~400 serveurs (2 premieres villes par pays)

#### 5. Groupes

```powershell
.\Create-GroupsStructure.ps1
```

**Resultat** : Creation de ~670 groupes (10 groupes par ville)

### Execution Complete

```powershell
# Script de deploiement complet
$Scripts = @(
    "Create-BaseOUStructure.ps1",
    "Create-UserStructure.ps1",
    "Create-ComputersStructure.ps1",
    "Create-ServersStructure.ps1",
    "Create-GroupsStructure.ps1"
)

foreach ($Script in $Scripts) {
    Write-Information "Execution de $Script..." -InformationAction Continue
    & ".\$Script"
    Write-Information "$Script termine.`n" -InformationAction Continue
}
```

## 📊 Statistiques de Deploiement (Version Optimisee)

| Element          | Quantite Approximative | Description                                    |
| ---------------- | ---------------------- | ---------------------------------------------- |
| **OUs Total**    | ~400                   | Base + Continents + Pays + Villes + Sous-OUs   |
| **Utilisateurs** | ~4,000                 | Repartis selon la taille des villes            |
| **Ordinateurs**  | ~1,500                 | PC, Laptops, Workstations (3 villes/pays)      |
| **Serveurs**     | ~400                   | Serveurs specialises par role (2 villes/pays)  |
| **Groupes**      | ~670                   | 10 groupes par ville                           |
| **Continents**   | 6                      | Europe, Ameriques, Asie, Afrique, Oceanie      |
| **Pays**         | 26                     | Principales puissances economiques             |
| **Villes**       | 67                     | Metropoles et villes importantes selectionnees |

## ⚙️ Configuration Avancee

### Personnalisation des Quantites

```powershell
# Dans Create-UserStructure.ps1
$UsersPerCity = @{
    "Major"  = 200    # Augmenter pour plus d'utilisateurs
    "Large"  = 75     # Adapter selon vos besoins
    "Medium" = 40     # Configuration flexible
    "Small"  = 20     # Minimum recommande
}
```

### Ajout de Nouvelles Villes

```powershell
# Exemple d'ajout dans la WorldStructure
"Nouveau-Continent" = @{
    "Nouveau-Pays" = @("Ville1", "Ville2", "Ville3")
}
```

### Modification du Mot de Passe

```powershell
# Dans la configuration
DefaultPassword = "VotreMotDePasse@$(Get-Date -Format 'yyyy')"
```

## 🔍 Monitoring et Validation

### Verification Post-Deploiement

```powershell
# Compter les objets crees
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
# Verifier la structure par continent
foreach ($Continent in @("Europe", "Amerique-du-Nord", "Asie")) {
    $OU = "OU=$Continent,OU=International,OU=ATP,DC=atp,DC=local"
    $Count = (Get-ADUser -Filter * -SearchBase $OU).Count
    Write-Information "$Continent : $Count utilisateurs" -InformationAction Continue
}
```

## 🛠️ Ameliorations PSScriptAnalyzer

### Corrections Apportees (Version 2025.06.18)

- ✅ **Suppression des caracteres speciaux** dans tous les commentaires
- ✅ **Remplacement de Write-Host** par Write-Information avec -InformationAction Continue
- ✅ **Correction des blocs catch vides** avec gestion d'erreur appropriee
- ✅ **Suppression des espaces de fin de ligne**
- ✅ **Gestion securisee des mots de passe** avec ConvertTo-SecureString
- ✅ **Optimisation des performances** avec reduction du nombre de villes

### Problemes Restants a Corriger

- ⚠️ **Erreurs de parsing** dans Create-BaseOUStructure.ps1 (lignes 221, 228)
- ⚠️ **Blocs catch vides** dans certains scripts
- ⚠️ **Encodage BOM** manquant pour les fichiers Unicode

## 🔐 Securite

### Bonnes Pratiques

- Les mots de passe par defaut doivent etre changes apres le deploiement
- Utiliser des comptes de service dedies pour l'execution des scripts
- Audit et logging de toutes les creations d'objets
- Mise en place de politiques de groupe appropriees

### Nettoyage Post-Deploiement

```powershell
# Script de nettoyage (a utiliser avec precaution)
# Remove-ADOrganizationalUnit -Identity "OU=International,OU=ATP,DC=atp,DC=local" -Recursive -Confirm:$false
```

## 📈 Evolutivite

### Ajout de Nouvelles Regions

Le systeme est concu pour etre facilement extensible :

1. Ajouter de nouveaux continents/pays dans `WorldStructure`
2. Relancer `Create-BaseOUStructure.ps1`
3. Executer les autres scripts pour peupler les nouvelles structures

### Integration avec d'Autres Systemes

- Export CSV pour systemes RH
- Integration avec Azure AD Connect
- Synchronisation avec systemes de gestion d'identite

## 🤝 Contribution

### Comment Contribuer

1. Fork le projet
2. Creer une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit des changements (`git commit -am 'Ajout nouvelle fonctionnalite'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Creer une Pull Request

### Standards de Code

- Utiliser `Write-Information` au lieu de `Write-Host`
- Gestion d'erreur avec `try/catch` appropriee
- Commentaires sans accents pour la compatibilite
- Respect des conventions PowerShell et PSScriptAnalyzer

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de details.

## 📞 Support

### Contact

- **Auteur** : Thibaut Maurras
- **Version** : 2025.06.18
- **Email** : thibaut.maurras@exemple.com
- **GitHub** : [thibautmaurras](https://github.com/thibautmaurras)

### Documentation Supplementaire

- [Guide de Deploiement Detaille](docs/DEPLOYMENT-GUIDE.md)
- [Architecture du Projet](docs/ARCHITECTURE.md)
- [Guide de Resolution de Problemes](docs/TROUBLESHOOTING.md)

## 🏆 Remerciements

- Equipe Microsoft Active Directory pour la documentation
- Communaute PowerShell pour les bonnes pratiques
- Contributeurs du projet pour leurs ameliorations

---

**⚠️ Avertissement** : Ce projet est destine a des environnements de test et de developpement. Pour une utilisation en production, veuillez adapter les configurations selon vos politiques de securite et effectuer des tests approfondis.

**📅 Derniere mise a jour** : Decembre 2024
**🔖 Version** : 2025.06.18 (Version optimisee)

## 📋 Notes de Version 2025.06.18

### Nouveautes

- **Reduction strategique** du nombre de villes (67 au lieu de 500+)
- **Optimisation des quantites** d'objets pour les environnements de test
- **Amelioration des performances** de deploiement
- **Correction PSScriptAnalyzer** pour la majorite des avertissements

### Changements Techniques

- **Utilisateurs** : ~4,000 (au lieu de ~40,000)
- **Ordinateurs** : ~1,500 (limite aux 3 premieres villes par pays)
- **Serveurs** : ~400 (limite aux 2 premieres villes par pays)
- **Temps de deploiement** : Reduit de ~80%

### Configuration Actuelle

- **Major Cities** : 150 utilisateurs, 100 ordinateurs, 15 serveurs
- **Large Cities** : 50 utilisateurs, 50 ordinateurs, 8 serveurs
- **Medium Cities** : 25 utilisateurs, 25 ordinateurs
- **Small Cities** : 15 utilisateurs

Cette version optimisee est ideale pour :

- ✅ Tests et demonstrations
- ✅ Environnements de formation
- ✅ Validation de concepts
- ✅ Deploiements rapides
