CONTROL_PLANE_IP=192.168.178.194
talosctl bootstrap --nodes $CONTROL_PLANE_IP --talosconfig=./talosconfig

echo "NEXT STEP: run talosctl kubeconfig --nodes $CONTROL_PLANE_IP --talosconfig=./talosconfig to get kubeconfig file"