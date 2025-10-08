#!/bin/bash

# S3 Migration Script
# This script configures MinIO client aliases and migrates data from acme-legacy to acme-mkpl
# by mirroring each bucket listed in buckets_list.txt

set -e

# Configuration
SOURCE_ALIAS="acme-legacy"
TARGET_ALIAS="acme-mkpl"
BUCKET_LIST_FILE="buckets_list.txt"

# MinIO endpoints and credentials
LEGACY_ENDPOINT="https://s3.acme.com"
LEGACY_ACCESS_KEY="XXXXXXXXXXXXX"
LEGACY_SECRET_KEY="XXXXXXXXXXXXX"

MKPL_ENDPOINT="https://s3-mkpl.acme.com"
MKPL_ACCESS_KEY="XXXXXXXXXXXXX"
MKPL_SECRET_KEY="XXXXXXXXXXXXX"

# Function to configure alias
configure_alias() {
    local alias_name=$1
    local endpoint=$2
    local access_key=$3
    local secret_key=$4

    echo "Configuring alias: $alias_name"
    mc alias set "$alias_name" "$endpoint" "$access_key" "$secret_key"

    # Test the connection
    if mc admin info "$alias_name" &> /dev/null; then
        echo "✓ Successfully configured and tested alias: $alias_name"
    else
        echo "✗ Failed to connect to $alias_name. Please check your credentials."
        return 1
    fi
}

# Install and configure MinIO client
setup_minio_client() {
    echo "Setting up MinIO client..."

    # Install mc client if not already installed
    if ! command -v mc &> /dev/null; then
        echo "Installing MinIO client (mc)..."
        wget https://dl.min.io/client/mc/release/linux-amd64/mc
        cp mc /usr/local/bin
        chmod +x /usr/local/bin/mc
        echo "✓ Successfully installed MinIO client (mc)"
    else
        echo "MinIO client (mc) is already installed."
    fi

    # Configure source alias (acme-legacy)
    echo "Configuring source MinIO alias (acme-legacy)..."
    configure_alias "$SOURCE_ALIAS" "$LEGACY_ENDPOINT" "$LEGACY_ACCESS_KEY" "$LEGACY_SECRET_KEY"

    # Configure target alias (acme-mkpl)
    echo "Configuring target MinIO alias (acme-mkpl)..."
    configure_alias "$TARGET_ALIAS" "$MKPL_ENDPOINT" "$MKPL_ACCESS_KEY" "$MKPL_SECRET_KEY"

    echo "✓ MinIO client aliases configured successfully!"
}

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    # Check if bucket list file exists
    if [[ ! -f "$BUCKET_LIST_FILE" ]]; then
        echo "Error: Bucket list file '$BUCKET_LIST_FILE' not found."
        exit 1
    fi

    echo "✓ All prerequisites checked successfully"
}

# Function to extract bucket name from the list file
extract_bucket_name() {
    local line=$1
    # Extract bucket name after the arrow (→)
    echo "$line" | sed 's/.*→//'
}

# Function to check if bucket exists
bucket_exists() {
    local alias=$1
    local bucket=$2
    mc ls "$alias/$bucket" &> /dev/null
}

# Function to create bucket if it doesn't exist
create_bucket_if_not_exists() {
    local alias=$1
    local bucket=$2

    if ! bucket_exists "$alias" "$bucket"; then
        echo "Creating bucket: $alias/$bucket"
        if mc mb "$alias/$bucket"; then
            echo "✓ Created bucket: $alias/$bucket"
        else
            echo "✗ Failed to create bucket: $alias/$bucket"
            return 1
        fi
    else
        echo "Bucket already exists: $alias/$bucket"
    fi
}

# Function to migrate a single bucket
migrate_bucket() {
    local bucket_name=$1
    local source_path="$SOURCE_ALIAS/$bucket_name"
    local target_path="$TARGET_ALIAS/$bucket_name"

    echo "Starting migration of bucket: $bucket_name"

    # Check if source bucket exists
    if ! bucket_exists "$SOURCE_ALIAS" "$bucket_name"; then
        echo "⚠ Source bucket does not exist: $source_path"
        return 0
    fi

    # Create target bucket if it doesn't exist
    if ! create_bucket_if_not_exists "$TARGET_ALIAS" "$bucket_name"; then
        return 1
    fi

    # Perform the mirror operation
    echo "Mirroring data from $source_path to $target_path"
    if mc mirror "$source_path" "$target_path" --overwrite; then
        echo "✓ Successfully migrated bucket: $bucket_name"
        return 0
    else
        echo "✗ Failed to migrate bucket: $bucket_name"
        return 1
    fi
}

# Main migration function
run_migration() {
    echo "=== Starting S3 Migration ==="

    check_prerequisites

    # Initialize counters
    local total_buckets=0
    local successful_migrations=0
    local failed_migrations=0

    # Read bucket list and migrate each bucket
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        bucket_name=$(extract_bucket_name "$line")

        # Skip if we couldn't extract a bucket name
        if [[ -z "$bucket_name" ]]; then
            echo "⚠ Could not extract bucket name from line: $line"
            continue
        fi

        echo "--- Processing bucket $total_buckets: $bucket_name ---"

        total_buckets=$((total_buckets + 1))

        if migrate_bucket "$bucket_name"; then
           successful_migrations=$((successful_migrations + 1))
        else
           failed_migrations=$((failed_migrations + 1))
        fi

        echo "" # Add blank line for readability

    done < "$BUCKET_LIST_FILE"

    # Print summary
    echo "=== Migration Summary ==="
    echo "Total buckets processed: $total_buckets"
    echo "Successful migrations: $successful_migrations"

    if [[ $failed_migrations -gt 0 ]]; then
        echo "Failed migrations: $failed_migrations"
        exit 1
    else
        echo "✓ All migrations completed successfully!"
    fi
}

# Handle script interruption
trap 'echo "Migration interrupted by user"; exit 130' INT TERM

# Show usage if help is requested
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script sets up MinIO client and migrates all buckets listed in $BUCKET_LIST_FILE"
    echo "from $SOURCE_ALIAS to $TARGET_ALIAS using MinIO client mirror command."
    echo ""
    echo "Options:"
    echo "  --setup-only     Only configure MinIO client aliases, don't run migration"
    echo "  --migrate-only   Only run migration (assumes aliases are already configured)"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Prerequisites:"
    echo "  1. Ensure $BUCKET_LIST_FILE exists in the current directory"
    echo ""
    echo "The script will automatically:"
    echo "  1. Install MinIO client (mc) if not present"
    echo "  2. Configure acme-legacy and acme-mkpl aliases"
    echo "  3. Migrate all buckets from source to target"
    exit 0
fi

# Main execution
main() {
    case "${1:-}" in
        "--setup-only")
            setup_minio_client
            echo "Setup completed. You can now run migration with --migrate-only"
            ;;
        "--migrate-only")
            echo "Running migration only (assuming aliases are configured)..."
            run_migration
            ;;
        *)
            # Default: setup and migrate
            setup_minio_client
            echo ""
            run_migration
            ;;
    esac
}

# Run the main function
main "$@"
