<#
.SYNOPSIS
    Automates the setup of Kubernetes clusters using Cluster API on WSL with Docker provider (CAPD)

.DESCRIPTION
    This script is designed to run INSIDE WSL using PowerShell 7 (pwsh).
    
    It automates the installation and configuration of:
    - Directory structure
    - Required command line tools (kubectl, kind, clusterctl, helm, etc.)
    - Linux host configuration
    - Management cluster (Kind)
    - Workload cluster (Cluster API)
    - Optional workloads (Istio, ArgoCD, Vault, Falco, Kyverno, etc.)

.PARAMETER ManagementClusterName
    The name for the management cluster (default: d01capimgmt001)

.PARAMETER WorkloadClusterName
    The name for the workload cluster (default: d01av8test001)

.PARAMETER ControlPlaneCount
    Number of control plane nodes for workload cluster (default: 1)

.PARAMETER WorkerNodeCount
    Number of worker nodes for workload cluster (default: 2)

.PARAMETER InstallObservability
    Install observability workloads (Istio, Kiali, Prometheus, Grafana, Jaeger, Loki)

.PARAMETER InstallSecurity
    Install security workloads (Falco, Kyverno, Vault, Trivy)

.PARAMETER InstallAppManagement
    Install application management workloads (ArgoCD, Keda, Harbor)

.EXAMPLE
    pwsh ./Setup-K8sCluster-WSL.ps1
    Runs basic installation with management and workload clusters only

.EXAMPLE
    pwsh ./Setup-K8sCluster-WSL.ps1 -InstallObservability -InstallSecurity
    Installs clusters plus observability and security workloads

.NOTES
    Author: Based on manual_install.txt guide
    Prerequisites: Must be run from inside WSL with PowerShell 7 installed
    License: Apache 2.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ManagementClusterName = "d01capimgmt001",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkloadClusterName = "d01av8test001",
   
    [Parameter(Mandatory=$false)]
    [string]$ipRange = "172.18.255.200-172.18.255.250",

    [Parameter(Mandatory=$false)]
    [int]$ControlPlaneCount = 1,
    
    [Parameter(Mandatory=$false)]
    [int]$WorkerNodeCount = 2,
    
    [Parameter(Mandatory=$false)]
    [switch]$InstallObservability,
    
    [Parameter(Mandatory=$false)]
    [switch]$InstallSecurity,
    
    [Parameter(Mandatory=$false)]
    [switch]$InstallAppManagement
)

# Verify we're running in Linux OS
if (!($IsLinux)) {
    Write-Host "ERROR: This script must be run on a Linux OS" -ForegroundColor Red
    exit 1
}

# Create variables
$tmpDir = '/mnt/c/av8systems/cluster-api/tmp'

# Display banner
Write-Host "========================================" -ForegroundColor Green
Write-Host "Kubernetes Cluster API Setup Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Management Cluster: $ManagementClusterName" -ForegroundColor White
Write-Host "  Workload Cluster: $WorkloadClusterName" -ForegroundColor White
Write-Host "  Control Plane Nodes: $ControlPlaneCount" -ForegroundColor White
Write-Host "  Worker Nodes: $WorkerNodeCount" -ForegroundColor White
if ($InstallObservability) { Write-Host "  Observability: Enabled" -ForegroundColor Green }
if ($InstallSecurity) { Write-Host "  Security: Enabled" -ForegroundColor Green }
if ($InstallAppManagement) { Write-Host "  App Management: Enabled" -ForegroundColor Green }
Write-Host ""

# Step 1: Create directory structure
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 1: Creating Directory Structure" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$directories = @(
    "/mnt/c/av8systems/cluster-api/providers/capd/clusters/management",
    "/mnt/c/av8systems/cluster-api/providers/capd/clusters/workload",
    "/mnt/c/av8systems/cluster-api/tools",
    "/mnt/c/av8systems/cluster-api/apps",
    $tmpDir
)

foreach ($dir in $directories) {
    Write-Host "Creating: $dir" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Host "✓ Directory structure created" -ForegroundColor Green
Write-Host ""

# Step 2: Install prerequisite packages
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 2: Installing Prerequisites" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "Updating package list..." -ForegroundColor Gray
bash -c "sudo apt-get update"

Write-Host "Installing prerequisite packages..." -ForegroundColor Gray
bash -c "sudo apt-get install -y ca-certificates curl gnupg apt-transport-https lsb-release git jq"

Write-Host "✓ Prerequisites installed" -ForegroundColor Green
Write-Host ""

# Step 3: Verify Docker Access
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 3: Verifying Docker Access" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$dockerTest = bash -c "docker ps 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠ Docker requires sudo or group refresh" -ForegroundColor Yellow
    Write-Host "  Attempting to use sudo for Docker commands..." -ForegroundColor Yellow
    $useSudoDocker = $true
} else {
    Write-Host "✓ Docker access confirmed" -ForegroundColor Green
    $useSudoDocker = $false
}
Write-Host ""

# Step 4: Install command line tools
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 4: Installing CLI Tools" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Push-Location $tmpDir

# Install kubectl
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "Installing kubectl..." -ForegroundColor Gray
    bash -c 'curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"'
    bash -c "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
    Remove-Item kubectl -Force -ErrorAction SilentlyContinue
    Write-Host "✓ kubectl installed" -ForegroundColor Green
} else {
    Write-Host "✓ kubectl already installed" -ForegroundColor Green
}

# Install kind
if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
    Write-Host "Installing kind..." -ForegroundColor Gray
    bash -c "curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64"
    bash -c "chmod +x ./kind"
    bash -c "sudo mv ./kind /usr/local/bin/kind"
    Write-Host "✓ kind installed" -ForegroundColor Green
} else {
    Write-Host "✓ kind already installed" -ForegroundColor Green
}

# Install clusterctl
if (-not (Get-Command clusterctl -ErrorAction SilentlyContinue)) {
    Write-Host "Installing clusterctl..." -ForegroundColor Gray
    bash -c "curl -L https://github.com/kubernetes-sigs/cluster-api/releases/latest/download/clusterctl-linux-amd64 -o clusterctl"
    bash -c "chmod +x clusterctl"
    bash -c "sudo mv clusterctl /usr/local/bin/clusterctl"
    Write-Host "✓ clusterctl installed" -ForegroundColor Green
} else {
    Write-Host "✓ clusterctl already installed" -ForegroundColor Green
}

# Install helm
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "Installing helm..." -ForegroundColor Gray
    bash -c "curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null"
    bash -c 'echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list'
    bash -c "sudo apt-get update"
    bash -c "sudo apt-get install helm -y"
    Write-Host "✓ helm installed" -ForegroundColor Green
} else {
    Write-Host "✓ helm already installed" -ForegroundColor Green
}

# Install istioctl
if (-not (Get-Command istioctl -ErrorAction SilentlyContinue)) {
    Write-Host "Installing istioctl..." -ForegroundColor Gray
    bash -c "curl -L https://istio.io/downloadIstio | sh -"
    $istioDir = Get-ChildItem -Directory -Filter "istio-*" | Select-Object -First 1
    if ($istioDir) {
        bash -c "sudo mv $($istioDir.Name)/bin/istioctl /usr/local/bin/"
    }
    Write-Host "✓ istioctl installed" -ForegroundColor Green
} else {
    Write-Host "✓ istioctl already installed" -ForegroundColor Green
}

# Install argocd CLI
if (-not (Get-Command argocd -ErrorAction SilentlyContinue)) {
    Write-Host "Installing argocd CLI..." -ForegroundColor Gray
    bash -c "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
    bash -c "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
    Remove-Item argocd-linux-amd64 -Force -ErrorAction SilentlyContinue
    Write-Host "✓ argocd CLI installed" -ForegroundColor Green
} else {
    Write-Host "✓ argocd CLI already installed" -ForegroundColor Green
}

# Install Vault CLI
if (-not (Get-Command vault -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Vault CLI..." -ForegroundColor Gray
    bash -c "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg"
    bash -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '"'"'(?<=UBUNTU_CODENAME=).*'"'"' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list'
    bash -c "sudo apt update && sudo apt install vault -y"
    Write-Host "✓ Vault CLI installed" -ForegroundColor Green
} else {
    Write-Host "✓ Vault CLI already installed" -ForegroundColor Green
}

Pop-Location
Write-Host ""

# Step 5: Configure Linux host settings
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 5: Configuring Linux Host" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "Loading kernel modules..." -ForegroundColor Gray
bash -c "sudo modprobe br_netfilter || true"
bash -c "sudo modprobe overlay || true"

Write-Host "Configuring network settings..." -ForegroundColor Gray
bash -c @'
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF
'@

Write-Host "Configuring ulimits for host..." -ForegroundColor Gray
bash -c @'
sudo tee /etc/security/limits.d/99-nofile.conf >/dev/null <<EOF
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF
'@

Write-Host "Configuring ulimits for Docker..." -ForegroundColor Gray
bash -c @'
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<EOF
{
  "default-ulimits": {
    "nofile": { "Name": "nofile", "Hard": 1048576, "Soft": 1048576 }
  }
}
EOF
'@

Write-Host "Configuring inotify settings..." -ForegroundColor Gray
bash -c @'
sudo tee /etc/sysctl.d/99-inotify-k8s.conf >/dev/null <<EOF
fs.inotify.max_user_instances=1024
fs.inotify.max_user_watches=1048576
fs.inotify.max_queued_events=32768
EOF
'@

Write-Host "Configuring conntrack limits..." -ForegroundColor Gray
bash -c @'
sudo tee /etc/sysctl.d/99-k8s-conntrack.conf <<EOF
net.netfilter.nf_conntrack_max=1048576
net.netfilter.nf_conntrack_buckets=262144
EOF
'@

Write-Host "Reloading kernel parameters..." -ForegroundColor Gray
bash -c "sudo sysctl --system" | Out-Null

Write-Host "Restarting Docker service..." -ForegroundColor Gray
bash -c "sudo service docker restart"

Write-Host "✓ Linux host configured" -ForegroundColor Green
Write-Host ""

# Step 6: Configure DNS
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 6: Configuring DNS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "Checking DNS configuration..." -ForegroundColor Gray
if (Test-Path "/etc/wsl.conf") {
    $wslConf = Get-Content "/etc/wsl.conf" -Raw
    if ($wslConf -notmatch '\[network\]') {
        Write-Host "Adding network configuration to /etc/wsl.conf..." -ForegroundColor Gray
        bash -c @'
echo '' | sudo tee -a /etc/wsl.conf
echo '[network]' | sudo tee -a /etc/wsl.conf  
echo 'generateResolvConf = false' | sudo tee -a /etc/wsl.conf
'@
    }
} else {
    Write-Host "Creating /etc/wsl.conf..." -ForegroundColor Gray
    bash -c @'
sudo tee /etc/wsl.conf <<EOF
[network]
generateResolvConf = false
EOF
'@
}

Write-Host "Configuring DNS servers..." -ForegroundColor Gray
bash -c @'
sudo chattr -i /etc/resolv.conf 2>/dev/null || true
sudo rm -f /etc/resolv.conf
sudo tee /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
options timeout:2 attempts:3
EOF
sudo chattr +i /etc/resolv.conf
'@

Write-Host "✓ DNS configured" -ForegroundColor Green
Write-Host "⚠ Note: Full DNS changes require WSL restart" -ForegroundColor Yellow
Write-Host ""

# Step 7: Create Management Cluster
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 7: Creating Management Cluster" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$env:MANAGEMENT_CLUSTER_NAME = $ManagementClusterName
$env:WORKLOAD_CLUSTER_NAME = $WorkloadClusterName
$env:WORKLOAD_KUBECONFIG_DIR = "/mnt/c/av8systems/cluster-api/providers/capd/clusters/workload/$WorkloadClusterName/configs"
$env:CLUSTER_TOPOLOGY = "true"
$env:CLUSTERCTL_DEFAULT_INFRASTRUCTURE = "docker"

New-Item -ItemType Directory -Path $env:WORKLOAD_KUBECONFIG_DIR -Force | Out-Null

Push-Location $tmpDir

Write-Host "Creating management cluster configuration..." -ForegroundColor Gray
@"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    image: kindest/node:v1.33.1@sha256:8d866994839cd096b3590681c55a6fa4a071fdaf33be7b9660e5697d2ed13002
    extraMounts:
      - hostPath: /var/run/docker.sock
        containerPath: /var/run/docker.sock
"@ | Set-Content -Path "$ManagementClusterName.yaml"

Write-Host "Creating kind management cluster..." -ForegroundColor Gray
bash -c "kind create cluster --name $ManagementClusterName --config $ManagementClusterName.yaml"

Write-Host "Waiting for management cluster node to be ready..." -ForegroundColor Gray
bash -c "kubectl wait --for=condition=Ready node --all --timeout=300s"

Write-Host "Initializing Cluster API..." -ForegroundColor Gray
bash -c "clusterctl init --infrastructure docker"

Write-Host "Waiting for Cluster API pods to be ready..." -ForegroundColor Gray
bash -c "kubectl wait --for=condition=Ready pods --all -n capi-system --timeout=300s"
bash -c "kubectl wait --for=condition=Ready pods --all -n capi-kubeadm-bootstrap-system --timeout=300s"
bash -c "kubectl wait --for=condition=Ready pods --all -n capi-kubeadm-control-plane-system --timeout=300s"
bash -c "kubectl wait --for=condition=Ready pods --all -n capd-system --timeout=300s"

Write-Host "✓ Management cluster created successfully" -ForegroundColor Green
Write-Host ""

# Step 8: Create Workload Cluster
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 8: Creating Workload Cluster" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$env:WORKLOAD_KUBECONFIG_FILE = "$env:WORKLOAD_KUBECONFIG_DIR/$WorkloadClusterName.kubeconfig"

Write-Host "Generating workload cluster configuration..." -ForegroundColor Gray
bash -c "clusterctl generate cluster $WorkloadClusterName --flavor development --infrastructure docker --kubernetes-version v1.32.0 --control-plane-machine-count=$ControlPlaneCount --worker-machine-count=$WorkerNodeCount > $WorkloadClusterName.yaml"

Write-Host "Creating workload cluster..." -ForegroundColor Gray
bash -c "kubectl apply -f $WorkloadClusterName.yaml"

Write-Host "Sleeping for 1 minute..." -ForegroundColor Gray
Start-Sleep -Seconds 60

Write-Host "Exporting workload cluster kubeconfig..." -ForegroundColor Gray
bash -c "clusterctl get kubeconfig '$WorkloadClusterName' > '$env:WORKLOAD_KUBECONFIG_FILE'"

Write-Host "Merging kubeconfig files..." -ForegroundColor Gray
bash -c @"
mkdir -p `$HOME/.kube
cp "`$HOME/.kube/config" "`$HOME/.kube/config.bak.`$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
KUBECONFIG="`$HOME/.kube/config:$env:WORKLOAD_KUBECONFIG_FILE" kubectl config view --merge --flatten > "`$HOME/.kube/config.merged"
mv "`$HOME/.kube/config.merged" "`$HOME/.kube/config"
"@

Write-Host "Switching to workload cluster context..." -ForegroundColor Gray
bash -c "kubectl config use-context $WorkloadClusterName-admin@$WorkloadClusterName"

Write-Host "✓ Workload cluster created successfully" -ForegroundColor Green
Write-Host ""

# Step 9: Install Calico CNI
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 9: Installing Calico CNI" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "Installing Calico..." -ForegroundColor Gray
bash -c "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml"

Write-Host "Waiting for Calico pods to be ready..." -ForegroundColor Gray
bash -c "kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=600s"

Write-Host "Waiting for nodes to be ready..." -ForegroundColor Gray
bash -c "kubectl wait --for=condition=Ready node --all --timeout=300s"

Write-Host "✓ Calico CNI installed successfully" -ForegroundColor Green
Write-Host ""

# Step 10: Install MetalLB
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 10: Installing MetalLB" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "Installing MetalLB..." -ForegroundColor Gray
bash -c "kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml"

Write-Host "Waiting for MetalLB pods to be ready..." -ForegroundColor Gray
Start-Sleep -Seconds 10
bash -c "kubectl wait --for=condition=Ready pods --all -n metallb-system --timeout=300s"

Write-Host "Using IP range: $ipRange" -ForegroundColor Gray

@"
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: capd-pool
  namespace: metallb-system
spec:
  addresses:
  - $ipRange
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: capd-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - capd-pool
"@ | Set-Content -Path "$env:WORKLOAD_KUBECONFIG_DIR/$WorkloadClusterName-metallb-ipam.yaml"

Write-Host "Applying MetalLB configuration..." -ForegroundColor Gray
bash -c "kubectl apply -f '$env:WORKLOAD_KUBECONFIG_DIR/$WorkloadClusterName-metallb-ipam.yaml'"

Write-Host "✓ MetalLB installed successfully with IP range: $ipRange" -ForegroundColor Green
Write-Host ""

# Step 11: Install Storage Provisioner
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 11: Installing Storage Provisioner" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "Installing local-path-provisioner..." -ForegroundColor Gray
bash -c "kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml"

Write-Host "Waiting for local-path-provisioner pods to be ready..." -ForegroundColor Gray
bash -c "kubectl wait --for=condition=Ready pods --all -n local-path-storage --timeout=300s"

Write-Host "Setting local-path as default storage class..." -ForegroundColor Gray
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

Write-Host "✓ Storage provisioner installed successfully" -ForegroundColor Green
Write-Host ""

# Step 12: Install Metrics Server
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 12: Installing Metrics Server" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "Adding metrics-server Helm repo..." -ForegroundColor Gray
bash -c "helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/"
bash -c "helm repo update metrics-server"

Write-Host "Installing metrics-server..." -ForegroundColor Gray
bash -c "helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system --set 'args={--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP\,ExternalIP\,Hostname}'"

Write-Host "Waiting for metrics-server to be ready..." -ForegroundColor Gray
bash -c "kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=metrics-server -n kube-system --timeout=300s"

Write-Host "✓ Metrics server installed successfully" -ForegroundColor Green
Write-Host ""

# Step 13: Install Vertical Pod Autoscaler
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 13: Installing Vertical Pod Autoscaler" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Push-Location $tmpDir

if (Test-Path "autoscaler") {
    Remove-Item -Recurse -Force "autoscaler"
}

Write-Host "Cloning autoscaler repository..." -ForegroundColor Gray
bash -c "git clone https://github.com/kubernetes/autoscaler.git"

Write-Host "Installing VPA..." -ForegroundColor Gray
Push-Location "autoscaler/vertical-pod-autoscaler"
bash -c "./hack/vpa-up.sh"
Pop-Location

Write-Host "✓ Vertical Pod Autoscaler installed successfully" -ForegroundColor Green
Pop-Location
Write-Host ""

# Step 14: Configure CoreDNS
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 14: Configuring CoreDNS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "Updating CoreDNS configuration..." -ForegroundColor Gray
@"
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . 1.1.1.1 8.8.8.8 {
          max_concurrent 1000
        }
        cache 30 {
           disable success cluster.local
           disable denial cluster.local
        }
        loop
        reload
        loadbalance
    }
"@ | Set-Content -Path "core-dns.yaml"

Write-Host "Updating core dns configuration..." -ForegroundColor Gray
bash -c "kubectl apply -f 'core-dns.yaml'"

Write-Host "Restarting CoreDNS..." -ForegroundColor Gray
bash -c "kubectl rollout restart deployment -n kube-system coredns"
bash -c "kubectl wait --for=condition=Ready pods -l k8s-app=kube-dns -n kube-system --timeout=300s"

Write-Host "✓ CoreDNS configured successfully" -ForegroundColor Green
Write-Host ""

# Optional: Install Observability Workloads
if ($InstallObservability) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Step 15: Installing Observability Stack" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green

    Push-Location $tmpDir

    Write-Host "Installing Istio..." -ForegroundColor Gray
    bash -c "istioctl install -y --set profile=demo"

    $istioDir = Get-ChildItem -Directory -Filter "istio-*" | Select-Object -First 1
    if ($istioDir) {
        Push-Location "$($istioDir.Name)/samples/addons"

        Write-Host "Installing Kiali..." -ForegroundColor Gray
        bash -c "kubectl apply -f ./kiali.yaml"

        Write-Host "Installing Prometheus..." -ForegroundColor Gray
        bash -c "kubectl apply -f ./prometheus.yaml"

        Write-Host "Installing Grafana..." -ForegroundColor Gray
        bash -c "kubectl apply -f ./grafana.yaml"

        Write-Host "Installing Jaeger..." -ForegroundColor Gray
        bash -c "kubectl apply -f ./jaeger.yaml"

        Write-Host "Installing Loki..." -ForegroundColor Gray
        bash -c "kubectl apply -f ./loki.yaml"

        Pop-Location
    }

    Write-Host "Waiting for observability stack to be ready..." -ForegroundColor Gray
    Start-Sleep -Seconds 30

    Write-Host "Labeling namespaces with pod security standards..." -ForegroundColor Gray
    bash -c "kubectl label --overwrite ns --all pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/audit=baseline pod-security.kubernetes.io/warn=baseline"

    Write-Host "✓ Observability stack installed successfully" -ForegroundColor Green
    Pop-Location
    Write-Host ""
}

# Optional: Install Security Workloads
if ($InstallSecurity) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Step 16: Installing Security Stack" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green

    Write-Host "Installing Falco and Falco UI..." -ForegroundColor Gray
    bash -c "helm repo add falcosecurity https://falcosecurity.github.io/charts"
    bash -c "helm repo update falcosecurity"
    bash -c "helm install falco falcosecurity/falco --create-namespace --namespace falco --set falcosidekick.enabled=true --set falcosidekick.webui.enabled=true"

    Write-Host "Installing Kyverno..." -ForegroundColor Gray
    bash -c "helm repo add kyverno https://kyverno.github.io/kyverno/"
    bash -c "helm repo update kyverno"
    bash -c "helm install kyverno kyverno/kyverno -n kyverno --create-namespace"

    Write-Host "Installing Kyverno Policy Reporter with UI..." -ForegroundColor Gray
    bash -c "helm repo add policy-reporter https://kyverno.github.io/policy-reporter"
    bash -c "helm repo update policy-reporter"
    bash -c "helm install policy-reporter policy-reporter/policy-reporter --create-namespace -n policy-reporter --set ui.enabled=true"

    Write-Host "Installing Vault Server..." -ForegroundColor Gray
    bash -c "helm repo add hashicorp https://helm.releases.hashicorp.com"
    bash -c "helm repo update hashicorp"
    bash -c "helm install vault hashicorp/vault -n vault --create-namespace --set injector.enabled=false"

    Write-Host "Installing Vault Secrets Operator..." -ForegroundColor Gray
    bash -c "helm install vault-secrets-operator hashicorp/vault-secrets-operator -n vault-secrets-operator-system --create-namespace"

    Write-Host "Installing Trivy..." -ForegroundColor Gray
    bash -c "helm repo add aqua https://aquasecurity.github.io/helm-charts/"
    bash -c "helm repo update aqua"
    bash -c 'helm install trivy-operator aqua/trivy-operator --namespace trivy-system --create-namespace --set="trivy.ignoreUnfixed=true"'

    Write-Host "Labeling namespaces with pod security standards..." -ForegroundColor Gray
    bash -c "kubectl label --overwrite ns --all pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/audit=baseline pod-security.kubernetes.io/warn=baseline"

    Write-Host "✓ Security stack installed successfully" -ForegroundColor Green
    Write-Host ""
}

# Optional: Install Application Management Workloads
if ($InstallAppManagement) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Step 17: Installing App Management Stack" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green

    Write-Host "Installing ArgoCD..." -ForegroundColor Gray
    bash -c "helm repo add argo https://argoproj.github.io/argo-helm/"
    bash -c "helm repo update argo"
    bash -c "helm install argocd argo/argo-cd --namespace argocd --create-namespace"

    Write-Host "Installing Keda..." -ForegroundColor Gray
    bash -c "helm repo add kedacore https://kedacore.github.io/charts"
    bash -c "helm repo update kedacore"
    bash -c "helm install keda kedacore/keda --namespace keda --create-namespace"

    Write-Host "Installing Harbor..." -ForegroundColor Gray
    bash -c "helm repo add harbor https://helm.goharbor.io"
    bash -c "helm repo update harbor"
    bash -c "helm install harbor harbor/harbor --namespace harbor --create-namespace"

    Write-Host "Labeling namespaces with pod security standards..." -ForegroundColor Gray
    bash -c "kubectl label --overwrite ns --all pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/audit=baseline pod-security.kubernetes.io/warn=baseline"

    Write-Host "✓ Application management stack installed successfully" -ForegroundColor Green
    Write-Host ""
}

# Final Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Management Cluster: $ManagementClusterName" -ForegroundColor White
Write-Host "  Workload Cluster: $WorkloadClusterName" -ForegroundColor White
Write-Host "  Control Plane Nodes: $ControlPlaneCount" -ForegroundColor White
Write-Host "  Worker Nodes: $WorkerNodeCount" -ForegroundColor White
Write-Host ""

if ($InstallObservability -or $InstallSecurity -or $InstallAppManagement) {
    Write-Host "Installed Workloads:" -ForegroundColor Cyan
    if ($InstallObservability) {
        Write-Host "  ✓ Observability Stack (Istio, Kiali, Prometheus, Grafana, Jaeger, Loki)" -ForegroundColor Green
    }
    if ($InstallSecurity) {
        Write-Host "  ✓ Security Stack (Falco, Kyverno, Vault, Trivy)" -ForegroundColor Green
    }
    if ($InstallAppManagement) {
        Write-Host "  ✓ App Management Stack (ArgoCD, Keda, Harbor)" -ForegroundColor Green
    }
    Write-Host ""
}

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Verify cluster status:" -ForegroundColor White
Write-Host "   kubectl get nodes" -ForegroundColor Gray
Write-Host "   kubectl get pods -A" -ForegroundColor Gray
Write-Host ""
Write-Host "2. View MetalLB IP range:" -ForegroundColor White
Write-Host "   kubectl get ipaddresspool -n metallb-system" -ForegroundColor Gray
Write-Host ""

if ($InstallSecurity) {
    Write-Host "3. Unseal Vault (if installed):" -ForegroundColor White
    Write-Host "   kubectl exec -n vault vault-0 -- vault operator init" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Configuration files are located at:" -ForegroundColor Cyan
Write-Host "  C:\av8systems\cluster-api\" -ForegroundColor White
Write-Host ""
Write-Host "Happy clustering! 🚀" -ForegroundColor Green
Write-Host ""
