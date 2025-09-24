#!/bin/bash
set -euo pipefail

# Toolhive MCP Registry - Registry Validation Script
# Validates registry syntax and schema compliance

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Configuration
REGISTRY_FILE="${PROJECT_ROOT}/registry/registry.json"
SCHEMA_FILE="${PROJECT_ROOT}/registry/schemas/schema.json"

echo "🔍 Validating Toolhive MCP Registry..."

# Check if files exist
if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo "❌ Registry file not found: $REGISTRY_FILE"
    exit 1
fi

if [[ ! -f "$SCHEMA_FILE" ]]; then
    echo "❌ Schema file not found: $SCHEMA_FILE"
    exit 1
fi

# Validate JSON syntax
echo "📝 Validating JSON syntax..."
if python3 -m json.tool "$REGISTRY_FILE" > /dev/null; then
    echo "✅ Registry JSON syntax is valid"
else
    echo "❌ Registry JSON syntax is invalid"
    exit 1
fi

# Schema validation (if jsonschema is available)
if command -v jsonschema &> /dev/null; then
    echo "🔍 Validating schema compliance..."
    if jsonschema "$SCHEMA_FILE" -i "$REGISTRY_FILE"; then
        echo "✅ Registry schema validation passed"
    else
        echo "❌ Registry schema validation failed"
        exit 1
    fi
else
    echo "⚠️ jsonschema not available, skipping schema validation"
    echo "   Install with: pip install jsonschema"
fi

# Check registry structure
echo "🏗️ Checking registry structure..."

# Extract server count
SERVER_COUNT=$(jq '.servers | length' "$REGISTRY_FILE")
GROUP_COUNT=$(jq '.groups | length' "$REGISTRY_FILE")

echo "📊 Registry Statistics:"
echo "   - Servers: $SERVER_COUNT"
echo "   - Groups: $GROUP_COUNT"

# Check required fields
REQUIRED_FIELDS=("version" "last_updated" "groups" "servers")
for field in "${REQUIRED_FIELDS[@]}"; do
    if jq -e ".$field" "$REGISTRY_FILE" > /dev/null; then
        echo "✅ Required field '$field' present"
    else
        echo "❌ Required field '$field' missing"
        exit 1
    fi
done

# Check server configurations
echo "🔧 Validating server configurations..."
jq -r '.servers | keys[]' "$REGISTRY_FILE" | while read -r server; do
    echo "  Checking server: $server"
    
    # Check required server fields
    for field in "image" "transport" "status"; do
        if jq -e ".servers.\"$server\".\"$field\"" "$REGISTRY_FILE" > /dev/null; then
            echo "    ✅ $field present"
        else
            echo "    ❌ $field missing"
        fi
    done
done

echo ""
echo "✅ Registry validation complete!"
echo ""
echo "Registry configuration:"
echo "  File: $REGISTRY_FILE"
echo "  Size: $(wc -c < "$REGISTRY_FILE") bytes"
echo "  Servers: $SERVER_COUNT"
echo "  Groups: $GROUP_COUNT"