# Build and bootstrap Kubernetes cluster on your local laptop using Wsl and the Cluster Api Docker provider CAPD
This guide also addresses some of problems you might run into (that make you want to give up or put it off) 
after creating you managment or workload cluster.

# Optional workload installation
After you complete all infrastructure tasks you dont have to install every workload
as it will consume a lot of cpu and memory resources.
Only the ones you will be working with and any ones they depend on can be installed.
As an example if you are deploying argo cd and want to use istio ingress to access it
then Istio needs to be installed as well.

# Anytime you see <<EOF copy the full block of text until you see EOF at the bottom of the block
sudo tee /etc/security/limits.d/99-nofile.conf >/dev/null <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

# Formatting might be off and must be fixed if pasting from install document into vim editor
As a workaround you can create the files using notepad or vs code.
As an example, for the management cluster create a new file then paste in the yaml from the install document
then save it in the '/mnt/c/av8systems/cluster-api/tmp' directory with the name 'd01capimgmt001.yaml' 
