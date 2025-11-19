CLUSTER_NAME=cluster0
CONTROL_PLANE_ENDPOINT=https://192.168.178.194:6443
TALOS_VERSION=v1.11.5
BARE_METAL_IMAGE_ID=$(curl -X POST --data-binary @bare-metal.yaml https://factory.talos.dev/schematics | jq -r '.id')

sed -i "s/{image_id}/${BARE_METAL_IMAGE_ID}/g; s/{version}/${TALOS_VERSION}/g" bare-metal.config.yaml

talosctl gen config $CLUSTER_NAME $CONTROL_PLANE_ENDPOINT --config-patch @bare-metal.config.yaml --config-patch-control-plane @controlplane.config.yaml --config-patch-worker @worker.config.yaml