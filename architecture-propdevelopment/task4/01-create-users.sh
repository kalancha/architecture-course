#!/usr/bin/env bash
set -euo pipefail
.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATED_DIR="${SCRIPT_DIR}/generated"
CERT_DIR="${GENERATED_DIR}/certs"
KUBECONFIG_OUT="${GENERATED_DIR}/propdevelopment-users.kubeconfig"
MINIKUBE_HOME="${MINIKUBE_HOME:-${HOME}/.minikube}"
MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-minikube}"
CLUSTER_NAME="${CLUSTER_NAME:-${MINIKUBE_PROFILE}}"

CA_CRT="${MINIKUBE_HOME}/ca.crt"
CA_KEY="${MINIKUBE_HOME}/ca.key"

if [[ ! -f "${CA_CRT}" || ! -f "${CA_KEY}" ]]; then
  echo "Minikube CA files were not found in ${MINIKUBE_HOME}."
  echo "Start Minikube first: minikube start -p ${MINIKUBE_PROFILE}"
  exit 1
fi

mkdir -p "${CERT_DIR}"

SERVER="$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}')"
kubectl config --kubeconfig "${KUBECONFIG_OUT}" set-cluster "${CLUSTER_NAME}" \
  --server="${SERVER}" \
  --certificate-authority="${CA_CRT}" \
  --embed-certs=true >/dev/null

USERS=(
  "pd-platform-admin|/CN=pd-platform-admin/O=propdev:k8s:cluster-admins"
  "pd-security-auditor|/CN=pd-security-auditor/O=propdev:k8s:security-auditors"
  "pd-cluster-viewer|/CN=pd-cluster-viewer/O=propdev:k8s:cluster-viewers"
  "pd-platform-engineer|/CN=pd-platform-engineer/O=propdev:k8s:platform-engineers"
  "pd-sales-dev|/CN=pd-sales-dev/O=propdev:sales:developers"
  "pd-smarthome-dev|/CN=pd-smarthome-dev/O=propdev:smarthome:developers"
)

for entry in "${USERS[@]}"; do
  IFS='|' read -r username subject <<< "${entry}"
  key_path="${CERT_DIR}/${username}.key"
  csr_path="${CERT_DIR}/${username}.csr"
  crt_path="${CERT_DIR}/${username}.crt"

  openssl genrsa -out "${key_path}" 2048 >/dev/null 2>&1
  openssl req -new -key "${key_path}" -out "${csr_path}" -subj "${subject}" >/dev/null 2>&1
  openssl x509 -req \
    -in "${csr_path}" \
    -CA "${CA_CRT}" \
    -CAkey "${CA_KEY}" \
    -CAcreateserial \
    -out "${crt_path}" \
    -days 365 \
    -sha256 >/dev/null 2>&1

  kubectl config --kubeconfig "${KUBECONFIG_OUT}" set-credentials "${username}" \
    --client-certificate="${crt_path}" \
    --client-key="${key_path}" \
    --embed-certs=true >/dev/null

  kubectl config --kubeconfig "${KUBECONFIG_OUT}" set-context "${username}@${CLUSTER_NAME}" \
    --cluster="${CLUSTER_NAME}" \
    --user="${username}" >/dev/null
done

echo "Created users and kubeconfig: ${KUBECONFIG_OUT}"
echo "Example: KUBECONFIG=${KUBECONFIG_OUT} kubectl config use-context pd-cluster-viewer@${CLUSTER_NAME}"
