# PolicyBinding Integration Guide for MinIO Tenant Helm Charts

## Overview

This guide demonstrates how to integrate **PolicyBinding** resources directly into your MinIO tenant Helm chart templates. This approach provides declarative policy management using Kubernetes-native resources while leveraging the MinIO Operator's STS (Security Token Service) capabilities.

## Why Use PolicyBinding Templates?

### Traditional Approach Limitations:
- ❌ Policies cannot be defined in `values.yaml`
- ❌ Manual policy creation after tenant deployment
- ❌ No GitOps-friendly policy management
- ❌ Complex disaster recovery for policies

### PolicyBinding Template Approach Benefits:
- ✅ **Declarative Configuration**: Define policies in Helm values
- ✅ **GitOps Ready**: Version control policy changes
- ✅ **Kubernetes Native**: Uses CRDs and service accounts
- ✅ **Automatic Management**: Policies created during deployment
- ✅ **Secure**: Token-based authentication via STS
- ✅ **Scalable**: Easy to add new roles and policies

## Prerequisites

### MinIO Operator Requirements:
1. **MinIO Operator v5.0.0+** installed in cluster
2. **STS enabled** in operator: `OPERATOR_STS_ENABLED=on`
3. **PolicyBinding CRD** available (automatic with STS)

### Kubernetes Requirements:
1. **Kubernetes v1.19+** (for CRD support)
2. **Helm v3.8+** for chart management
3. **RBAC enabled** in cluster

### Validation Commands:
```bash
# Check operator STS status
kubectl -n minio-operator get deployment minio-operator -o yaml | grep OPERATOR_STS_ENABLED

# Verify PolicyBinding CRD exists
kubectl get crd policybindings.sts.min.io

# Check API versions
kubectl api-versions | grep sts.min.io
```

## Integration Steps

### Step 1: Prepare Your Chart Structure

Create the following directory structure:
```
your-minio-chart/
├── Chart.yaml
├── values.yaml                    # Enhanced with PolicyBinding config
├── templates/
│   ├── _helpers.tpl              # Template functions
│   ├── tenant.yaml               # Your existing tenant resource
│   ├── serviceaccount.yaml       # PolicyBinding service accounts  
│   ├── policybinding.yaml        # PolicyBinding CRDs
│   ├── policy-configmap.yaml     # Policy definitions
│   ├── policy-setup-job.yaml     # Policy creation job
│   ├── rbac.yaml                 # RBAC for policy management
│   └── NOTES.txt                 # Usage instructions
```

### Step 2: Update Chart.yaml

Add operator dependency to ensure STS availability:
```yaml
apiVersion: v2
name: your-minio-tenant
version: 1.0.0
dependencies:
- name: operator
  version: ">=5.0.0" 
  repository: https://operator.min.io
  condition: operator.enabled
```

### Step 3: Enhance values.yaml

Replace your `values.yaml` with the PolicyBinding-enabled configuration:
```yaml
# Core tenant configuration (your existing config)
tenant:
  name: minio-tenant
  namespace: minio-tenant-ns

# Enable PolicyBinding features
sts:
  enabled: true                    # Enable STS features
  policyBindingEnabled: true       # Create PolicyBinding resources
  policyManagement:
    enabled: true                  # Auto-create policies
    method: "job"                  # Use Kubernetes Job

# Define your 4 required roles + guest
policies:
  administrator:
    enabled: true
    name: administrator-policy
    # ... (policy definition)
  auditor:
    enabled: true  
    name: auditor-policy
    # ... (policy definition)
  datalakeAdmin:
    enabled: true
    name: datalake-admin-policy  
    # ... (policy definition)
  datalakeViewer:
    enabled: true
    name: datalake-viewer-policy
    # ... (policy definition)
  guest:
    enabled: true
    name: guest-policy
    # ... (policy definition)
```

### Step 4: Add Template Files

Copy the provided template files to your `templates/` directory:

1. **_helpers.tpl** - Template helper functions
2. **serviceaccount.yaml** - Service accounts for each role
3. **policybinding.yaml** - PolicyBinding CRD resources
4. **policy-configmap.yaml** - Policy definitions as ConfigMap
5. **policy-setup-job.yaml** - Job to create policies in MinIO
6. **rbac.yaml** - RBAC for policy management
7. **NOTES.txt** - User instructions and status

### Step 5: Test the Integration

#### Dry Run Validation:
```bash
# Test template rendering
helm template minio-tenant ./your-chart -f values.yaml

# Validate with dry-run
helm install minio-tenant ./your-chart --dry-run --debug -f values.yaml
```

#### Check Generated Resources:
```bash
# Verify ServiceAccounts are created
helm template minio-tenant ./your-chart | grep "kind: ServiceAccount"

# Verify PolicyBindings are created (if STS available)
helm template minio-tenant ./your-chart | grep "kind: PolicyBinding"

# Check policy job configuration
helm template minio-tenant ./your-chart | grep -A 20 "kind: Job"
```

### Step 6: Deploy and Verify

#### Deploy the Chart:
```bash
helm install minio-tenant ./your-chart -n minio-tenant-ns --create-namespace -f values.yaml
```

#### Verify Deployment:
```bash
# Check tenant status
kubectl get tenant -n minio-tenant-ns

# Verify service accounts
kubectl get sa -n minio-tenant-ns

# Check PolicyBindings (if STS enabled)
kubectl get policybinding -n minio-tenant-ns

# Monitor policy creation job
kubectl logs job/minio-tenant-policy-setup -n minio-tenant-ns
```

#### Test Access:
```bash
# Test with datalake-viewer service account
kubectl run test-viewer --image=minio/mc:latest --serviceaccount=datalake-viewer-sa -n minio-tenant-ns -- sleep 3600

# Test MinIO access (in pod)
kubectl exec -it test-viewer -n minio-tenant-ns -- mc alias set minio https://minio-tenant-hl:9000
kubectl exec -it test-viewer -n minio-tenant-ns -- mc ls minio/
```

## Advanced Configuration

### Custom Policy Example

Add custom policies to your values.yaml:
```yaml
policies:
  # ... existing policies

  custom:
    dataScientist:
      enabled: true
      name: data-scientist-policy
      description: "Access to ML datasets only"
      policy:
        Version: "2012-10-17"
        Statement:
        - Effect: Allow
          Action: ["s3:GetObject", "s3:ListBucket"]
          Resource: 
          - "arn:aws:s3:::ml-datasets"
          - "arn:aws:s3:::ml-datasets/*"
        - Effect: Allow  
          Action: ["s3:PutObject"]
          Resource: ["arn:aws:s3:::ml-results/*"]
      serviceAccount:
        name: data-scientist-sa
        create: true
      policyBinding:
        enabled: true
        name: data-scientist-binding
```

### Environment-Specific Configuration

Use different values files for different environments:

**values-dev.yaml:**
```yaml
policies:
  guest:
    enabled: true    # Allow guest access in dev
  administrator:
    enabled: true    # Full access for development
```

**values-prod.yaml:**
```yaml
policies:
  guest:
    enabled: false   # No guest access in production
  administrator:
    enabled: false   # Restrict admin access in production
```

Deploy with environment-specific values:
```bash
helm install minio-tenant ./chart -f values.yaml -f values-prod.yaml
```

### Conditional PolicyBinding Creation

The templates automatically handle cases where STS is not available:
```yaml
# templates/policybinding.yaml includes checks:
{{- if and .Values.sts.enabled .Values.sts.policyBindingEnabled }}
{{- $stsEnabled := include "tenant.stsEnabled" . }}
{{- if eq $stsEnabled "true" }}
# PolicyBinding resources created here
{{- else }}
# Warning comment about STS not being available
{{- end }}
{{- end }}
```

## Troubleshooting

### Common Issues and Solutions

#### 1. PolicyBinding CRD Not Found
**Error:** `error validating data: ValidationError(PolicyBinding): unknown object type`

**Solution:**
```bash
# Check if STS is enabled in operator
kubectl -n minio-operator set env deployment/minio-operator OPERATOR_STS_ENABLED=on

# Verify CRD exists
kubectl get crd policybindings.sts.min.io

# Wait for operator to restart and register CRD
kubectl -n minio-operator rollout status deployment/minio-operator
```

#### 2. Policy Creation Job Fails
**Error:** Policy setup job fails to connect to MinIO

**Solutions:**
```bash
# Check job logs
kubectl logs job/minio-tenant-policy-setup -n minio-tenant-ns

# Verify tenant is running
kubectl get pods -n minio-tenant-ns

# Check service connectivity
kubectl run debug --image=busybox -n minio-tenant-ns -- sleep 3600
kubectl exec -it debug -n minio-tenant-ns -- nc -z minio-tenant-hl 9000
```

#### 3. Service Account Token Not Working
**Error:** STS token authentication fails

**Solutions:**
```bash
# Verify PolicyBinding exists and is valid
kubectl describe policybinding -n minio-tenant-ns

# Check service account token mounting
kubectl describe sa administrator-sa -n minio-tenant-ns

# Test STS endpoint
kubectl run sts-test --image=curlimages/curl -n minio-tenant-ns -- sleep 3600
kubectl exec -it sts-test -n minio-tenant-ns -- curl -X POST https://sts.minio-tenant-ns.svc.cluster.local:4222/
```

#### 4. Policies Not Applied
**Error:** Service account has access but policies not enforced

**Solutions:**
```bash
# Verify policies were created in MinIO
kubectl exec -it minio-tenant-pool-0-0 -n minio-tenant-ns -- mc admin policy ls minio

# Check policy content
kubectl exec -it minio-tenant-pool-0-0 -n minio-tenant-ns -- mc admin policy info minio administrator-policy

# Verify PolicyBinding is linking correctly
kubectl get policybinding -n minio-tenant-ns -o yaml
```

### Debug Mode Deployment

Enable debug logging for troubleshooting:
```bash
helm install minio-tenant ./chart --debug --dry-run -f values.yaml
```

### Template Testing

Test individual templates:
```bash
# Test specific template
helm template minio-tenant ./chart -s templates/policybinding.yaml -f values.yaml

# Test with different values
helm template minio-tenant ./chart --set sts.enabled=false -f values.yaml
```

## Monitoring and Maintenance

### Health Checks

Create monitoring for policy management:
```yaml
# Add to your monitoring stack
apiVersion: v1
kind: Service
metadata:
  name: policy-health-check
spec:
  selector:
    app.kubernetes.io/component: policy-setup-job
  ports:
  - port: 8080
```

### Policy Updates

To update policies:
1. Modify `values.yaml` policy definitions
2. Run `helm upgrade minio-tenant ./chart -f values.yaml`
3. Policy setup job will recreate policies with new definitions

### Backup and Recovery

Backup policy configurations:
```bash
# Export current policies
kubectl get policybinding -n minio-tenant-ns -o yaml > policy-backup.yaml

# Export service accounts
kubectl get sa -n minio-tenant-ns -o yaml > sa-backup.yaml
```

## Security Best Practices

### 1. Least Privilege Access
- Define minimal required permissions for each role
- Use specific resource ARNs instead of wildcards when possible
- Regular review and audit of policy definitions

### 2. Service Account Security
```yaml
# Disable token auto-mounting for unused service accounts
automountServiceAccountToken: false

# Use specific security contexts
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
```

### 3. Network Policies
```yaml
# Restrict network access between service accounts
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: minio-policy-isolation
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: policy-management
  policyTypes:
  - Ingress
  - Egress
```

### 4. Regular Rotation
- Implement regular service account token rotation
- Monitor and audit policy usage
- Set up alerts for unauthorized access attempts

## Conclusion

This PolicyBinding integration provides a complete solution for managing MinIO policies through Helm chart templates. The approach enables:

- **Declarative policy management** through values.yaml
- **GitOps-ready configuration** with version control
- **Kubernetes-native implementation** using CRDs and service accounts
- **Automated deployment** with policy creation jobs
- **Secure access control** via STS token authentication

The solution addresses the current limitation of MinIO operator not supporting direct policy configuration in Helm values while providing a robust, scalable, and maintainable approach to policy management in production environments.
