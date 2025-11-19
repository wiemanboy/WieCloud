DRY_RUN=true
CONTROL_PLANE_IP=192.168.178.194
CLUSTER_NAME=homelab

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
CONTROL_PLANE_ENDPOINT=https://$CONTROL_PLANE_IP:6443

talosctl gen config $CLUSTER_NAME $CONTROL_PLANE_ENDPOINT --config-patch-control-plane @controlplane.config.yaml --config-patch-worker @worker.config.yaml || exit

talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file controlplane.yaml $DRY_RUN_TAG

if [[ $DRY_RUN == "true" ]]; then
  exit
fi

talosctl --talosconfig=./talosconfig config endpoints $CONTROL_PLANE_IP

echo "NEXT STEP: run setup_k8s.sh to bootstrap the cluster"