#!/bin/bash
set -e

# MinIO Tenant PolicyBinding Deployment Script
# This script helps deploy a MinIO tenant with PolicyBinding support

CHART_DIR="./minio-tenant-chart"
RELEASE_NAME="minio-tenant"
NAMESPACE="minio-tenant-ns"
VALUES_FILE="values.yaml"

echo "🚀 MinIO Tenant PolicyBinding Deployment"
echo "========================================="

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ helm not found. Please install Helm 3.8+."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot access Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Check MinIO Operator
echo "🔍 Checking MinIO Operator..."
if kubectl get deployment -n minio-operator minio-operator &> /dev/null; then
    echo "✅ MinIO Operator found"

    # Check STS status
    STS_STATUS=$(kubectl -n minio-operator get deployment minio-operator -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="OPERATOR_STS_ENABLED")].value}' 2>/dev/null || echo "not-set")

    if [ "$STS_STATUS" = "on" ]; then
        echo "✅ STS is enabled in MinIO Operator"
    else
        echo "⚠️  STS not enabled. Enabling now..."
        kubectl -n minio-operator set env deployment/minio-operator OPERATOR_STS_ENABLED=on
        echo "⏳ Waiting for operator to restart..."
        kubectl -n minio-operator rollout status deployment/minio-operator --timeout=300s
        echo "✅ STS enabled successfully"
    fi
else
    echo "❌ MinIO Operator not found. Please install MinIO Operator first:"
    echo "   helm repo add minio-operator https://operator.min.io"
    echo "   helm install minio-operator minio-operator/operator --namespace minio-operator --create-namespace"
    exit 1
fi

# Check PolicyBinding CRD
echo "🔍 Checking PolicyBinding CRD..."
if kubectl get crd policybindings.sts.min.io &> /dev/null; then
    echo "✅ PolicyBinding CRD is available"
else
    echo "⚠️  PolicyBinding CRD not found. Waiting for operator to register it..."
    sleep 10
    if kubectl get crd policybindings.sts.min.io &> /dev/null; then
        echo "✅ PolicyBinding CRD is now available"
    else
        echo "❌ PolicyBinding CRD still not available. Check operator logs:"
        echo "   kubectl logs -n minio-operator deployment/minio-operator"
        exit 1
    fi
fi

# Validate chart
echo "📊 Validating Helm chart..."
if [ ! -d "$CHART_DIR" ]; then
    echo "❌ Chart directory $CHART_DIR not found"
    exit 1
fi

if [ ! -f "$CHART_DIR/$VALUES_FILE" ]; then
    echo "❌ Values file $CHART_DIR/$VALUES_FILE not found"
    exit 1
fi

# Dry run
echo "🧪 Running dry-run validation..."
if helm install $RELEASE_NAME $CHART_DIR --dry-run --debug -f $CHART_DIR/$VALUES_FILE -n $NAMESPACE &> /tmp/helm-dry-run.log; then
    echo "✅ Dry-run validation passed"
else
    echo "❌ Dry-run validation failed. Check logs:"
    cat /tmp/helm-dry-run.log
    exit 1
fi

# Create namespace if it doesn't exist
echo "📁 Preparing namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace $NAMESPACE ready"

# Deploy the chart
echo "🚀 Deploying MinIO Tenant with PolicyBinding..."
if helm install $RELEASE_NAME $CHART_DIR -n $NAMESPACE -f $CHART_DIR/$VALUES_FILE; then
    echo "✅ Deployment initiated successfully"
else
    echo "❌ Deployment failed"
    exit 1
fi

# Wait for tenant to be ready
echo "⏳ Waiting for MinIO Tenant to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=minio-tenant -n $NAMESPACE --timeout=600s

# Check policy job
echo "🔍 Checking policy setup job..."
if kubectl get job/${RELEASE_NAME}-policy-setup -n $NAMESPACE &> /dev/null; then
    kubectl wait --for=condition=complete job/${RELEASE_NAME}-policy-setup -n $NAMESPACE --timeout=300s
    echo "✅ Policy setup completed successfully"

    # Show job logs
    echo "📋 Policy setup logs:"
    kubectl logs job/${RELEASE_NAME}-policy-setup -n $NAMESPACE
else
    echo "⚠️  Policy setup job not found"
fi

# Verify PolicyBindings
echo "🔍 Verifying PolicyBinding resources..."
POLICY_BINDINGS=$(kubectl get policybinding -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
if [ $POLICY_BINDINGS -gt 0 ]; then
    echo "✅ Found $POLICY_BINDINGS PolicyBinding resources:"
    kubectl get policybinding -n $NAMESPACE
else
    echo "⚠️  No PolicyBinding resources found. Check if STS is properly enabled."
fi

# Show service accounts
echo "👥 Available Service Accounts:"
kubectl get sa -n $NAMESPACE | grep -E "(administrator|auditor|datalake|guest)"

# Final status
echo ""
echo "🎉 Deployment Summary"
echo "===================="
echo "✅ MinIO Tenant: $RELEASE_NAME deployed in namespace $NAMESPACE"
echo "✅ STS: Enabled"
echo "✅ PolicyBindings: $POLICY_BINDINGS created"
echo ""
echo "📚 Next Steps:"
echo "1. Check deployment status: kubectl get all -n $NAMESPACE"
echo "2. View notes: helm get notes $RELEASE_NAME -n $NAMESPACE"
echo "3. Test access with service accounts"
echo ""
echo "🔧 Troubleshooting:"
echo "- Check logs: kubectl logs -l app.kubernetes.io/name=minio-tenant -n $NAMESPACE"
echo "- Policy job logs: kubectl logs job/${RELEASE_NAME}-policy-setup -n $NAMESPACE"
echo "- PolicyBinding status: kubectl describe policybinding -n $NAMESPACE"
