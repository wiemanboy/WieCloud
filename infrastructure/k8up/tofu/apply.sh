tofu apply -var "access_key=$(kubectl -n k8up get secret deploy-s3-secret -o jsonpath="{.data.accessKey}" | base64 --decode)" \
           -var "secret_key=$(kubectl -n k8up get secret deploy-s3-secret -o jsonpath="{.data.secretKey}" | base64 --decode)"
