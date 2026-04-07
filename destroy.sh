#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "This will destroy ALL resources. Ctrl+C to cancel."
echo ""
terraform destroy
