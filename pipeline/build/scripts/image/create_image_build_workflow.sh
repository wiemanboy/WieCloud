set -e

image_path=""
registry=""
repository=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      image_path="$2"
      shift 2
      ;;
    --registry)
      registry="$2"
      shift 2
      ;;
    --repository)
      repository="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

missing=()
[[ -z "$image_path" ]] && missing+=("--path")
[[ -z "$registry" ]] && missing+=("--registry")
[[ -z "$repository" ]] && missing+=("--repository")


if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

echo "Creating workflow for image at path: ${image_path}"


# Find Image.yaml in the provided image path
image_yaml="${image_path}/Image.yaml"
if [[ ! -f "$image_yaml" ]]; then
  echo "Image.yaml not found at $image_yaml"
  exit 1
fi

# Extract image name
image_name=$(yq '.name' $image_yaml )

# Read template and replace placeholders
template_path="$(dirname "$0")/image_build_<image_name>.yaml"
workflow_path=".github/workflows/image_build_${image_name}.yaml"

workflow_content=$(cat "$template_path" \
  | sed "s|<image_name>|$image_name|g" \
  | sed "s|<image_path>|$image_path|g" \
  | sed "s|<registry>|$registry|g" \
  | sed "s|<repository>|$repository|g" \
)

# Write to workflows directory
mkdir -p .github/workflows
echo "$workflow_content" > "$workflow_path"
echo "Workflow created at $workflow_path"
