set -e

CHART_PATH=""
TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      CHART_PATH="$2"
      shift 2
      ;;
    --tag)
      TAG="-$2"
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

if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi


echo "Building Helm chart at path: ${CHART_PATH}"
cd ${CHART_PATH} || exit 1
yq -i ".version = .version + \"$TAG\"" Chart.yaml

echo "Updating Helm chart dependencies..."
helm dependency list .
helm dependency update . || exit 1

echo
echo "Linting Helm chart..."
helm lint . || exit 1

echo
echo "Packaging Helm chart..."
helm package .
