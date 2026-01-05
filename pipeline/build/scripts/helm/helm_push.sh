#!/bin/bash
set -e

PACKAGE=""
REGISTRY=""
REPOSITORY=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --package)
      PACKAGE="$2"
      shift 2
      ;;
    --registry)
      REGISTRY="$2"
      shift 2
      ;;
    --repository)
      REPOSITORY="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

missing=()
[[ -z "$PACKAGE" ]] && missing+=("--package")
[[ -z "$REGISTRY" ]] && missing+=("--registry")
[[ -z "$REPOSITORY" ]] && missing+=("--repository")

if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

echo "Pushing Helm chart package: ${REGISTRY}/${REPOSITORY}/${PACKAGE}"
helm push $PACKAGE $REGISTRY/$REPOSITORY