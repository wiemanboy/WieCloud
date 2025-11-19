DRY_RUN=${1:-true}

CONTROL_PLANE_IP=192.168.178.194

TALOS_VERSION=v1.11.5
BARE_METAL_IMAGE_ID=$(curl -s -X POST --data-binary @bare-metal.yaml https://factory.talos.dev/schematics | jq -r '.id')

sed -i "s/{image_id}/${BARE_METAL_IMAGE_ID}/g; s/{version}/${TALOS_VERSION}/g" bare-metal.config.yaml

if [[ $DRY_RUN == "true" ]]; then
  talosctl patch machineconfig --talosconfig=./talosconfig -n $CONTROL_PLANE_IP -p @controlplane.config.yaml -p @worker.config.yaml -p @bare-metal.config.yaml --dry-run
  exit
fi

talosctl patch machineconfig -n $CONTROL_PLANE_IP -p @controlplane.config.yaml -p @worker.config.yaml -p @bare-metal.config.yaml 
