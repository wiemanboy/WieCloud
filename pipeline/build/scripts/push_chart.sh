#!/bin/bash
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
      REGISTRY="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

echo "Pushing Helm chart package: ${REGISTRY}/${REPOSITORY}/${PACKAGE}"
helm push $PACKAGE $REGISTRY/$REPOSITORY