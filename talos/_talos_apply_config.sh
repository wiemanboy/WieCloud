DRY_RUN=true
CONTROL_PLANE_IP=""
WORKER_IPS=""
TALOS_VERSION=v1.11.5

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN="$2"
      shift 2
      ;;
    --cp)
      CONTROL_PLANE_IP="$2"
      shift 2
      ;;
    --workers)
      WORKER_IPS="$2"
      shift 2
      ;;
    --version)
      TALOS_VERSION="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

DRY_RUN_TAG=$([[ $DRY_RUN != "false" ]] && echo "--dry-run" || echo "")
IMAGE_ID=$(curl -s -X POST --data-binary @bare-metal.yaml https://factory.talos.dev/schematics | jq -r '.id')

echo "Patching bare-metal config with image id: ${IMAGE_ID} and talos version: ${TALOS_VERSION}"
sed -i "s/{image_id}/${IMAGE_ID}/g; s/{version}/${TALOS_VERSION}/g" bare-metal.config.yaml

talosctl patch machineconfig --talosconfig=./talosconfig -n $WORKER_IPS -p @worker.config.yaml -p @bare-metal.config.yaml $DRY_RUN_TAG
talosctl patch machineconfig --talosconfig=./talosconfig -n $CONTROL_PLANE_IP -p @controlplane.config.yaml -p @bare-metal.config.yaml $DRY_RUN_TAG

sed -i "s/${IMAGE_ID}/{image_id}/g; s/${TALOS_VERSION}/{version}/g" bare-metal.config.yaml
