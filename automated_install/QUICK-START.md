# Quick Start Guide - WSL Kubernetes Cluster Setup

## Installation Workflow

This guide uses a **two-step process**:
1. **Install PowerShell 7** in WSL (bash script)
2. **Run the main setup** from PowerShell (PowerShell script)

## Step-by-Step Installation

### Step 1: Enter WSL

```powershell
# From Windows PowerShell or Terminal
wsl -d Ubuntu-22.04
```
You should now be in your Ubuntu bash shell.

### Step 2: Clone Repository

Copy the following files to your WSL home directory:
- `install-powershell.sh`
- `preflight-check.sh`
- `Setup-K8sClusterAPI.ps1`
- `Cleanup-K8sClusterAPI.ps1`

```bash
# Example: If files are in Windows downloads folder
cp /mnt/c/Users/YourUsername/Downloads/*.sh ~/
cp /mnt/c/Users/YourUsername/Downloads/*.ps1 ~/

# Or create a dedicated directory
mkdir -p ~/k8s-setup
cd ~/k8s-setup
# Copy files here
```

### Step 3: Install PowerShell 7

```bash
# Make the script executable
chmod +x install-powershell.sh

# Run the installation script
./install-powershell.sh
```

**Expected output:**
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

# Custom cluster names
pwsh ./Setup-K8sClusterAPI.ps1 -ManagementClusterName "prod-mgmt" -WorkloadClusterName "prod-cluster-01"

# Security-focused setup
pwsh ./Setup-K8sClusterAPI.ps1 -InstallSecurity -WorkloadClusterName "sec-cluster"
```

### Step 7: Wait for Installation

The script will display progress for each step. **Do not close the terminal** during installation.

You'll see output like:
```
========================================
Step 1: Creating Directory Structure
========================================
>>> Creating directory structure
Executing: mkdir -p /mnt/c/av8systems/cluster-api/...

========================================
Step 2: Installing Prerequisites
========================================
...
```

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

**Expected node output:**
```
NAME                             STATUS   ROLES           AGE   VERSION
d01av8test001-control-plane-xxx  Ready    control-plane   10m   v1.32.0
d01av8test001-worker-xxx         Ready    <none>          9m    v1.32.0
d01av8test001-worker-yyy         Ready    <none>          9m    v1.32.0
```

---

## Common Installation Options

### All Available Parameters

```bash
pwsh ./Setup-K8sClusterAPI.ps1 -Help
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-DistroName` | String | Ubuntu-22.04 | WSL distribution name |
| `-ManagementClusterName` | String | d01capimgmt001 | Management cluster name |
| `-WorkloadClusterName` | String | d01av8test001 | Workload cluster name |
| `-ControlPlaneCount` | Integer | 1 | Control plane node count |
| `-WorkerNodeCount` | Integer | 2 | Worker node count |
| `-InstallObservability` | Switch | false | Install observability stack |
| `-InstallSecurity` | Switch | false | Install security stack |
| `-InstallAppManagement` | Switch | false | Install app management stack |

---

## Post-Installation

### Accessing Your Clusters

```bash
# List all contexts
kubectl config get-contexts

# Switch to management cluster
kubectl config use-context kind-d01capimgmt001

# Switch to workload cluster
kubectl config use-context d01av8test001-admin@d01av8test001
```

### File Locations

**Configuration files:**
- `C:\av8systems\cluster-api\` - Main directory
- `C:\av8systems\cluster-api\providers\capd\clusters\workload\<cluster-name>\configs\` - Kubeconfigs

**In WSL:**
- `/mnt/c/av8systems/cluster-api/` - Same as above
- `~/.kube/config` - Merged kubeconfig

### Testing the Cluster

```bash
# Deploy a test application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=LoadBalancer --port=80

# Get the external IP (from MetalLB)
kubectl get svc nginx

# Test the service
curl http://<EXTERNAL-IP>
```

### Accessing Web UIs (If Installed)

#### ArgoCD (App Management)
```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access at: https://localhost:8080
# Username: admin
# Password: (from above command)
```

#### Kiali (Service Mesh - Observability)
```bash
kubectl port-forward svc/kiali -n istio-system 20001:20001

# Access at: http://localhost:20001
```

#### Grafana (Monitoring - Observability)
```bash
kubectl port-forward svc/grafana -n istio-system 3000:3000

# Access at: http://localhost:3000
```

#### Falco UI (Security)
```bash
kubectl port-forward svc/falco-falcosidekick-ui -n falco 2802:2802

# Access at: http://localhost:2802
```

---

## Troubleshooting

### PowerShell Installation Failed

```bash
# Check Ubuntu version
lsb_release -a

# Manually install
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
```

### DNS Issues in WSL

```bash
# Check DNS
cat /etc/resolv.conf

# If incorrect, restart WSL from Windows PowerShell:
wsl --shutdown
wsl
```

### Docker Not Starting

```bash
# Check Docker status
sudo service docker status

# Restart Docker
sudo service docker restart

# Verify you're in docker group
groups | grep docker
```

### Pods Not Becoming Ready

```bash
# Check pod details
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check Calico (CNI) status
kubectl get pods -n kube-system -l k8s-app=calico-node
```

### Cluster Creation Stuck

```bash
# Switch to management cluster
kubectl config use-context kind-d01capimgmt001

# Check cluster status
kubectl get cluster
kubectl get machine
kubectl get machinedeployment

# View events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

---

## Cleanup / Destruction

### Complete Cleanup

```bash
# Run the cleanup script
pwsh ./Cleanup-K8sClusterAPI.ps1

# With directories
pwsh ./Cleanup-K8sClusterAPI.ps1 -RemoveDirectories

# Complete removal (including WSL)
pwsh ./Cleanup-K8sClusterAPI.ps1 -RemoveDirectories -UnregisterWSL -Force
```

### Manual Cleanup

```bash
# Switch to management cluster
kubectl config use-context kind-d01capimgmt001

# Delete workload cluster
kubectl delete cluster d01av8test001

# Delete management cluster
kind delete cluster --name d01capimgmt001

# Remove directories
rm -rf /mnt/c/av8systems
```

## Summary

**Installation Steps:**
1. ✅ Enter WSL
2. ✅ Run `install-powershell.sh`
5. ✅ Run `pwsh ./Setup-K8sClusterAPI.ps1`


Happy clustering! 🚀
