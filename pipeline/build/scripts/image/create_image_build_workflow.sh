set -e

IMAGE_PATH=""
REGISTRY=""
REPOSITORY=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      IMAGE_PATH="$2"
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
[[ -z "$IMAGE_PATH" ]] && missing+=("--path")
[[ -z "$REGISTRY" ]] && missing+=("--registry")
[[ -z "$REPOSITORY" ]] && missing+=("--repository")


if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

echo "Creating workflow for image at path: ${IMAGE_PATH}"


# Find Image.yaml in the provided image path
IMAGE_YAML="${IMAGE_PATH}/Image.yaml"
if [[ ! -f "$IMAGE_YAML" ]]; then
  echo "Image.yaml not found at $IMAGE_YAML"
  exit 1
fi

# Extract chart name
IMAGE_NAME=$(yq '.name' $IMAGE_YAML )

# Read template and replace placeholders
TEMPLATE_PATH="$(dirname "$0")/image_build_<chart_name>.yaml"
WORKFLOW_PATH=".github/workflows/image_build_${IMAGE_NAME}.yaml"

WORKFLOW_CONTENT=$(cat "$TEMPLATE_PATH" \
  | sed "s|<image_name>|$IMAGE_NAME|g" \
  | sed "s|<image_path>|$IMAGE_PATH|g" \
  | sed "s|<registry>|$REGISTRY|g" \
  | sed "s|<repository>|$REPOSITORY|g" \
)

# Write to workflows directory
mkdir -p .github/workflows
echo "$WORKFLOW_CONTENT" > "$WORKFLOW_PATH"
echo "Workflow created at $WORKFLOW_PATH"
