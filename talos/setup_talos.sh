DRY_RUN=${1:-true}
SECURE=${2:-true}

CLUSTER_NAME=homelab

CONTROL_PLANE_IP=192.168.178.194
CONTROL_PLANE_ENDPOINT=https://$CONTROL_PLANE_IP:6443

talosctl gen config $CLUSTER_NAME $CONTROL_PLANE_ENDPOINT --config-patch-control-plane @controlplane.config.yaml --config-patch-worker @worker.config.yaml || exit

if [[ $DRY_RUN == "true" ]]; then
  talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file controlplane.yaml --dry-run
  exit
fi

talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file controlplane.yaml
talosctl --talosconfig=./talosconfig config endpoints $CONTROL_PLANE_IP