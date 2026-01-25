# Cluster API - CAPD - Automated Install

## Installation Workflow

This guide uses a **two-step process**:
1. **Install PowerShell 7 and Docker Engine** in WSL (bash script)
2. **Run Automated Install** from PowerShell (PowerShell script)

## Step-by-Step Installation

### Step 1: Install WSL

```powershell
# From PowerShell or Terminal
wsl --instal Ubuntu-22.04
```
You should now be in your Ubuntu bash shell.

### Step 2: Create and move into av8lab directory
```bash
mkdir /mnt/c/av8lab -p
cd /mnt/c/av8lab
```

### Step 3: Clone repository

```bash
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

### Step 6: Exit out of WSl and re-enter 

```bash
wsl --shutdown
wsl -d Ubuntu-22.04
```

### Step 7: Open PowerShell from Wsl

```bash
pwsh
```

### Step 7: Run the automated install script

Pick an install type

```powershell
# Install with no optional workloads
./automated_install.ps1
```

```powershell
# Install with all optional workloads
./automated_install.ps1 -InstallObservability -InstallSecurity -InstallAppManagement
```

```powershell
# Install with observability workloads
# Istio, Kiali, Prometheus, Grafana, Jaeger, Loki
./automated_install.ps1 -InstallObservability
```

```powershell
# Install with security workloads
**Security:** Falco, Kyverno, Vault, Trivy
./automated_install.ps1 -InstallSecurity 
```

```powershell
# Install with appplication management workloads
./automated_install.ps1 -InstallAppManagement
```

This installs:
- ✅ Management cluster (Kind)


#### Full Installation (All Workloads)


Additional components:
- **Observability:** Istio, Kiali, Prometheus, Grafana, Jaeger, Loki
- 
- **App Management:** ArgoCD, Keda, Harbor


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
