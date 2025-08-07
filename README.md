# argo-minio

Test mono repo to deploy minio Operator and Tenant with ArgoCD and directpv


# The folder scripts contains:

 - bootstrap-directpv.sh (This script install and configure directpv with the dedicated nodes for minio operations)
 - directpv-addNode.sh (This script will add an additional node to directpv to expand the storage capacity available for minio)
 - bootstrap-argo.sh (kubectl apply of argocd/project/project-minio.yaml and  argocd/bootstrap/apps.yaml that will deploy Argocd App from folder argocd/minio)

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

# argocd

- argocd/bootstrap/ > app of apps -  apps.yaml defined as root-app to handle minio operator and minio tenants.
- argocd/minio/operator > argocd app to handle minio-operator will look at helm/values-operator.yaml behing path /helm.
- argocd/minio/tenant-one > argocd app to handle minio-operator will look at helm/values-tenant-one.yaml behing path /helm.
- argocd/minio/tenant-two > argocd app to handle minio-operator will look at helm/values-tenant-two.yaml behing path /helm.
- argocd/project | Argo project - Project specifically created to handle minio applications, it allow to key minio in a controller space behind ArgoCD.


# Minio operator and tenants custom helm chart definitions with ESO (external secrets operator) copied on /charts 


# Experimental - TODO helm-chart definitions using helm templates, it could be complex to handle having many tenants.
helm-chart
  Chart.yaml
  templates
    minio-operator.yaml
    tenant.yaml
  values
    tenant-one.yaml  
    tenant-two.yaml





