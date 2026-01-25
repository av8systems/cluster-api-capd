#!/bin/bash

###############################################################################
# PowerShell 7 Installation Script for WSL Ubuntu
#
# This script installs PowerShell 7 in your WSL Ubuntu distribution.
# After installation, you can run PowerShell scripts directly in WSL.
#
# Usage:
#   chmod +x install-powershell.sh
#   ./install-powershell.sh
#
# After installation, launch PowerShell with:
#   pwsh
#
# Author: Based on Microsoft PowerShell installation documentation
# License: Apache 2.0
###############################################################################

set -e  # Exit on error

# Color output functions
print_header() {
    echo -e "\e[32m========================================"
    echo -e "$1"
    echo -e "========================================\e[0m"
}

print_step() {
    echo -e "\e[36m>>> $1\e[0m"
}

print_success() {
    echo -e "\e[32m✓ $1\e[0m"
}

print_error() {
    echo -e "\e[31m✗ ERROR: $1\e[0m"
}

print_warning() {
    echo -e "\e[33m⚠ WARNING: $1\e[0m"
}

# Check if running in WSL
if ! grep -qi microsoft /proc/version; then
    print_error "This script is designed to run in WSL (Windows Subsystem for Linux)"
    exit 1
fi

print_header "PowerShell 7 and Docker Installation for WSL"
echo ""

echo ""
print_step "Step 1: Updating package list"
sudo apt-get update

echo ""
print_step "Step 2: Installing prerequisites"
sudo apt-get install -y wget apt-transport-https software-properties-common

echo ""
print_step "Step 3: Downloading Microsoft repository GPG keys"
# Get Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
wget -q "https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb"

echo ""
print_step "Step 4: Registering Microsoft repository"
sudo dpkg -i packages-microsoft-prod.deb

echo ""
print_step "Step 5: Cleaning up repository file"
rm packages-microsoft-prod.deb

echo ""
print_step "Step 6: Updating package list with Microsoft repository"
sudo apt-get update

echo ""
print_step "Step 7: Installing PowerShell"
sudo apt-get install -y powershell

echo ""
print_step "Step 8: Verifying installation"
if command -v pwsh &> /dev/null; then
    INSTALLED_VERSION=$(pwsh --version)
    print_success "PowerShell installed successfully!"
    echo ""
    echo "Installed version: $INSTALLED_VERSION"
else
    print_error "PowerShell installation failed"
    exit 1
fi

echo ""
print_header "Installation Complete!"
echo ""
echo -e "\e[36mNext Steps:\e[0m"
echo "1. Launch PowerShell:"
echo "   \e[37mpwsh\e[0m"
echo ""
echo "2. Run the setup PowerShell script:"
echo "   \e[37mpwsh ./Setup-K8sClusterAPI.ps1\e[0m"
echo ""
echo "3. Or run with options:"
echo "   \e[37mpwsh ./Setup-K8sClusterAPI.ps1 -InstallObservability -InstallSecurity\e[0m"
echo ""
echo -e "\e[36mUseful PowerShell Commands:\e[0m"
echo "  pwsh --version          - Check PowerShell version"
echo "  pwsh --help             - PowerShell help"
echo "  pwsh -Command 'command' - Run a single command"
echo "  pwsh -File script.ps1   - Run a PowerShell script"
echo ""

echo ""
print_header "Installing Docker engine"
echo ""
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
echo ""
print_header "IMPORTANT! Exit out of Wsl and re enter before continuing"
echo ""
newgrp docker
