set -e

# Find all Chart.yaml and Image.yaml files
find applications infrastructure -type f \( \
  -path '*/chart/Chart.yaml' -o \
  -path '*/image/Image.yaml' \
\) | while read -r file; do

  # Extract current version (assumes "version: x.y.z")
  version=$(sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' "$file")

  if [ -z "$version" ]; then
    echo "Skipping $file (no version found)"
    continue
  fi

  IFS='.' read -r major minor patch <<< "$version"
  new_version="${major}.${minor}.$((patch + 1))"

  sed -i -E "s/^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+/version: ${new_version}/" "$file"

  echo "Bumped $file: $version → $new_version"
done
