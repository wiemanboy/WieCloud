set -e

app_chart="./wiecloud/chart"
image_path=""
name=""
tag=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      image_path="$2"
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
[[ -z "$image_path" ]] && missing+=("--path")
[[ -z "$name" ]] && missing+=("--name")


if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

[ "$tag" = "-" ] && tag=""

version=$( yq .version $image_path/Image.yaml )

echo "Setting image version ${version}${tag} for ${name}"

sed -i "/rconcli:/,/version:/ s/^\(\s*version:\s*\).*/\1${version}${tag}/" $app_chart/values.yaml
