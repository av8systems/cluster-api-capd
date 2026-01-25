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



This installs:
- ✅ Management cluster (Kind)


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
