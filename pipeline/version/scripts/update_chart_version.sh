set -e

APP_CHART="./wiecloud/chart"
CHART_PATH=""
NAME=""
TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      CHART_PATH="$2"
      shift 2
      ;;
    --name)
      NAME="$2"
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
[[ -z "$NAME" ]] && missing+=("--name")


if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

[ "$TAG" = "-" ] && TAG=""

VERSION=$( yq .version $CHART_PATH/Chart.yaml )

echo "Setting chart version ${VERSION}${TAG} for ${NAME}"

sed -i "/${NAME}:/,/version:/ s/^\(\s*version:\s*\).*/\1${VERSION}${TAG}/" $APP_CHART/values.yaml
