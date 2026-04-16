#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: propdevelopment-cluster-admins
subjects:
  - kind: Group
    name: propdev:k8s:cluster-admins
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: propdevelopment-cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: propdevelopment-security-auditors
subjects:
  - kind: Group
    name: propdev:k8s:security-auditors
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: propdevelopment-security-auditor
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: propdevelopment-cluster-viewers
subjects:
  - kind: Group
    name: propdev:k8s:cluster-viewers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: propdevelopment-cluster-viewer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: propdevelopment-platform-engineers
subjects:
  - kind: Group
    name: propdev:k8s:platform-engineers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: propdevelopment-platform-engineer
  apiGroup: rbac.authorization.k8s.io
YAML

kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-sales-developers
  namespace: pd-sales
subjects:
  - kind: Group
    name: propdev:sales:developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: propdevelopment-domain-developer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-tenant-developers
  namespace: pd-tenant-services
subjects:
  - kind: Group
    name: propdev:tenant:developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: propdevelopment-domain-developer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-finance-developers
  namespace: pd-finance
subjects:
  - kind: Group
    name: propdev:finance:developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: propdevelopment-domain-developer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-data-developers
  namespace: pd-data
subjects:
  - kind: Group
    name: propdev:data:developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: propdevelopment-domain-developer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-smarthome-developers
  namespace: pd-smart-home
subjects:
  - kind: Group
    name: propdev:smarthome:developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: propdevelopment-domain-developer
  apiGroup: rbac.authorization.k8s.io
YAML

kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-sales-viewers
  namespace: pd-sales
subjects:
  - kind: Group
    name: propdev:sales:operators
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: propdevelopment-namespace-viewer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-tenant-viewers
  namespace: pd-tenant-services
subjects:
  - kind: Group
    name: propdev:tenant:operators
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: propdevelopment-namespace-viewer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-finance-viewers
  namespace: pd-finance
subjects:
  - kind: Group
    name: propdev:finance:operators
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: propdevelopment-namespace-viewer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-data-viewers
  namespace: pd-data
subjects:
  - kind: Group
    name: propdev:data:analysts
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: propdevelopment-namespace-viewer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-smarthome-viewers
  namespace: pd-smart-home
subjects:
  - kind: Group
    name: propdev:smarthome:operators
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: propdevelopment-namespace-viewer
  apiGroup: rbac.authorization.k8s.io
YAML

echo "Created PropDevelopment RBAC bindings."

