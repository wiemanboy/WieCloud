#!/bin/bash
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

DIFF=$(git diff master --name-only | grep -E '^(infrastructure|applications)/.*/chart/')
EDITED=$(printf '%s\n' "$DIFF"| sed 's|\(.*\/chart\)/.*|\1|' | sort -u)

while read -r CHART_PATH; do
  IFS='/' read -r PROJECT CHART_NAME _ <<< "$CHART_PATH"

  echo $CHART_PATH
bash ./pipeline/version/scripts/update_version.sh \
  --path "$CHART_PATH" \
  --project "$PROJECT" \
  --name "$CHART_NAME" \
  --tag "$TAG" \
  < /dev/null
done <<< "$EDITED"