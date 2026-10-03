set -e

name=$(grep "^name:" Image.yaml | awk '{print $2}')
version=$(grep "^version:" Image.yaml | awk '{print $2}')

echo "Building ${name} version ${version}"

cd src
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-X main.appName=$name -X main.appVersion=$version" -o ../.build/tofudeployer .
