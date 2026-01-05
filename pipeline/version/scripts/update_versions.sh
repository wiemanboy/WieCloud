#!/bin/bash
set -e

TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --tag)
      TAG="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

DIFF=$(git diff FETCH_HEAD...HEAD --name-only | grep -E '^(infrastructure|applications)/.*/chart/' || exit 0)
EDITED_CHARTS=$(printf '%s\n' "$DIFF"| sed 's|\(.*\/chart\)/.*|\1|' | sort -u)

while read -r CHART_PATH; do
  IFS='/' read -r _ CHART_NAME _ <<< "$CHART_PATH"

  echo $CHART_PATH
bash ./pipeline/version/scripts/update_chart_version.sh \
  --path "$CHART_PATH" \
  --name "$CHART_NAME" \
  --tag "$TAG" \
  < /dev/null
done <<< "$EDITED_CHARTS"

echo "all charts edited"

DIFF=$(git diff FETCH_HEAD...HEAD --name-only | grep -E '^(infrastructure|applications)/.*/image/' || exit 0)

echo $DIFF

EDITED_IMAGES=$(printf '%s\n' "$DIFF"| sed 's|\(.*\/image\)/.*|\1|' | sort -u)

echo $EDITED_IMAGES

while read -r IMAGE_PATH; do
  IFS='/' read -r -a PARTS <<< "$IMAGE_PATH"
  IMAGE_NAME="${PARTS[-1]}"

  echo $IMAGE_PATH
bash ./pipeline/version/scripts/update_image_version.sh \
  --path "$IMAGE_PATH" \
  --name "$IMAGE_NAME" \
  --tag "$TAG" \
  < /dev/null
done <<< "$EDITED_IMAGES"