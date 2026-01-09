# cluster-api-capd
Build and bootstrap Kubernetes cluster on your local laptop using Wsl and the Cluster Api Docker provider CAPD.

This guide provides a comprehensive technical framework for building a platform engineering laboratory using Cluster API and the CAPD provider. It begins with the initial setup of WSL, Docker, and essential command-line utilities like kubectl and kind to bootstrap both management and workload clusters. The documentation details how to configure critical infrastructure components, including networking, load balancing via MetalLB, and persistent storage. Furthermore, it outlines the integration of advanced observability tools, security protocols such as Falco and Vault, and GitOps deployment workflows with Argo CD. This resource serves as a structured roadmap for engineers to deploy, manage, and eventually dismantle a sophisticated, multi-layered Kubernetes environment.

      __      _____     _____           _                     
     /\ \    / / _ \   / ____|         | |                    
    /  \ \  / / (_) | | (___  _   _ ___| |_ ___ _ __ ___  ___ 
   / /\ \ \/ / > _ <   \___ \| | | / __| __/ _ \ '_ ` _ \/ __|
  / ____ \  / | (_) |  ____) | |_| \__ \ ||  __/ | | | | \__ \
 /_/    \_\/   \___/  |_____/ \__, |___/\__\___|_| |_| |_|___/
                               __/ |                          
                              |___/   
