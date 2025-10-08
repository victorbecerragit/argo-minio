
# argo-minio

Test mono repo to deploy minio Operator, Tenant  and directpv with ArgoCD

POC repository used to implemented customer production environment with minio Infrastructure MNMD (Multi-Node Multi-Drive)

# The folder scripts contains:

| Application | Description |
|-------------|-------------|
| [bootstrap-directpv](scripts/bootstrap-directpv.sh) | This script install and configure directpv with the dedicated nodes for minio operations |
| [directpv-addNode](scripts/directpv-addNode.sh) | This script will add an additional node to directpv to expand the storage capacity available for minio  |
| [bootstrap-argoy](scripts/bootstrap-argo.sh) | kubectl apply of argocd/project/project-minio.yaml and  argocd/bootstrap/apps.yaml that will deploy Argocd App from folder argocd/minio |

```yaml

# DirectPV 

Directpv is the "volume manager" that handle the drivers for minio in autonomy, this component is crucial to be installed before than the bootstrap of minio.
The script require have full Cluster admin permission with the kubeconfig already in place.

Storage Pre-requisite:

Node created with longhorn disabled and predefined drivers without partition on it.
The node should be added in the cluster with the following tain:


taints:
    - effect: NoSchedule
      key: minio-directpv
      value: storage


- Effect: NoSchedule → Pods that don’t tolerate this taint will not be scheduled on this node.

Directpv and minio will respect this toleration.
```

# argocd

| Application | Description |
|-------------|-------------|
| [argocd/bootstrap/](argocd/bootstrap/) | app of apps -  apps.yaml defined as root-app to handle minio operator and minio tenants. |
| [argocd/minio/operator](argocd/minio/operator) | argocd app to handle minio-operator will look at helm/values-operator.yaml behing path /helm.  |
| [argocd/minio/tenant-one](argocd/minio/tenant-one) | argocd app to handle minio-operator will look at helm/values-tenant-one.yaml behing path /helm. |
| [argocd/minio/tenant-two](argocd/minio/tenant-two) | argocd app to handle minio-operator will look at helm/values-tenant-two.yaml behing path /helm. |
| [argocd/project](argocd/project) | Argo project - Project specifically created to handle minio applications, it allow to key minio in a controller space behind ArgoCD. |


# Minio operator and tenants custom helm chart definitions with ESO (external secrets operator) copied on /charts 

# Experimental Optional to deploy minio using Helm Chart directly .
# The cons of this approach is that every time that there is a modification like add a tenants, modifi secrets and so on.
# Argo will refresh/sync the Helm application if there are syntax errors on helm templating or so, will brake the installation.
# Also helm-chart definitions using helm templates, it could be complex to handle having many tenants.

helm-chart
  Chart.yaml
  templates
    minio-operator.yaml
    tenant.yaml
  values
    tenant-one.yaml  
    tenant-two.yaml


```yaml

# This part of the repo is a poc to install directpv using "kustomize" based on minio/directpv resources repository.
# Source repo : https://github.com/minio/directpv/tree/master/resources

# It was modified with node labels and tolerations to be distribuited accross nodes during the installations.

# Pre-requisite 

    - # Kubernetes nodes

        Directpv Controller nodes should have this label > "directpv-controller=yes"

        Directpv Worker nodes should have this label > "directpv-node=yes"

    - # Docker image 
        The cronjob job use a custom docker image with kubectl, directpv and the directpv-discovery.sh script.

        To build the docker image check out : kustomize/directpv/build


To test test it, the cluster should not have installed directpv, it make exclusive use of namespace "directpv".

git clone ...

cd kustomize/directpv/overlays/

 - cronjobs

   - kubejob-directpv-discover.yaml #Run as needed to discover new nodes/sotrage to add to directpv.

   - kubejob-directpv-info.yaml     #Run every 1 hours and print the directpv info command.

 - dev

   - daemonset-node-toleration-patch.yaml

   - deployment-affinity-selector-patch.yaml

 - minio (idem dev)

 - prod  (idem dev)

kustomize build kustomize/directpv/overlays/minio |kubectl apply  -f -

# In the cronjobs folder there are a few examples of kubecronjobs that  execute in a schedule basic inside the cluster the command "kubectl directpv discover"

# This allow to have the discovery of nodes/storage dinamically performed without need of further actions 




