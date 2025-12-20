#!/bin/bash
CHART_PATH=""
REGISTRY=""
REPOSITORY=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      CHART_PATH="$2"
      shift 2
      ;;
    --registry)
      REGISTRY="$2"
      shift 2
      ;;
    --repository)
      REPOSITORY="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

missing=()
[[ -z "$CHART_PATH" ]] && missing+=("--path")
[[ -z "$REGISTRY" ]] && missing+=("--registry")
[[ -z "$REPOSITORY" ]] && missing+=("--repository")


if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

echo "Creating workflow for Helm chart at path: ${CHART_PATH}"


# Find Chart.yaml in the provided chart path
CHART_YAML="${CHART_PATH}/Chart.yaml"
if [[ ! -f "$CHART_YAML" ]]; then
  echo "Chart.yaml not found at $CHART_YAML"
  exit 1
fi

# Extract chart name
CHART_NAME=$(yq '.name' $CHART_YAML )

# Read template and replace placeholders
TEMPLATE_PATH="$(dirname "$0")/build_<chart_name>.yaml"
WORKFLOW_PATH=".github/workflows/build_${CHART_NAME}.yaml"

WORKFLOW_CONTENT=$(cat "$TEMPLATE_PATH" \
  | sed "s|<chart_name>|$CHART_NAME|g" \
  | sed "s|<chart_path>|$CHART_PATH|g" \
  | sed "s|<registry>|$REGISTRY|g" \
  | sed "s|<repository>|$REPOSITORY|g" \
)

# Write to workflows directory
mkdir -p .github/workflows
echo "$WORKFLOW_CONTENT" > "$WORKFLOW_PATH"
echo "Workflow created at $WORKFLOW_PATH"
