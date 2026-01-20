set -e

image_path=""
tag=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      image_path="$2"
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

if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

image_name=$(yq '.name' "$image_path/Image.yaml")
image_version=$(yq '.version' "$image_path/Image.yaml")

image_tag="${image_version}${tag}"

echo "Building docker image: $image_name:$image_tag"
docker build $image_path --tag $image_name:$image_tag
