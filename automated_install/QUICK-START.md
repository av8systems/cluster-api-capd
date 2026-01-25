# Cluster API - CAPD - Automated Install

## Installation Workflow

This guide uses a **two-step process**:
1. **Install PowerShell 7 and Docker Engine** in WSL (bash script)
2. **Run the main setup** from PowerShell (PowerShell script)

## Step-by-Step Installation

### Step 1: Install WSL

```powershell
# From PowerShell or Terminal
wsl --instal Ubuntu-22.04
```
You should now be in your Ubuntu bash shell.

### Step 2: Create and move into av8lab directory
```powershell
mkdir /mnt/c/av8lab -p
cd /mnt/c/av8lab
```

### Step 3: Clone repository

```powershell
git clone https://github.com/av8systems/cluster-api-capd.git
# Move to install directory
cd cluster-api-capd/automated_install/
```

### Step 4: Make install scripts executable

```bash
chmod +x install-prereqs.sh
chmod +x automated_install.ps1
```

### Step 5: Install PowerShell 7 and Docker Engine

```bash
./install-prereqs.sh
```



========================================
PowerShell 7 Installation for WSL
========================================

>>> Step 1: Updating package list
>>> Step 2: Installing prerequisites
>>> Step 3: Downloading Microsoft repository GPG keys
>>> Step 4: Registering Microsoft repository
>>> Step 5: Cleaning up repository file
>>> Step 6: Updating package list with Microsoft repository
>>> Step 7: Installing PowerShell
>>> Step 8: Verifying installation
✓ PowerShell installed successfully!

Installed version: PowerShell 7.4.x
```

### Step 4: Run Pre-flight Checks (Recommended)

```bash
# Make the script executable
chmod +x preflight-check.sh

# Run pre-flight checks
./preflight-check.sh
```

This script will:
- ✅ Verify WSL environment
- ✅ Check memory and disk space
- ✅ Verify PowerShell installation
- ✅ Check/configure Docker
- ✅ Test network connectivity
- ✅ Identify potential issues

**If Docker group was just added, you have 3 options:**

#### Option 1: Restart WSL (Recommended)
```bash
# Exit WSL
exit

# From Windows PowerShell:
wsl --shutdown
wsl -d Ubuntu-22.04
```

#### Option 2: Use newgrp (Temporary for current session)
```bash
# Apply docker group for current session
newgrp docker

# Now run the setup
pwsh ./Setup-K8sClusterAPI.ps1
```

#### Option 3: Continue anyway
The setup script will handle Docker with sudo if needed.

### Step 5: Verify PowerShell Installation

```bash
# Check PowerShell version
pwsh --version

# Should output: PowerShell 7.4.x (or similar)
```

### Step 6: Run the Kubernetes Setup

Now launch PowerShell and run the main setup script.

#### Basic Installation (Clusters Only)

```bash
# Run PowerShell with the setup script
pwsh ./Setup-K8sClusterAPI.ps1
```

This installs:
- ✅ Management cluster (Kind)
- ✅ Workload cluster (Cluster API)
- ✅ Calico CNI
- ✅ MetalLB load balancer
- ✅ Storage provisioner
- ✅ Metrics server
- ✅ Vertical Pod Autoscaler

**Estimated time:** 15-20 minutes

#### Full Installation (All Workloads)

```bash
# Install with all optional workloads
pwsh ./Setup-K8sClusterAPI.ps1 -InstallObservability -InstallSecurity -InstallAppManagement
```

Additional components:
- **Observability:** Istio, Kiali, Prometheus, Grafana, Jaeger, Loki
- **Security:** Falco, Kyverno, Vault, Trivy
- **App Management:** ArgoCD, Keda, Harbor

**Estimated time:** 40-50 minutes

#### Custom Installation Examples

```bash
# Larger cluster with observability
pwsh ./Setup-K8sClusterAPI.ps1 -WorkerNodeCount 3 -InstallObservability



### Step 8: Verify Installation

After the script completes:

```bash
# Switch to workload cluster context
kubectl config use-context d01av8test001-admin@d01av8test001

# Check nodes (should show Ready status)
kubectl get nodes

# Check all pods (should show Running status)
kubectl get pods -A

# Check MetalLB IP pool
kubectl get ipaddresspool -n metallb-system
```

Happy clustering! 🚀
