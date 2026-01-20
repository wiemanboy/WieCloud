set -e

app_chart="./wiecloud/chart"
chart_path=""
name=""
tag=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      chart_path="$2"
      shift 2
      ;;
    --name)
      name="$2"
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
[[ -z "$name" ]] && missing+=("--name")


if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

[ "$tag" = "-" ] && tag=""

version=$( yq .version $chart_path/Chart.yaml )

echo "Setting chart version ${version}${tag} for ${name}"

sed -i "/${name}:/,/version:/ s/^\(\s*version:\s*\).*/\1${version}${tag}/" $app_chart/values.yaml
