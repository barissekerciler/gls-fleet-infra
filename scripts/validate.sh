#!/usr/bin/env bash

# Prerequisites
# - yq v4.6
# - kustomize v3.9
# - kubeval v0.15

COUNT=$#

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "options:"
      echo "-h, --help                show brief help"
      echo "--cluster                 validate clusters"
      echo "--kustomize               validate kustomize overlays"
      exit 0
      ;;
    --cluster)
      CLUSTER=true
      shift
      ;;
    --kustomize)
      KUSTOMIZE=true
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [ $COUNT -eq 0 ]; then
    CLUSTER=true
    KUSTOMIZE=true
fi

function error() {
  RED='\033[0;31m'
  NC='\033[0m' # No Color
  echo -e "${RED}ERROR${NC} - ${1}"
  exit 1
}

if [[ "$CLUSTER" ]]; then
  echo "=== INFO - Validating clusters ==="
  kubeconform -ignore-filename-pattern '.*\/flux-system\/.*' -ignore-filename-pattern kustomization.yaml -schema-location default -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' -summary ./clusters
fi
# mirror kustomize-controller build options
kustomize_config="kustomization.yaml"

if [[ "$KUSTOMIZE" ]]; then
  echo "=== INFO - Validating kustomize overlays ==="
  find . -type f -name $kustomize_config -not -path "./clusters/*" -print0 | while IFS= read -r -d $'\0' file;
    do
      echo "INFO - Validating kustomization ${file/%$kustomize_config}"
      kustomize build "${file/%$kustomize_config}" | \
        kubeconform -schema-location default -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' -summary
      if [[ ${PIPESTATUS[0]} != 0 ]]; then
        error "unable to validate ${file}"
      fi
  done
fi
