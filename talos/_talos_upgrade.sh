DRY_RUN=true
NODE_IPS=192.168.178.194
TALOS_VERSION=v1.11.5

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN="$2"
      shift 2
      ;;
    --ip)
      NODE_IPS="$2"
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

IMAGE_ID=$(curl -s -X POST --data-binary @bare-metal.yaml https://factory.talos.dev/schematics | jq -r '.id')

if [[ $DRY_RUN != "false" ]]; then
    echo "DRY RUN:"
    echo "talosctl upgrade --nodes  --image factory.talos.dev/installer/${IMAGE_ID}:${TALOS_VERSION} --preserve"
    exit
fi

talosctl upgrade --nodes $NODE_IPS --talosconfig=./talosconfig --image factory.talos.dev/installer/${IMAGE_ID}:${TALOS_VERSION} --preserve