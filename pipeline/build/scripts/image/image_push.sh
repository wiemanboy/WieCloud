set -e

image=""
registry=""
repository=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --image)
      image="$2"
      shift 2
      ;;
    --registry)
      registry="$2"
      shift 2
      ;;
    --repository)
      repository="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

missing=()
[[ -z "$image" ]] && missing+=("--image")
[[ -z "$registry" ]] && missing+=("--registry")
[[ -z "$repository" ]] && missing+=("--repository")

if [ ${#missing[@]} -ne 0 ]; then
  echo "Error: Missing required parameter(s): ${missing[*]}"
  exit 1
fi

echo "Pushing docker image: ${registry}/${repository}/${image}"
docker tag $image "${registry}/${repository}/${image}"
docker push "${registry}/${repository}/${image}"
