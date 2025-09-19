
# This repo is a test performed to install directpv using "kustomize"
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




