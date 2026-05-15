#!/bin/sh
set -e

. deploy/deploy.env

FULL_IMAGE="${HARBOR_REGISTRY}/${IMAGE_NAME}:${TAG}"

SECRETS_JSON="["
first=true
while IFS='=' read -r key value; do
  case "$key" in "#"*|"") continue ;; esac
  $first || SECRETS_JSON="${SECRETS_JSON},"
  SECRETS_JSON="${SECRETS_JSON}{\"name\": \"$key\", \"value\": \"$value\"}"
  first=false
done < deploy/agent.env
SECRETS_JSON="${SECRETS_JSON}]"

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
