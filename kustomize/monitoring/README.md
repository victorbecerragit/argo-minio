
# This repo is a test performed to install monitoring configurations using "kustomize"

# Pre-requisite 

    - # Minio-Tenant

        Prometheus minio-servicemonitor require this label > "v1.min.io/tenant: tenant-mkpl" defined on minio-tenant service "minio" to autodiscover nodes.


To test test it, the cluster should have RKE/2 solution monitoring installed, it will create a servicemonitor on ns "cattle-monitoring-system" and configmaps on ns "cattle-dashboards"

git clone ...

cd kustomize/monitoring

 - base

   - prometheus/minio-servicemonitor.yaml

   - grafana-dashboards/minio-bucket-dashboard-configmap.yaml
   
   - grafana-dashboards/minio-dashboard-configmap.yaml

 - minio/prod  (overlays/)

kustomize build kustomize/monitoring/overlays/minio |kubectl apply  -f -

# This allow to have the discovery of nodes/storage dinamically performed without need of further actions from Grafana/Prometheus




