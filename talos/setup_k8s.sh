CONTROL_PLANE_IP=192.168.178.194

while [[ $# -gt 0 ]]; do
  case $1 in
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

talosctl bootstrap --nodes $CONTROL_PLANE_IP --talosconfig=./talosconfig

echo "NEXT STEP: run talosctl kubeconfig --nodes $CONTROL_PLANE_IP --talosconfig=./talosconfig to get kubeconfig file"