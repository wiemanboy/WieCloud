NODE_IP=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --cp)
      NODE_IP="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

talosctl bootstrap --nodes $NODE_IP --talosconfig=./talosconfig || exit 1

echo "NEXT STEP: run talosctl kubeconfig --nodes $NODE_IP --talosconfig=./talosconfig to get kubeconfig file"