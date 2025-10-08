## General commands

### Migrate buckets metadata

```bash
mc admin cluster bucket export acme-legacy
mc admin cluster bucket import acme-mkpl ./acme-legacy-bucket-metadata.zip
```

### Migrate iam

```bash
mc admin cluster iam export acme-legacy
mc admin cluster iam import acme-mkpl ./acme-legacy-iam-info.zip
```

### Copy bucket data sample

```bash
mc mirror --dry-run acme-legacy/aif-dev-cwl-test acme-mkpl/aif-dev-cwl-test
```

### Update buckets list

```bash
mc ls acme-legacy | awk '{print $NF}' | sed 's/\/$//' > buckets_list.txt
```

## How to run the script on cluster

Get access keys and secret keys from source and target MinIO environments and update `migrate.sh` script.

Launch a pod with alpine image on cluster.

```bash
kubectl run -it --rm s3-migrator01 --image=alpine:latest --namespace=minio-operator --restart=Never -- sh
```

Copy the script and buckets list to the pod.
Execute the script.

```bash
./migrate.sh
```
