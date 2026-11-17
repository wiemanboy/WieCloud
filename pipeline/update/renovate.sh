set -euo pipefail

dirs=()

for dir in {applications,infrastructure,products}/*/{chart,image}; do
  [[ -d "$dir" ]] || continue
  dirs+=("$dir")
done

package_rules=$(jq -n --argjson dirs "$(printf '%s\n' "${dirs[@]}" | jq -R . | jq -s .)" '
[
  $dirs[] as $dir |
  ($dir | split("/") | .[1]) as $name |
  ($dir | split("/") | .[0]) as $project |

  {
    "matchFileNames": ["\($project)/\($name)/**"],
    "matchUpdateTypes": ["patch"],
    "groupName": "\($name) patch",
    "group": { "branchTopic": "\($name)/minor" },
    "bumpVersion": "patch"
  },
  {
    "matchFileNames": ["\($project)/\($name)/**"],
    "matchUpdateTypes": ["minor"],
    "groupName": "\($name) minor",
    "group": { "branchTopic": "\($name)/minor" },
    "bumpVersion": "minor"
  },
  {
    "matchFileNames": ["\($project)/\($name)/**"],
    "matchUpdateTypes": ["major"],
    "groupName": "\($name) major",
    "group": { "branchTopic": "\($name)/major" },
    "bumpVersion": "major"
  }
]
')

echo $package_rules | jq

jq --argjson packageRules "$package_rules" '.packageRules = $packageRules' renovate.json > renovate.json.tmp && \
  mv renovate.json.tmp renovate.json
