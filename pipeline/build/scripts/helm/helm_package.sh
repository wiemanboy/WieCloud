set -e

chart_path=""
tag=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      chart_path="$2"
      shift 2
      ;;
    --tag)
      tag="-$2"
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

if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi


echo "Building Helm chart at path: ${chart_path}"
cd ${chart_path} || exit 1
yq -i ".version = .version + \"$tag\"" Chart.yaml

echo "Updating Helm chart dependencies..."
helm dependency list .
helm dependency update . || exit 1

echo
echo "Linting Helm chart..."
helm lint . || exit 1

echo
echo "Packaging Helm chart..."
helm package .
