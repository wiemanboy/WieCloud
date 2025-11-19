DRY_RUN=${1:-true}
DRY_RUN_TAG=$([[ $DRY_RUN == "true" ]] && echo "--dry-run" || echo "")

CONTROL_PLANE_IP=192.168.178.194

TALOS_VERSION=v1.11.5
BARE_METAL_IMAGE_ID=$(curl -s -X POST --data-binary @bare-metal.yaml https://factory.talos.dev/schematics | jq -r '.id')

echo "Patching bare-metal config with image id: ${BARE_METAL_IMAGE_ID} and talos version: ${TALOS_VERSION}"
sed -i "s/{image_id}/${BARE_METAL_IMAGE_ID}/g; s/{version}/${TALOS_VERSION}/g" bare-metal.config.yaml

talosctl patch machineconfig --talosconfig=./talosconfig -n $CONTROL_PLANE_IP -p @controlplane.config.yaml -p @worker.config.yaml -p @bare-metal.config.yaml $DRY_RUN_TAG

sed -i "s/${BARE_METAL_IMAGE_ID}/{image_id}/g; s/${TALOS_VERSION}/{version}/g" bare-metal.config.yaml
