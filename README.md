# psSearchGitHub

PowerShell Tools for Searching GitHub

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-orange)
![License](https://img.shields.io/badge/license-MIT-green)

A PowerShell module for searching GitHub repositories and gists using the GitHub CLI. Search for code, files, and content across your repositories and gists with PowerShell-style cmdlets.

## 🎯 Overview

This module provides PowerShell cmdlets to search GitHub repositories and gists for specific content. It leverages the GitHub CLI (gh) to perform searches and returns results in a PowerShell-friendly format, making it easy to integrate GitHub searches into your automation workflows.

## ✨ Features

- 🔍 **Repository Search** - Search code across GitHub repositories
- 📝 **Gist Search** - Search through your gists and their content
- 🎯 **Content Matching** - Find specific text patterns in code and files
- 📊 **Flexible Output** - Get detailed results or summary views
- 🔐 **Owner Filtering** - Limit searches to specific repository owners
- ⚡ **GitHub CLI Integration** - Leverages the power of the GitHub CLI

## Requirements

- PowerShell 5.1 or higher
- GitHub CLI (gh) installed and authenticated
- Appropriate GitHub permissions for the resources being searched

## Installation

### Prerequisites

First, install and authenticate GitHub CLI:

```bash
# Install GitHub CLI (if not already installed)
# Windows (winget)
winget install --id GitHub.cli

# macOS
brew install gh

# Linux (Debian/Ubuntu)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Authenticate with GitHub
gh auth login
```

### From PowerShell Gallery (When Available)

```powershell
Install-Module -Name psSearchGitHub -Scope CurrentUser
```

### From GitHub

1. **Clone the repository**
   ```bash
   git clone https://github.com/Skatterbrainz/psSearchGitHub.git
   cd psSearchGitHub
   ```

2. **Import the module**
   ```powershell
   Import-Module ./psSearchGitHub.psd1
   ```

## Usage

Import the module and start searching:

```powershell
# Import the module
Import-Module psSearchGitHub

# Get all available cmdlets
Get-Command -Module psSearchGitHub

# Get help for a specific cmdlet
Get-Help Search-GitHub -Full

# Example: Search repositories for PowerShell content
Search-GitHub -Target Repo -SearchValue "Invoke-WebRequest"

# Example: Search gists with content included
Search-GitHub -Target Gist -SearchValue "function" -IncludeContent -Limit 50

# Example: Search with summary view
Search-GitHub -Target Repo -SearchValue "PowerShell" -Summary
```

## 📖 Available Cmdlets

### Search-GitHub

Search GitHub repositories or gists for specified content.

**Parameters:**
- `-Target` - Specifies whether to search 'Gist' or 'Repo' (required)
- `-SearchValue` - The text pattern to search for (required)
- `-IncludeContent` - Include matching content in results (gist searches only)
- `-Limit` - Maximum number of results to return (default: 100)
- `-Summary` - Display summary view of results (repo searches)

**Examples:**

```powershell
# Search gists for "Invoke-WebRequest" and include content
Search-GitHub -Target Gist -SearchValue "Invoke-WebRequest" -IncludeContent -Limit 50

# Search repositories for "PowerShell"
Search-GitHub -Target Repo -SearchValue "PowerShell"

# Get summary of repository matches
Search-GitHub -Target Repo -SearchValue "function" -Summary
```

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features or cmdlets
- Improve documentation
- Add support for additional GitHub search capabilities
- Submit pull requests

Please open an [issue](https://github.com/Skatterbrainz/psSearchGitHub/issues) or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Skatterbrainz**
- GitHub: [@Skatterbrainz](https://github.com/Skatterbrainz)

## Acknowledgments

- Built for PowerShell 5.1+ on all platforms
- Powered by the GitHub CLI
- Thanks to all contributors and users who have provided feedback and suggestions

---

## 📋 Version History

### 1.0.0 - 1/2/2026
- Initial release
- Added: Search-GitHub cmdlet for searching repositories and gists
