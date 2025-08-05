# argo-minio

Test mono repo to deploy minio Operator and Tenant with ArgoCD and directpv


# The folder scripts contains:

 - bootstrap-directpv.sh (This script install and configure directpv with the dedicated nodes for minio operations)

 - bootstrap-argo.sh (This is just a kubectl apply of argo project "system" from where the "app" minio will deploy the helms charts from folder /helm)

# argocd/minio/ > root argocd app to handle helm charts (similar to an umbrella chart), will check everything behing path /helm.

- apps.yaml


# Minio operator and tenants helm chart definitions are behind folder /helm


helm
  Chart.yaml
  templates
    minio-operator.yaml
    tenant-one.yaml
    tenant-two.yaml





