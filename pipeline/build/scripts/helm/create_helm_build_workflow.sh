set -e

chart_path=""
registry=""
repository=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      chart_path="$2"
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
[[ -z "$chart_path" ]] && missing+=("--path")
[[ -z "$registry" ]] && missing+=("--registry")
[[ -z "$repository" ]] && missing+=("--repository")


if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

echo "Creating workflow for Helm chart at path: ${chart_path}"


# Find Chart.yaml in the provided chart path
chart_yaml="${chart_path}/Chart.yaml"
if [[ ! -f "$chart_yaml" ]]; then
  echo "Chart.yaml not found at $chart_yaml"
  exit 1
fi

# Extract chart name
chart_name=$(yq '.name' $chart_yaml )

# Read template and replace placeholders
template_path="$(dirname "$0")/helm_build_<chart_name>.yaml"
workflow_path=".github/workflows/helm_build_${chart_name}.yaml"

workflow_content=$(cat "$template_path" \
  | sed "s|<chart_name>|$chart_name|g" \
  | sed "s|<chart_path>|$chart_path|g" \
  | sed "s|<registry>|$registry|g" \
  | sed "s|<repository>|$repository|g" \
)

# Write to workflows directory
mkdir -p .github/workflows
echo "$workflow_content" > "$workflow_path"
echo "Workflow created at $workflow_path"
