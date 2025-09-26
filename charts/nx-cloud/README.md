# Nx Cloud Helm Chart

This chart deploys Nx Cloud components (API, Frontend, Aggregator, optional File Server, and optional Workflow
Controller service for Nx Agents).

> Important: Breaking changes in 1.0.0
>
> Starting with chart version 1.0.0, there are breaking changes to values and templates. Please review the migration guide before upgrading and plan for required adjustments.
>
> See MIGRATION.md for details: [MIGRATION.md](MIGRATION.md)

## Prerequisites
* MongoDB 7+
* Valkey 7.2+
* Object storage
  * Cloud storage (recommended for production deployments)
    * S3-compatible storage 
    * Google Cloud Storage 
    * Azure Blob Storage 
  * **OR** built-in file server (not recommended for production)

## Object storage
We recommend using a S3-compatible storage / Google Cloud Storage / Azure Blob Storage for production deployments.
However, if you do not have a storage solution available, you can enable the built-in file server by setting `fileServer.enabled` to `true`.

## Values

Below is a summary table of configurable values from values.yaml.

| Key                                                         | Type   | Default                                     | Description                                                               |
|-------------------------------------------------------------|--------|---------------------------------------------|---------------------------------------------------------------------------|
| global.labels                                               | object | {}                                          | Common labels added to all resources.                                     |
| global.podLabels                                            | object | {}                                          | Pod labels applied to all Deployments/Pods.                               |
| global.imageTag                                             | string | "2025.06.3"                                 | Default image tag used when per-service tag is empty.                     |
| global.imagePullPolicy                                      | string | IfNotPresent                                | Global image pull policy.                                                 |
| global.imagePullSecrets                                     | list   | []                                          | List of image pull secret names.                                          |
| global.verboseLogging                                       | bool   | false                                       | Enable verbose logging globally.                                          |
| global.logLevel                                             | string | "INFO"                                      | Global log level.                                                         |
| global.nxCloudAppURL                                        | string | ""                                          | Public URL for Nx Cloud application.                                      |
| global.mongodbConnectionString.secretName                   | string | ""                                          | Name of Secret containing MongoDB connection string.                      |
| global.mongodbConnectionString.secretKey                    | string | ""                                          | Key in Secret for MongoDB connection string.                              |
| global.extraContainers                                      | list   | []                                          | Extra sidecar containers to inject globally into pods.                    |
| config.agentConfigs                                         | string | ""                                          | Optional Agent configuration (YAML/JSON) injected via ConfigMap.          |
| ingress.enabled                                             | bool   | true                                        | Enable Kubernetes Ingress.                                                |
| ingress.annotations                                         | object | {}                                          | Annotations applied to Ingress.                                           |
| ingress.labels                                              | object | {}                                          | Labels applied to Ingress.                                                |
| ingress.className                                           | string | ""                                          | Ingress class name.                                                       |
| ingress.host                                                | string | ""                                          | Hostname for the Ingress.                                                 |
| ingress.tls.enabled                                         | bool   | false                                       | Enable TLS for Ingress.                                                   |
| ingress.tls.secretName                                      | string | ""                                          | Secret name for TLS certificate.                                          |
| ingress.tls.hosts                                           | list   | []                                          | Additional hosts for TLS.                                                 |
| ingress.additionalPaths                                     | list   | []                                          | Additional path rules appended to the Ingress.                            |
| fileServer.enabled                                          | bool   | false                                       | Enable internal file server component.                                    |
| fileServer.verboseLogging                                   | bool   | false                                       | Enable verbose logging for file server.                                   |
| fileServer.logLevel                                         | string | "INFO"                                      | Log level for file server.                                                |
| fileServer.image.repository                                 | string | "nxprivatecloud/nx-cloud-file-server"       | File server image repository.                                             |
| fileServer.image.tag                                        | string | ""                                          | File server image tag (overrides global.imageTag when set).               |
| fileServer.image.pullPolicy                                 | string | IfNotPresent                                | Image pull policy for file server.                                        |
| fileServer.service.annotations                              | object | {}                                          | Service annotations for file server.                                      |
| fileServer.service.labels                                   | object | {}                                          | Service labels for file server.                                           |
| fileServer.service.name                                     | string | nx-cloud-file-server-service                | File server service name.                                                 |
| fileServer.service.type                                     | string | ClusterIP                                   | File server service type.                                                 |
| fileServer.service.port                                     | int    | 5000                                        | File server service port.                                                 |
| fileServer.deployment.annotations                           | object | {}                                          | Deployment annotations for file server.                                   |
| fileServer.deployment.labels                                | object | {}                                          | Deployment labels for file server.                                        |
| fileServer.deployment.podLabels                             | object | {}                                          | Pod labels for file server deployment.                                    |
| fileServer.deployment.port                                  | int    | 5000                                        | Container port for file server.                                           |
| fileServer.deployment.env                                   | object | { NX_CACHE_EXPIRATION_PERIOD_IN_DAYS: "1" } | Environment variables for file server.                                    |
| fileServer.deployment.envValueFrom                          | object | {}                                          | env valueFrom references for file server.                                 |
| fileServer.deployment.strategy.type                         | string | RollingUpdate                               | Deployment strategy type.                                                 |
| fileServer.deployment.strategy.rollingUpdate.maxUnavailable | int    | 1                                           | Max unavailable during rolling update.                                    |
| fileServer.deployment.strategy.rollingUpdate.maxSurge       | int    | 0                                           | Max surge during rolling update.                                          |
| fileServer.deployment.envFrom                               | list   | []                                          | envFrom sources for file server.                                          |
| fileServer.deployment.securityContext                       | object | {}                                          | Pod securityContext for file server.                                      |
| fileServer.deployment.affinity                              | object | {}                                          | Affinity rules for file server.                                           |
| fileServer.deployment.tolerations                           | list   | []                                          | Tolerations for file server.                                              |
| fileServer.deployment.nodeSelector                          | object | {}                                          | Node selector for file server.                                            |
| fileServer.deployment.resources.limits                      | object | {}                                          | Resource limits for file server container.                                |
| fileServer.deployment.resources.requests.memory             | string | '500Mi'                                     | Requested memory.                                                         |
| fileServer.deployment.resources.requests.cpu                | string | '500m'                                      | Requested CPU.                                                            |
| fileServer.deployment.volumes                               | list   | []                                          | Additional volumes.                                                       |
| fileServer.deployment.volumeMounts                          | list   | []                                          | Additional volume mounts.                                                 |
| fileServer.deployment.extraContainers                       | list   | []                                          | Extra sidecars for file server only.                                      |
| fileServer.pvc.name                                         | string | nx-cloud-file-server                        | PVC name for file server storage.                                         |
| fileServer.pvc.annotations                                  | object | {}                                          | PVC annotations.                                                          |
| fileServer.pvc.labels                                       | object | {}                                          | PVC labels.                                                               |
| fileServer.pvc.storageClassName                             | string | ""                                          | Storage class name for PVC.                                               |
| fileServer.pvc.size                                         | string | 10Gi                                        | Requested storage size.                                                   |
| fileServer.pvc.helmResourcePolicy                           | string | keep                                        | Helm resource policy for PVC.                                             |
| fileServer.serviceAccount.create                            | bool   | true                                        | Whether to create a ServiceAccount for file server.                       |
| fileServer.serviceAccount.name                              | string | nx-cloud-file-server                        | ServiceAccount name for file server.                                      |
| fileServer.serviceAccount.annotations                       | object | {}                                          | ServiceAccount annotations for file server.                               |
| fileServer.serviceAccount.labels                            | object | {}                                          | ServiceAccount labels for file server.                                    |
| fileServer.serviceAccount.automount                         | bool   | false                                       | Automount service account token for file server pods.                     |
| aggregator.verboseLogging                                   | bool   | false                                       | Enable verbose logging for aggregator.                                    |
| aggregator.logLevel                                         | string | "INFO"                                      | Log level for aggregator.                                                 |
| aggregator.image.repository                                 | string | "nxprivatecloud/nx-cloud-aggregator"        | Aggregator image repository.                                              |
| aggregator.image.tag                                        | string | ""                                          | Aggregator image tag (overrides global.imageTag when set).                |
| aggregator.image.pullPolicy                                 | string | IfNotPresent                                | Image pull policy for aggregator.                                         |
| aggregator.cronjob.schedule                                 | string | "*/10 * * * *"                              | Cron schedule for the aggregator job.                                     |
| aggregator.cronjob.annotations                              | object | {}                                          | CronJob annotations.                                                      |
| aggregator.cronjob.labels                                   | object | {}                                          | CronJob labels.                                                           |
| aggregator.cronjob.podLabels                                | object | {}                                          | Pod labels for aggregator CronJob.                                        |
| aggregator.cronjob.env                                      | object | {}                                          | Environment variables for aggregator.                                     |
| aggregator.cronjob.envValueFrom                             | object | {}                                          | env valueFrom references for aggregator.                                  |
| aggregator.cronjob.envFrom                                  | list   | []                                          | envFrom sources for aggregator.                                           |
| aggregator.cronjob.securityContext                          | object | {}                                          | Pod securityContext for aggregator.                                       |
| aggregator.cronjob.affinity                                 | object | {}                                          | Affinity rules for aggregator.                                            |
| aggregator.cronjob.tolerations                              | list   | []                                          | Tolerations for aggregator.                                               |
| aggregator.cronjob.nodeSelector                             | object | {}                                          | Node selector for aggregator.                                             |
| aggregator.cronjob.resources.limits                         | object | {}                                          | Resource limits for aggregator.                                           |
| aggregator.cronjob.resources.requests.memory                | string | '1200Mi'                                    | Requested memory.                                                         |
| aggregator.cronjob.resources.requests.cpu                   | string | '500m'                                      | Requested CPU.                                                            |
| aggregator.cronjob.volumes                                  | list   | []                                          | Additional volumes for aggregator.                                        |
| aggregator.cronjob.volumeMounts                             | list   | []                                          | Additional volume mounts for aggregator.                                  |
| aggregator.serviceAccount.create                            | bool   | true                                        | Whether to create a ServiceAccount for aggregator.                        |
| aggregator.serviceAccount.name                              | string | nx-cloud-aggregator                         | ServiceAccount name for aggregator.                                       |
| aggregator.serviceAccount.annotations                       | object | {}                                          | ServiceAccount annotations for aggregator.                                |
| aggregator.serviceAccount.labels                            | object | {}                                          | ServiceAccount labels for aggregator.                                     |
| aggregator.serviceAccount.automount                         | bool   | false                                       | Automount service account token for aggregator pods.                      |
| aggregator.secret.create                                    | bool   | false                                       | Whether to create a Secret for aggregator (placeholder to mount secrets). |
| frontend.verboseLogging                                     | bool   | false                                       | Enable verbose logging for frontend.                                      |
| frontend.logLevel                                           | string | "INFO"                                      | Log level for frontend.                                                   |
| frontend.image.repository                                   | string | "nxprivatecloud/nx-cloud-frontend"          | Frontend image repository.                                                |
| frontend.image.tag                                          | string | ""                                          | Frontend image tag (overrides global.imageTag when set).                  |
| frontend.image.pullPolicy                                   | string | ""                                          | Image pull policy for frontend (defaults to global if empty).             |
| frontend.service.annotations                                | object | {}                                          | Service annotations for frontend.                                         |
| frontend.service.labels                                     | object | {}                                          | Service labels for frontend.                                              |
| frontend.service.name                                       | string | nx-cloud-frontend-service                   | Frontend service name.                                                    |
| frontend.service.type                                       | string | ClusterIP                                   | Frontend service type.                                                    |
| frontend.service.port                                       | int    | 8080                                        | Frontend service port.                                                    |
| frontend.deployment.annotations                             | object | {}                                          | Deployment annotations for frontend.                                      |
| frontend.deployment.labels                                  | object | {}                                          | Deployment labels for frontend.                                           |
| frontend.deployment.podLabels                               | object | {}                                          | Pod labels for frontend deployment.                                       |
| frontend.deployment.replicas                                | int    | 1                                           | Number of frontend replicas.                                              |
| frontend.deployment.port                                    | int    | 4202                                        | Container port for frontend.                                              |
| frontend.deployment.env                                     | object | {}                                          | Environment variables for frontend.                                       |
| frontend.deployment.envValueFrom                            | object | {}                                          | env valueFrom references for frontend.                                    |
| frontend.deployment.strategy.type                           | string | RollingUpdate                               | Deployment strategy type.                                                 |
| frontend.deployment.strategy.rollingUpdate.maxUnavailable   | int    | 0                                           | Max unavailable during rolling update.                                    |
| frontend.deployment.strategy.rollingUpdate.maxSurge         | int    | 1                                           | Max surge during rolling update.                                          |
| frontend.deployment.envFrom                                 | list   | []                                          | envFrom sources for frontend.                                             |
| frontend.deployment.securityContext                         | object | {}                                          | Pod securityContext for frontend.                                         |
| frontend.deployment.affinity                                | object | {}                                          | Affinity rules for frontend.                                              |
| frontend.deployment.tolerations                             | list   | []                                          | Tolerations for frontend.                                                 |
| frontend.deployment.nodeSelector                            | object | {}                                          | Node selector for frontend.                                               |
| frontend.deployment.resources.limits                        | object | {}                                          | Resource limits for frontend.                                             |
| frontend.deployment.resources.requests.memory               | string | '500Mi'                                     | Requested memory.                                                         |
| frontend.deployment.resources.requests.cpu                  | string | '500m'                                      | Requested CPU.                                                            |
| frontend.deployment.volumes                                 | list   | []                                          | Additional volumes.                                                       |
| frontend.deployment.volumeMounts                            | list   | []                                          | Additional volume mounts.                                                 |
| frontend.deployment.extraContainers                         | list   | []                                          | Extra sidecars for frontend only.                                         |
| frontend.serviceAccount.create                              | bool   | true                                        | Whether to create a ServiceAccount for frontend.                          |
| frontend.serviceAccount.name                                | string | nx-cloud-frontend                           | ServiceAccount name for frontend.                                         |
| frontend.serviceAccount.annotations                         | object | {}                                          | ServiceAccount annotations for frontend.                                  |
| frontend.serviceAccount.labels                              | object | {}                                          | ServiceAccount labels for frontend.                                       |
| frontend.serviceAccount.automount                           | bool   | false                                       | Automount service account token for frontend pods.                        |
| api.verboseLogging                                          | bool   | false                                       | Enable verbose logging for API.                                           |
| api.logLevel                                                | string | "INFO"                                      | Log level for API.                                                        |
| api.valkey.clientProvider                                   | string | "redisson"                                  | Valkey client provider implementation.                                    |
| api.valkey.useSentinel                                      | bool   | false                                       | Use Sentinel mode for Valkey.                                             |
| api.valkey.sentinelMasterName                               | string | ""                                          | Sentinel master name.                                                     |
| api.valkey.sentinelPort                                     | int    | 26379                                       | Sentinel port.                                                            |
| api.valkey.primaryAddress                                   | string | ""                                          | Primary Valkey hostname/address.                                          |
| api.valkey.replicaAddresses                                 | string | ""                                          | Comma-separated list of replica addresses.                                |
| api.valkey.port                                             | int    | 6379                                        | Valkey server port.                                                       |
| api.valkey.username                                         | string | ""                                          | Username for Valkey authentication.                                       |
| api.valkey.passwordSecret.name                              | string | ""                                          | Secret name storing Valkey password.                                      |
| api.valkey.passwordSecret.key                               | string | ""                                          | Secret key for Valkey password.                                           |
| api.image.repository                                        | string | "nxprivatecloud/nx-cloud-nx-api"            | API image repository.                                                     |
| api.image.tag                                               | string | ""                                          | API image tag (overrides global.imageTag when set).                       |
| api.image.pullPolicy                                        | string | ""                                          | Image pull policy for API (defaults to global if empty).                  |
| api.service.annotations                                     | object | {}                                          | Service annotations for API.                                              |
| api.service.labels                                          | object | {}                                          | Service labels for API.                                                   |
| api.service.name                                            | string | nx-cloud-nx-api-service                     | API service name.                                                         |
| api.service.type                                            | string | ClusterIP                                   | API service type.                                                         |
| api.service.port                                            | int    | 4203                                        | API service port.                                                         |
| api.deployment.annotations                                  | object | {}                                          | Deployment annotations for API.                                           |
| api.deployment.labels                                       | object | {}                                          | Deployment labels for API.                                                |
| api.deployment.podLabels                                    | object | {}                                          | Pod labels for API deployment.                                            |
| api.deployment.replicas                                     | int    | 1                                           | Number of API replicas.                                                   |
| api.deployment.port                                         | int    | 4203                                        | Container port for API.                                                   |
| api.deployment.env                                          | object | {}                                          | Environment variables for API.                                            |
| api.deployment.envValueFrom                                 | object | {}                                          | env valueFrom references for API.                                         |
| api.deployment.strategy.type                                | string | RollingUpdate                               | Deployment strategy type.                                                 |
| api.deployment.strategy.rollingUpdate.maxUnavailable        | int    | 0                                           | Max unavailable during rolling update.                                    |
| api.deployment.strategy.rollingUpdate.maxSurge              | int    | 1                                           | Max surge during rolling update.                                          |
| api.deployment.envFrom                                      | list   | []                                          | envFrom sources for API.                                                  |
| api.deployment.securityContext                              | object | {}                                          | Pod securityContext for API.                                              |
| api.deployment.affinity                                     | object | {}                                          | Affinity rules for API.                                                   |
| api.deployment.tolerations                                  | list   | []                                          | Tolerations for API.                                                      |
| api.deployment.nodeSelector                                 | object | {}                                          | Node selector for API.                                                    |
| api.deployment.resources.limits                             | object | {}                                          | Resource limits for API.                                                  |
| api.deployment.resources.requests.memory                    | string | '1000Mi'                                    | Requested memory.                                                         |
| api.deployment.resources.requests.cpu                       | string | '1000m'                                     | Requested CPU.                                                            |
| api.deployment.volumes                                      | list   | []                                          | Additional volumes.                                                       |
| api.deployment.volumeMounts                                 | list   | []                                          | Additional volume mounts.                                                 |
| api.deployment.extraContainers                              | list   | []                                          | Extra sidecars for API only.                                              |
| api.serviceAccount.create                                   | bool   | true                                        | Whether to create a ServiceAccount for API.                               |
| api.serviceAccount.name                                     | string | nx-cloud-nx-api                             | ServiceAccount name for API.                                              |
| api.serviceAccount.annotations                              | object | {}                                          | ServiceAccount annotations for API.                                       |
| api.serviceAccount.labels                                   | object | {}                                          | ServiceAccount labels for API.                                            |
| api.serviceAccount.automount                                | bool   | false                                       | Automount service account token for API pods.                             |
| workflowController.service.enabled                          | bool   | false                                       | Create a Service for external workflow controller connectivity.           |
| workflowController.service.name                             | string | "nx-cloud-workflow-controller-service"      | Name of the Service for workflow controller.                              |
| workflowController.service.annotations                      | object | {}                                          | Service annotations.                                                      |
| workflowController.service.labels                           | object | {}                                          | Service labels.                                                           |
| workflowController.service.externalName                     | string | ""                                          | ExternalName for Service (if pointing to external controller).            |
| workflowController.service.port                             | int    | 9000                                        | Service port for workflow controller.                                     |
| workflowController.service.headless                         | bool   | false                                       | Create a headless Service instead of ExternalName.                        |
| extraObjects                                                | object | {}                                          | Additional arbitrary Kubernetes objects to be created.                    |
