## References

Helm operator:
https://min.io/docs/minio/kubernetes/upstream/operations/install-deploy-manage/deploy-operator-helm.html

Helm operator values:
https://min.io/docs/minio/kubernetes/upstream/reference/operator-chart-values.html#minio-operator-chart-values

## Commands

```bash
helm install -n sample-operator minio-operator . --create-namespace
```