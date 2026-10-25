# Ideas de mejora para la demo Argo CD + CFK

Backlog de ideas para evolucionar la demo. No están priorizadas ni implementadas salvo que se indique.

## Seguridad (prioritario)

- [ ] **Rotar las API keys de Confluent Cloud** que están en texto plano en `data/CC/secret.yml` y `data/CC/secretSR.yml` (el repo es público y siguen en el historial de git).
- [ ] **Gestionar secretos con GitOps**: Sealed Secrets, External Secrets Operator (Vault / AWS Secrets Manager) o SOPS + argocd-vault-plugin. Sirve además como segmento de la demo.

## Mejoras a la demo actual

- [ ] **Corregir namespaces inconsistentes**: `data/CP/topics.yml` usa `namespace: confluent` pero la App `confluent-cp` apunta a `confluent-cp`; el operator usa `confluent` en `cfk_across_namespace.yaml` y `confluent-dev` en el README.
- [ ] **Usar `KafkaRestClass`**: un único CR con endpoint, clusterID y credenciales, referenciado desde los topics con `kafkaRestClassRef` en lugar de repetir `kafkaRest` en cada topic.
- [ ] **Desplegar CP también con CFK** (kind/minikube, KRaft en vez de ZooKeeper) en lugar de `cp/docker-compose.yml`, para que todo, incluidos los brokers, sea GitOps.
- [ ] **Más CRDs de CFK**: `Connector`, `ConfluentRolebinding`, `ClusterLink` + `SchemaExporter` (historia de híbrido / migración CP -> CC declarativa en Git).
- [ ] **Entornos con Kustomize overlays** (`dev/`, `prod/`) con distintas particiones / retención por entorno.
- [ ] **Políticas OPA más ricas**: límites de particiones y réplicas, labels obligatorios (`team`, `owner`), retención máxima, `cleanup.policy` permitidas. Tests con `opa test` / conftest, quitar el paso "hardcoded" del workflow y migrar a sintaxis Rego v1.
- [ ] **Actualizar la versión del chart de CFK** (`0.1193.1` está desactualizada).
- [ ] **Limpieza del repo**: eliminar ruido (`.taskmaster`, `.claude`, `.cursor`, `GEMINI.md`, `task-*.txt`, `error.txt`, `*.bak`), reorganizar en `apps/`, `platform/`, `teams/`, y corregir el README (ejemplo con `kafka.strimzi.io` en lugar de CFK, erratas).

## Funcionalidades de Argo CD aplicables a CFK

- [ ] **App of Apps / ApplicationSet** con Git directory generator: una App por equipo (`teams/*/`) o por cluster (CC/CP). Self-service: un equipo añade una carpeta y Argo crea su App.
- [ ] **ApplicationSet Pull Request generator**: topics efímeros (`pr-42-...`) en dev por cada PR, que se borran al cerrarla.
- [ ] **Sync waves + hooks**: operator -> Secrets/ConfigMaps -> `KafkaRestClass` -> topics -> schemas -> connectors/rolebindings. `PreSync` Job para comprobar la conectividad REST y `PostSync` con smoke test produce/consume.
- [ ] **Custom health checks (Lua)** para `KafkaTopic` y `Schema` (Healthy solo si `status.state == CREATED`). Argo CD ya trae uno built-in para `Connector`, `Kafka`, `Connect`, `SchemaRegistry`, `KsqlDB`, `ControlCenter` y `Zookeeper` (v2.14+).
- [ ] **Custom resource actions (Lua)**: botones en la UI de Argo para, por ejemplo, reiniciar o pausar un `Connector` mediante las anotaciones de CFK (validar nombres exactos en la documentación de CFK).
- [ ] **Protección de borrado**: `argocd.argoproj.io/sync-options: Prune=false,Delete=false` en topics críticos. Por defecto, borrar el YAML hace que CFK borre el topic real y sus datos.
- [ ] **selfHeal / detección de drift**: un `kubectl edit` sobre un topic se revierte automáticamente. Nota: Argo detecta drift en el CR de Kubernetes, no cambios hechos directamente en Kafka (eso lo reconcilia CFK).
- [ ] **`ignoreDifferences` + `RespectIgnoreDifferences`** para campos que el operator muta y evitar falsos OutOfSync.
- [ ] **AppProjects + RBAC/SSO**: por equipo, restringir namespaces, repos y kinds permitidos (por ejemplo solo `KafkaTopic` / `Schema`, nunca `Kafka`). Multi-tenancy real.
- [ ] **Notifications**: alertas a Slack/Teams cuando un topic queda Degraded o falla un sync.
- [ ] **Sync windows**: congelación de cambios en producción (por ejemplo, sin cambios de topics en horario de negocio).
- [ ] **History / rollback** y **`argocd app diff` en CI**: comentar en el PR qué CRs van a cambiar.
- [ ] **Multi-cluster**: un Argo CD central gestionando CFK en varios clusters con ApplicationSet cluster generator.
