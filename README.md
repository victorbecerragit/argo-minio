# argo-minio

Test mono repo to deploy minio Operator and Tenant with ArgoCD


# Default values that could overwritte.

helm show values minio/operator --version 7.1.0 > minio-operator-defaults.yaml

helm show values minio/tenant --version 7.1.0 > minio-tenant-defaults.yaml


# Sample main root argocd app to handle helm charts (similar to an umbrella chart), will check everything behing path /helm.

- apps.yaml


# Minio operator and tenant helm chart definitions within path /helm


helm
  Chart.yaml
  templates
    minio-operator.yaml
    minio-tenant.yaml

# ArgoCD Application template reference

https://github.com/victorbecerragit/argocd-demo/blob/master/application-template.yaml


