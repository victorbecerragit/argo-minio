# minio-sample

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://operator.min.io | tenant | 7.1.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| eso.minio.client_secret_property | string | `"openid-client-secret"` |  |
| eso.minio.config_secret_path | string | `"minio/sample/config"` |  |
| eso.minio.password_secret_property | string | `"password"` |  |
| eso.minio.user_secret_property | string | `"user"` |  |
| eso.secret_store.kind | string | `"ClusterSecretStore"` |  |
| eso.secret_store.name | string | `"infrastructure-vault"` |  |
| eso.wilcard_cert.crt_property | string | `"tls.crt"` |  |
| eso.wilcard_cert.key_property | string | `"tls.key"` |  |
| eso.wilcard_cert.vault_path | string | `"wildcard_cert"` |  |
| tenant.ingress.api.annotations | object | `{}` |  |
| tenant.ingress.api.enabled | bool | `false` |  |
| tenant.ingress.api.host | string | `"minio.local"` |  |
| tenant.ingress.api.ingressClassName | string | `""` |  |
| tenant.ingress.api.labels | object | `{}` |  |
| tenant.ingress.api.path | string | `"/"` |  |
| tenant.ingress.api.pathType | string | `"Prefix"` |  |
| tenant.ingress.api.tls | list | `[]` |  |
| tenant.ingress.console.annotations | object | `{}` |  |
| tenant.ingress.console.enabled | bool | `false` |  |
| tenant.ingress.console.host | string | `"minio-console.local"` |  |
| tenant.ingress.console.ingressClassName | string | `""` |  |
| tenant.ingress.console.labels | object | `{}` |  |
| tenant.ingress.console.path | string | `"/"` |  |
| tenant.ingress.console.pathType | string | `"Prefix"` |  |
| tenant.ingress.console.tls | list | `[]` |  |
| tenant.tenant.additionalVolumeMounts | list | `[]` |  |
| tenant.tenant.additionalVolumes | list | `[]` |  |
| tenant.tenant.buckets | list | `[]` |  |
| tenant.tenant.certificate.certConfig | object | `{}` |  |
| tenant.tenant.certificate.externalCaCertSecret | list | `[]` |  |
| tenant.tenant.certificate.externalCertSecret | list | `[]` |  |
| tenant.tenant.certificate.requestAutoCert | bool | `true` |  |
| tenant.tenant.configSecret.accessKey | string | `"minio"` |  |
| tenant.tenant.configSecret.name | string | `"myminio-env-configuration"` |  |
| tenant.tenant.configSecret.secretKey | string | `"minio123"` |  |
| tenant.tenant.configuration.name | string | `"myminio-env-configuration"` |  |
| tenant.tenant.env | list | `[]` |  |
| tenant.tenant.exposeServices | object | `{}` |  |
| tenant.tenant.features.bucketDNS | bool | `false` |  |
| tenant.tenant.features.domains | object | `{}` |  |
| tenant.tenant.features.enableSFTP | bool | `false` |  |
| tenant.tenant.image.pullPolicy | string | `"IfNotPresent"` |  |
| tenant.tenant.image.repository | string | `"quay.io/minio/minio"` |  |
| tenant.tenant.image.tag | string | `"RELEASE.2024-11-07T00-52-20Z"` |  |
| tenant.tenant.imagePullSecret | object | `{}` |  |
| tenant.tenant.initContainers | list | `[]` |  |
| tenant.tenant.lifecycle | object | `{}` |  |
| tenant.tenant.liveness | object | `{}` |  |
| tenant.tenant.logging | object | `{}` |  |
| tenant.tenant.metrics.enabled | bool | `false` |  |
| tenant.tenant.metrics.port | int | `9000` |  |
| tenant.tenant.metrics.protocol | string | `"http"` |  |
| tenant.tenant.mountPath | string | `"/export"` |  |
| tenant.tenant.name | string | `"myminio"` |  |
| tenant.tenant.podManagementPolicy | string | `"Parallel"` |  |
| tenant.tenant.poolsMetadata.annotations | object | `{}` |  |
| tenant.tenant.poolsMetadata.labels | object | `{}` |  |
| tenant.tenant.pools[0].affinity | object | `{}` |  |
| tenant.tenant.pools[0].annotations | object | `{}` |  |
| tenant.tenant.pools[0].containerSecurityContext.allowPrivilegeEscalation | bool | `false` |  |
| tenant.tenant.pools[0].containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| tenant.tenant.pools[0].containerSecurityContext.runAsGroup | int | `1000` |  |
| tenant.tenant.pools[0].containerSecurityContext.runAsNonRoot | bool | `true` |  |
| tenant.tenant.pools[0].containerSecurityContext.runAsUser | int | `1000` |  |
| tenant.tenant.pools[0].containerSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| tenant.tenant.pools[0].labels | object | `{}` |  |
| tenant.tenant.pools[0].name | string | `"pool-0"` |  |
| tenant.tenant.pools[0].nodeSelector | object | `{}` |  |
| tenant.tenant.pools[0].resources | object | `{}` |  |
| tenant.tenant.pools[0].securityContext.fsGroup | int | `1000` |  |
| tenant.tenant.pools[0].securityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| tenant.tenant.pools[0].securityContext.runAsGroup | int | `1000` |  |
| tenant.tenant.pools[0].securityContext.runAsNonRoot | bool | `true` |  |
| tenant.tenant.pools[0].securityContext.runAsUser | int | `1000` |  |
| tenant.tenant.pools[0].servers | int | `4` |  |
| tenant.tenant.pools[0].size | string | `"10Gi"` |  |
| tenant.tenant.pools[0].storageAnnotations | object | `{}` |  |
| tenant.tenant.pools[0].storageLabels | object | `{}` |  |
| tenant.tenant.pools[0].tolerations | list | `[]` |  |
| tenant.tenant.pools[0].topologySpreadConstraints | list | `[]` |  |
| tenant.tenant.pools[0].volumesPerServer | int | `4` |  |
| tenant.tenant.priorityClassName | string | `""` |  |
| tenant.tenant.prometheusOperator | bool | `false` |  |
| tenant.tenant.readiness | object | `{}` |  |
| tenant.tenant.scheduler | object | `{}` |  |
| tenant.tenant.serviceAccountName | string | `""` |  |
| tenant.tenant.serviceMetadata | object | `{}` |  |
| tenant.tenant.startup | object | `{}` |  |
| tenant.tenant.subPath | string | `"/data"` |  |
| tenant.tenant.users | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
