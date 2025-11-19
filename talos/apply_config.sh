DRY_RUN=true
CONTROL_PLANE_IP=192.168.178.194

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN="$2"
      shift 2
      ;;
    --ip)
      CONTROL_PLANE_IP="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

DRY_RUN_TAG=$([[ $DRY_RUN != "false" ]] && echo "--dry-run" || echo "")


TALOS_VERSION=v1.11.5
BARE_METAL_IMAGE_ID=$(curl -s -X POST --data-binary @bare-metal.yaml https://factory.talos.dev/schematics | jq -r '.id')

echo "Patching bare-metal config with image id: ${BARE_METAL_IMAGE_ID} and talos version: ${TALOS_VERSION}"
sed -i "s/{image_id}/${BARE_METAL_IMAGE_ID}/g; s/{version}/${TALOS_VERSION}/g" bare-metal.config.yaml

talosctl patch machineconfig --talosconfig=./talosconfig -n $CONTROL_PLANE_IP -p @controlplane.config.yaml -p @worker.config.yaml -p @bare-metal.config.yaml $DRY_RUN_TAG

sed -i "s/${BARE_METAL_IMAGE_ID}/{image_id}/g; s/${TALOS_VERSION}/{version}/g" bare-metal.config.yaml
