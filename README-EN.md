# ATP International - Active Directory Structure Deployment

<div align="center">

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Active Directory](https://img.shields.io/badge/Active%20Directory-Windows%20Server-green.svg)](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**🌐 English | [Version Française](README.md)**

</div>

## 📋 Description

This project automates the deployment of a complete international Active Directory structure for the ATP organization. It creates a global organizational hierarchy with Organizational Units (OUs), users, computers, servers, and groups distributed across 6 continents and their major cities.

## 🌍 Optimized Global Structure

The project covers a strategic selection of continents and cities:

- **Europe**: France (5 cities), England (2), Germany (2), Spain (2), Italy (4), Netherlands (2), Belgium (2), Switzerland (2)
- **North America**: USA (5 cities), Canada (2), Mexico (2)
- **South America**: Brazil (2), Argentina (2), Chile (2), Colombia (2), Peru (2)
- **Asia**: China (2), Japan (3), India (3), South Korea (3), Singapore (1), Malaysia (2), Thailand (2), Vietnam (3)
- **Africa**: South Africa (3), Nigeria (2), Egypt (1), Morocco (2), Kenya (2), Ghana (2)
- **Oceania**: Australia (2), New Zealand (1), Papua New Guinea (1), Fiji (1)

**Total**: 6 continents, 26 countries, 67 cities

## 🚀 Features

### ✅ Organizational Structure

- Automatic creation of OU hierarchy: ATP → International → Continents → Countries → Cities
- 67 strategically selected cities
- Standardized sub-OUs: Users, Computers, Servers, Groups

### 👥 User Management

- Automatic generation of **~1,700 users** with realistic French first/last names
- Intelligent distribution based on city size:
  - **Major**: 50 users (capitals, metropolises)
  - **Large**: 20 users (large cities)
  - **Medium**: 10 users (medium cities)
  - **Small**: 5 users (small cities)
- Unique usernames with duplicate handling
- Default password: `Epsi@2025.`

### 💻 Computers and Servers

- **Computers**: ~1,500 machines (first 3 cities per country)
  - Major: 100, Large: 50, Medium: 25 computers
  - Types: PC, Laptop, Workstation
  - Departments: Finance, HR, IT, Marketing, Operations, Legal
- **Servers**: ~400 servers (first 2 cities per country)
  - Major: 15, Large: 8 servers
  - Roles: DC, FILE, PRINT, WEB, DB, APP, MAIL, DNS, DHCP, BACKUP

### 🔐 Security Groups

- **~670 groups** (10 groups per city)
- Types: Administrators, Users, Finance, HR, IT, Marketing, Operations, Legal, Managers, Support
- Appropriate scopes (Global, DomainLocal) according to best practices

## 📁 Project Structure

```
deploye-ad-atp-internationnal/
├── README.md                        # French documentation
├── README-EN.md                     # English documentation
├── Create-BaseOUStructure.ps1       # Base OU structure creation
├── Create-UserStructure.ps1         # User creation
├── Create-ComputersStructure.ps1    # Computer creation
├── Create-ServersStructure.ps1      # Server creation
└── Create-GroupsStructure.ps1       # Group creation
```

## 🔧 Prerequisites

### System

- **OS**: Windows Server 2016/2019/2022 or Windows 10/11 with RSAT
- **PowerShell**: Version 5.1 or higher
- **Module**: ActiveDirectory PowerShell Module

### Permissions

- Domain administration rights on Active Directory
- Object creation permissions in Active Directory
- Write access to destination OUs

### Infrastructure

- Accessible domain controller
- Configured domain: `atp.local`
- Existing base structure: `DC=atp,DC=local`

## 📦 Installation

### 1. Clone the Repository

```powershell
git clone https://github.com/MyMsprEPSI/deploye-ad-atp-internationnal.git
cd deploye-ad-atp-internationnal
```

### 2. Verify Prerequisites

```powershell
# Check Active Directory module
Get-Module -ListAvailable ActiveDirectory

# Install if necessary (Windows 10/11)
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

### 3. Configuration

Scripts use optimized configuration for testing:

```powershell
# Automatic configuration
$Configuration = @{
    Domain = "atp.local"
    BaseOU = "OU=International,OU=ATP,DC=atp,DC=local"
    DefaultPassword = "Epsi@2025."
    UsersPerCity = @{
        "Major"  = 50     # Major metropolises
        "Large"  = 20     # Large cities
        "Medium" = 10     # Medium cities
        "Small"  = 5      # Small cities
    }
}
```

## 🚀 Deployment

### Recommended Execution Order

#### 1. Base Structure (Required first)

```powershell
.\Create-BaseOUStructure.ps1
```

**Result**: Creation of ~400 OUs

#### 2. Users

```powershell
.\Create-UserStructure.ps1
```

**Result**: Creation of ~1,700 users

#### 3. Computers

```powershell
.\Create-ComputersStructure.ps1
```

**Result**: Creation of ~1,500 computers

#### 4. Servers

```powershell
.\Create-ServersStructure.ps1
```

**Result**: Creation of ~400 servers

#### 5. Groups

```powershell
.\Create-GroupsStructure.ps1
```

**Result**: Creation of ~670 groups

### Complete Execution

```powershell
# Complete deployment script
$Scripts = @(
    "Create-BaseOUStructure.ps1",
    "Create-UserStructure.ps1",
    "Create-ComputersStructure.ps1",
    "Create-ServersStructure.ps1",
    "Create-GroupsStructure.ps1"
)

foreach ($Script in $Scripts) {
    Write-Information "Executing $Script..." -InformationAction Continue
    & ".\$Script"
    Write-Information "$Script completed.`n" -InformationAction Continue
}
```

## 📊 Deployment Statistics

| Element        | Quantity | Description                                      |
| -------------- | -------- | ------------------------------------------------ |
| **Total OUs**  | ~400     | Base + Continents + Countries + Cities + Sub-OUs |
| **Users**      | ~1,700   | Distributed according to city size               |
| **Computers**  | ~1,500   | PCs, Laptops, Workstations (3 cities/country)    |
| **Servers**    | ~400     | Specialized servers by role (2 cities/country)   |
| **Groups**     | ~670     | 10 groups per city                               |
| **Continents** | 6        | Europe, Americas, Asia, Africa, Oceania          |
| **Countries**  | 26       | Major economic powers                            |
| **Cities**     | 67       | Important metropolises and cities                |

## 🔍 Monitoring and Validation

### Post-Deployment Verification

```powershell
# Count created objects
$Stats = @{
    OUs = (Get-ADOrganizationalUnit -Filter * -SearchBase "OU=International,OU=ATP,DC=atp,DC=local").Count
    Users = (Get-ADUser -Filter * -SearchBase "OU=International,OU=ATP,DC=atp,DC=local").Count
    Computers = (Get-ADComputer -Filter * -SearchBase "OU=International,OU=ATP,DC=atp,DC=local").Count
    Groups = (Get-ADGroup -Filter * -SearchBase "OU=International,OU=ATP,DC=atp,DC=local").Count
}

$Stats | Format-Table -AutoSize
```

### Validation Scripts

```powershell
# Verify structure by continent
foreach ($Continent in @("Europe", "Amerique-du-Nord", "Asie")) {
    $OU = "OU=$Continent,OU=International,OU=ATP,DC=atp,DC=local"
    $Count = (Get-ADUser -Filter * -SearchBase $OU).Count
    Write-Information "$Continent: $Count users" -InformationAction Continue
}
```

## 🛠️ PSScriptAnalyzer Improvements

### Version 2025.06.18 Enhancements

- ✅ **Removed special characters** from all comments
- ✅ **Replaced Write-Host** with Write-Information
- ✅ **Fixed empty catch blocks** with proper error handling
- ✅ **Removed trailing whitespace**
- ✅ **Secure password handling**
- ✅ **Performance optimization**

## 🔐 Security

### Best Practices

- Default passwords should be changed after deployment
- Use dedicated service accounts for script execution
- Audit and log all object creations
- Implement appropriate Group Policy settings

### Post-Deployment Cleanup

```powershell
# Cleanup script (use with caution)
# Remove-ADOrganizationalUnit -Identity "OU=International,OU=ATP,DC=atp,DC=local" -Recursive -Confirm:$false
```

## 🔧 Advanced Configuration

### Customizing Quantities

```powershell
# In Create-UserStructure.ps1
$UsersPerCity = @{
    "Major"  = 100    # Increase for more users
    "Large"  = 50     # Adapt to your needs
    "Medium" = 25     # Flexible configuration
    "Small"  = 10     # Recommended minimum
}
```

### Adding New Cities

```powershell
# Example addition to WorldStructure
"New-Continent" = @{
    "New-Country" = @("City1", "City2", "City3")
}
```

## 🤝 Contribution

### How to Contribute

1. Fork the project
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create a Pull Request

### Code Standards

- Use `Write-Information` instead of `Write-Host`
- Proper error handling with `try/catch`
- Comments without accents for compatibility
- Follow PowerShell and PSScriptAnalyzer conventions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

### Contact

- **Author**: Thibaut Maurras
- **Version**: 2025.06.18
- **Repository**: [GitHub - ATP AD Deployment](https://github.com/MyMsprEPSI/deploye-ad-atp-internationnal)

### Documentation

- 🇬🇧 [English Documentation](README-EN.md) (this file)
- 🇫🇷 [Documentation Française](README.md)

### Troubleshooting

#### Common Issues

- **Permission Errors**: Ensure proper AD domain admin rights
- **Module Not Found**: Install RSAT Active Directory tools
- **Connection Issues**: Verify domain controller accessibility
- **Duplicate Objects**: Scripts handle existing objects gracefully

#### Performance Tips

- Run scripts during off-peak hours
- Monitor domain controller resources
- Use batch processing for large deployments
- Consider incremental deployment for production

---

**⚠️ Warning**: This project is intended for test and development environments. For production use, please adapt configurations according to your security policies and perform thorough testing.