set -e

# Charts in json format [{path: str, name: str, project: str}]
charts=""
# Images in json format [{path: str, name: str}]
images=""
tag=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --charts)
      charts="$2"
      shift 2
      ;;
    --images)
      images="$2"
      shift 2
      ;;
    --tag)
      tag="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

while read -r chart; do
  chart_path=$(jq -r '.path' <<< "$chart")
  chart_name=$(jq -r '.name' <<< "$chart")
  project=$(jq -r '.project' <<< "$chart")

  echo "$chart_path"
  bash ./pipeline/version/scripts/update_chart_version.sh \
    --path "$chart_path" \
    --project "$project" \
    --name "$chart_name" \
    --tag "$tag" \
    < /dev/null
done < <(jq -c '.[]' <<< "$charts")

while read -r image; do
  image_path=$(jq -r '.path' <<< "$image")
  image_name=$(jq -r '.name' <<< "$image")

  echo "$chart_path"
  bash ./pipeline/version/scripts/update_image_version.sh \
    --path "$image_path" \
    --name "$image_name" \
    --tag "$tag" \
    < /dev/null
done < <(jq -c '.[]' <<< "$images")
