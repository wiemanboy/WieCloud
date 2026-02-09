set -e

tag=""

while [[ $# -gt 0 ]]; do
  case $1 in
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

diff=$(git diff FETCH_HEAD...HEAD --name-only | grep -E '^(infrastructure|applications)/.*/chart/') || exit 0
edited_charts=$(printf '%s\n' "$diff"| sed 's|\(.*\/chart\)/.*|\1|' | sort -u)

while read -r chart_path; do
  IFS='/' read -r _ chart_name _ <<< "$chart_path"

  echo $chart_path
bash ./pipeline/version/scripts/update_chart_version.sh \
  --path "$chart_path" \
  --name "$chart_name" \
  --tag "$tag" \
  < /dev/null
done <<< "$edited_charts"

diff=$(git diff FETCH_HEAD...HEAD --name-only | grep -E '^(infrastructure|applications)/.*/image/') || exit 0
edited_images=$(printf '%s\n' "$diff"| sed 's|\(.*\/image\)/.*|\1|' | sort -u)

while read -r image_path; do
  IFS='/' read -r -a PARTS <<< "$image_path"
  image_name="${PARTS[-1]}"

  echo $image_path
bash ./pipeline/version/scripts/update_image_version.sh \
  --path "$image_path" \
  --name "$image_name" \
  --tag "$tag" \
  < /dev/null
done <<< "$edited_images"
