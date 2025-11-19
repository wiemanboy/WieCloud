NODE_IPS=192.168.178.194

while [[ $# -gt 0 ]]; do
  case $1 in
    --ip)
      NODE_IPS="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

DRY_RUN_TAG=$([[ $DRY_RUN != "false" ]] && echo "--dry-run" || echo "")

talosctl bootstrap --nodes $NODE_IPS --talosconfig=./talosconfig

echo "NEXT STEP: run talosctl kubeconfig --nodes $NODE_IPS --talosconfig=./talosconfig to get kubeconfig file"