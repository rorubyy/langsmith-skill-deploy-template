#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/deploy.env"

FULL_IMAGE="${HARBOR_REGISTRY}/${IMAGE_NAME}:${TAG}"

SECRETS_JSON="["
first=true
while IFS='=' read -r key value; do
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
  $first || SECRETS_JSON+=","
  SECRETS_JSON+="{\"name\": \"$key\", \"value\": \"$value\"}"
  first=false
done < "$SCRIPT_DIR/agent.env"
SECRETS_JSON+="]"

cd "$PROJECT_ROOT"

echo "▶ [1/3] Build: ${FULL_IMAGE}"
langgraph build -t "${FULL_IMAGE}" --no-cache

echo "▶ [2/3] Push to Harbor"
docker push "${FULL_IMAGE}"

echo "▶ [3/3] Update deployment: ${DEPLOYMENT_ID}"
curl -sf -X PATCH "${LANGSMITH_HOST}/api-host/v2/deployments/${DEPLOYMENT_ID}" \
  -H "X-Api-Key: ${LANGSMITH_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"source_revision_config\": {\"image_uri\": \"${FULL_IMAGE}\"},
    \"secrets\": ${SECRETS_JSON}
  }"

echo "✅ Done: ${FULL_IMAGE}"
