DRY_RUN=${1:-true}
DRY_RUN_TAG=$([[ $DRY_RUN == "true" ]] && echo "--dry-run" || echo "")

CLUSTER_NAME=homelab

CONTROL_PLANE_IP=192.168.178.194
CONTROL_PLANE_ENDPOINT=https://$CONTROL_PLANE_IP:6443

talosctl gen config $CLUSTER_NAME $CONTROL_PLANE_ENDPOINT --config-patch-control-plane @controlplane.config.yaml --config-patch-worker @worker.config.yaml || exit

talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file controlplane.yaml $DRY_RUN_TAG

if [[ $DRY_RUN == "true" ]]; then
  exit
fi

talosctl --talosconfig=./talosconfig config endpoints $CONTROL_PLANE_IP

echo "NEXT STEP: run setup_k8s.sh to bootstrap the cluster"