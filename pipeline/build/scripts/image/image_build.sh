#!/bin/bash
set -e

IMAGE_PATH=""
TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --path)
      IMAGE_PATH="$2"
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

if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

IMAGE_NAME=$(yq '.name' "$IMAGE_PATH/Image.yaml")
IMAGE_VERSION=$(yq '.version' "$IMAGE_PATH/Image.yaml")

IMAGE_TAG="${IMAGE_VERSION}${TAG}"

echo "Building docker image: $IMAGE_NAME:$IMAGE_TAG"
docker build $IMAGE_PATH --tag $IMAGE_NAME:$IMAGE_TAG