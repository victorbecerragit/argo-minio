#!/bin/bash
set -e

# MinIO PolicyBinding Testing Script
NAMESPACE="minio-tenant-ns"
TENANT_NAME="minio-tenant"

echo "🧪 MinIO PolicyBinding Testing"
echo "=============================="

# Test each service account
ROLES=("administrator" "auditor" "datalake-admin" "datalake-viewer" "guest")

for ROLE in "${ROLES[@]}"; do
    SA_NAME="${ROLE}-sa"

    echo ""
    echo "🔍 Testing $ROLE role (Service Account: $SA_NAME)"
    echo "------------------------------------------------"

    # Check if service account exists
    if kubectl get sa $SA_NAME -n $NAMESPACE &> /dev/null; then
        echo "✅ Service Account $SA_NAME exists"
    else
        echo "❌ Service Account $SA_NAME not found"
        continue
    fi

    # Check if PolicyBinding exists
    BINDING_NAME="${ROLE}-binding"
    if kubectl get policybinding $BINDING_NAME -n $NAMESPACE &> /dev/null; then
        echo "✅ PolicyBinding $BINDING_NAME exists"
    else
        echo "⚠️  PolicyBinding $BINDING_NAME not found"
    fi

    # Create test pod with service account
    TEST_POD="test-${ROLE}"

    echo "🚀 Creating test pod with $SA_NAME..."
    kubectl run $TEST_POD --image=minio/mc:latest --serviceaccount=$SA_NAME -n $NAMESPACE -- sleep 300

    # Wait for pod to be ready
    kubectl wait --for=condition=ready pod/$TEST_POD -n $NAMESPACE --timeout=60s

    # Test MinIO access
    echo "🔐 Testing MinIO access..."
    if kubectl exec $TEST_POD -n $NAMESPACE -- mc alias set test-minio https://${TENANT_NAME}-hl:9000 --no-color &> /dev/null; then
        echo "✅ MinIO connection successful"

        # Test list buckets (should work for most roles)
        if kubectl exec $TEST_POD -n $NAMESPACE -- mc ls test-minio/ --no-color &> /dev/null; then
            echo "✅ List buckets: ALLOWED"
        else
            echo "❌ List buckets: DENIED"
        fi

        # Test bucket creation (should work for admin roles)
        if kubectl exec $TEST_POD -n $NAMESPACE -- mc mb test-minio/test-bucket-${ROLE} --no-color &> /dev/null; then
            echo "✅ Create bucket: ALLOWED"

            # Clean up test bucket
            kubectl exec $TEST_POD -n $NAMESPACE -- mc rb test-minio/test-bucket-${ROLE} --no-color &> /dev/null || true
        else
            echo "ℹ️  Create bucket: DENIED (expected for read-only roles)"
        fi

    else
        echo "❌ MinIO connection failed"
    fi

    # Clean up test pod
    kubectl delete pod $TEST_POD -n $NAMESPACE --ignore-not-found=true

    echo "🧹 Test pod cleaned up"
done

echo ""
echo "📊 Test Summary"
echo "==============="
echo "✅ PolicyBinding testing completed"
echo ""
echo "💡 Tips:"
echo "- Check PolicyBinding status: kubectl describe policybinding -n $NAMESPACE"
echo "- View MinIO policies: kubectl exec -it ${TENANT_NAME}-pool-0-0 -n $NAMESPACE -- mc admin policy ls minio"
echo "- Debug access issues: kubectl logs job/${TENANT_NAME}-policy-setup -n $NAMESPACE"
