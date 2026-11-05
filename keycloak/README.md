# Keycloak Helm Chart

Minimal Helm chart to deploy [Keycloak](https://www.keycloak.org/) on Kubernetes. By default Keycloak uses its embedded (`dev-file`) database. External PostgreSQL is optional via `database.enabled: true`.

## Create a namespace
kubectl create namespace cadc-auth

## Keycloak

```bash
helm install keycloak ./charts/keycloak \
  --namespace cadc-auth
```

Or use a values overlay:

```bash
helm install keycloak ./charts/keycloak \
  --namespace cadc-auth \
  -f values-localhost.yaml
```

If `auth.adminPassword` is omitted and no existing secret is provided, the chart generates a random password and stores it in a Kubernetes Secret. On upgrade, existing generated passwords are preserved. When `database.enabled` is true and `database.password` is omitted (with no existing DB secret), the DB password is generated the same way.

### Local without Traefik

Install Keycloak with the localhost overlay (skips Ingress; use port-forward). Uses the embedded database by default:

```bash
helm install keycloak ./charts/keycloak \
  --namespace cadc-auth \
  -f charts/keycloak/localhost-values.yaml

kubectl -n cadc-auth port-forward svc/keycloak 8080:80
```

Then open `http://localhost:8080/keycloak`.

### Realm import

Import realm JSON at startup with `--import-realm` (files mounted at `/opt/keycloak/data/import`). See [Keycloak import/export](https://www.keycloak.org/server/importExport).

If a realm already exists, Keycloak **skips** the import. To overwrite, run `kc.sh import` separately while the server is stopped (not handled by this chart).

Enable via values overlay — either inline files (chart creates a ConfigMap) or an existing ConfigMap/Secret:

```yaml
realmImport:
  enabled: true
  files:
    cadc.json: |
      {
        "realm": "cadc",
        "enabled": true
      }
```

```bash
helm upgrade --install keycloak ./charts/keycloak \
  --namespace cadc-auth \
  -f charts/keycloak/localhost-values.yaml \
  -f my-realm-import.yaml
```

Use `realmImport.existingConfigMap` or `realmImport.existingSecret` for large exports or JSON that contains credentials (ConfigMaps are limited to ~1Mi). Keys in the ConfigMap/Secret must be `*.json` filenames.

LDAP User Federation and attribute mappers belong in the realm JSON (not Helm `KC_*` env vars). Example mapper shape inside the LDAP provider:

```json
{
  "name": "email",
  "providerId": "user-attribute-ldap-mapper",
  "config": {
    "ldap.attribute": ["mail"],
    "user.model.attribute": ["email"],
    "is.mandatory.in.ldap": ["true"]
  }
}
```

## Optional PostgreSQL

For persistent / production use, point Keycloak at an existing PostgreSQL instance reachable from the cluster and enable external database settings:

```yaml
database:
  enabled: true
  host: postgres.example.svc.cluster.local
  name: auth
  username: admin
  password: pw-admin
  schema: keycloak
```

```bash
helm upgrade --install keycloak ./charts/keycloak \
  --namespace cadc-auth \
  -f my-database-values.yaml
```

If you use a non-default schema (default `database.schema: keycloak`), create that schema in PostgreSQL before Keycloak starts; this chart does not create it.

## Configuration

| Value | Default | Description |
|---|---|---|
| `ingress.hostname` | `rc-uv.canfar.net` | Public hostname |
| `ingress.className` | `traefik` | IngressClass |
| `ingress.management.enabled` | `false` | Expose health/metrics via Traefik port 9000 |
| `service.port` | `80` | Service port (Traefik backend) |
| `service.targetPort` | `8080` | Keycloak HTTP container port |
| `service.managementPort` | `9000` | Keycloak management/health port |
| `database.enabled` | `false` | Use external PostgreSQL (`true`) or Keycloak embedded DB (`false`) |
| `database.host` | `postgresql` | External PostgreSQL hostname; required when `database.enabled` is true |
| `keycloak.hostname` | `rc-uv.canfar.net` | Keycloak public hostname |
| `keycloak.proxyHeaders` | `xforwarded` | Reverse proxy header mode |
| `realmImport.enabled` | `false` | Mount realm JSON and pass `--import-realm` |
| `realmImport.files` | `{}` | Map of `*.json` filename → realm JSON (creates ConfigMap) |
| `realmImport.existingConfigMap` | `""` | Mount an existing ConfigMap instead of `files` |
| `realmImport.existingSecret` | `""` | Mount an existing Secret instead of `files` |

Traefik terminates HTTPS and forwards HTTP to the Keycloak Service on port 80. Management endpoints (`/health/*`, `/metrics`) are reachable at `http://<ingress.hostname>:9000/` via Traefik's management entrypoint when `ingress.management.enabled` is true.

## Upgrade

```bash
helm upgrade keycloak ./charts/keycloak \
  --namespace cadc-auth \
  -f values-rc-uv.yaml
```

## Uninstall

```bash
helm uninstall keycloak --namespace cadc-auth
```

## Verify locally

```bash
helm lint ./charts/keycloak

helm template keycloak ./charts/keycloak
helm template keycloak ./charts/keycloak -f charts/keycloak/test-values.yaml
```
