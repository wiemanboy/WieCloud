#!/bin/bash
APP_CHART="./wiecloud/chart"
IMAGE_PATH=""
NAME=""
TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      IMAGE_PATH="$2"
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
[[ -z "$IMAGE_PATH" ]] && missing+=("--path")
[[ -z "$NAME" ]] && missing+=("--name")


if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

[ "$TAG" = "-" ] && TAG=""

VERSION=$( yq .version $IMAGE_PATH/Image.yaml )

echo "Setting image version ${VERSION}${TAG} for ${NAME}"

sed -i "/rconcli:/,/version:/ s/^\(\s*version:\s*\).*/\1${VERSION}${TAG}/" $APP_CHART/values.yaml