set -e

# Find all matching Chart.yaml files
find applications infrastructure -type f -path '*/chart/Chart.yaml' | while read -r chart; do
  # Extract current version (assumes "version: x.y.z")
  version=$(sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' "$chart")

  if [ -z "$version" ]; then
    echo "Skipping $chart (no version found)"
    continue
  fi

  IFS='.' read -r major minor patch <<< "$version"
  new_version="${major}.${minor}.$((patch + 1))"

  # Replace version using sed
  sed -i.bak -E "s/^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+/version: ${new_version}/" "$chart"
  rm -f "${chart}.bak"

  echo "Bumped $chart: $version → $new_version"
done
