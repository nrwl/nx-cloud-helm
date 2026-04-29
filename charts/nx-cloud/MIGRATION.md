# Migration Guide for 1.0.0

Version 1.0.0 of the nx-cloud Helm chart introduces breaking changes. Please review and update your values accordingly
before upgrading.

## Migration table

This table maps legacy values (pre-1.0.0) to their new equivalents.

| Legacy key path                     | New key/path or status                             | Notes                                                                                                                                                                             |
|-------------------------------------|----------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| image.tag                           | global.imageTag or per-service image.tag           | Deprecated. Prefer service-specific image.tag; falls back to global.imageTag.                                                                                                     |
| global.imageRegistry                | Removed                                            | Use each component's image.repository with full reference (including registry) as needed.                                                                                         |
| global.imageTag                     | global.imageTag                                    | Stays the same. Can be overridden per component via component.image.tag.                                                                                                          |
| global.imageRepository              | Removed                                            | Use each component's image.repository (full name).                                                                                                                                |
| global.namespace                    | Removed                                            | Chart now deploys into .Release.Namespace.                                                                                                                                        |
| naming.nameOverride                 | nameOverride                                       | Moved/renamed to top-level nameOverride.                                                                                                                                          |
| naming.fullNameOverride             | fullNameOverride                                   | Moved/renamed to top-level fullNameOverride.                                                                                                                                      |
| mode                                | Removed                                            | Hardcoded in templates.                                                                                                                                                           |
| nxCloudAppURL                       | global.nxCloudAppURL                               | Moved.                                                                                                                                                                            |
| verboseLogging                      | global.verboseLogging and component.verboseLogging | Moved. Also configurable per component now.                                                                                                                                       |
| verboseMongoLogging                 | Removed                                            | If required, set via environment variables in supported components. See: [Environment variables configured by legacy values](#environment-variables-configured-by-legacy-values). |
| enableMessageQueue                  | Removed                                            | Message queue must be set up externally.                                                                                                                                          |
| frontend.serviceAccountName         | frontend.serviceAccount.name                       | Moved. Chart now creates a SA by default; disable with frontend.serviceAccount.create=false.                                                                                      |
| frontend.image.registry             | Removed                                            | Use frontend.image.repository (full name).                                                                                                                                        |
| frontend.image.imageName            | Removed                                            | Use frontend.image.repository (full name).                                                                                                                                        |
| frontend.image.repository           | frontend.image.repository                          | Must now include full image name (incl. registry).                                                                                                                                |
| frontend.image.tag                  | frontend.image.tag                                 | Unchanged (overrides global.imageTag).                                                                                                                                            |
| frontend.image.digest               | Removed                                            | Not supported.                                                                                                                                                                    |
| frontend.image.pullPolicy           | frontend.image.pullPolicy                          | Default changed from Always to IfNotPresent.                                                                                                                                      |
| frontend.deployment.replicas        | frontend.deployment.replicas                       | Unchanged.                                                                                                                                                                        |
| frontend.deployment.port            | frontend.deployment.port                           | Unchanged.                                                                                                                                                                        |
| frontend.deployment.env (list)      | frontend.deployment.env (object)                   | Format changed to key/value object (ENV_NAME: value).                                                                                                                             |
| frontend.deployment.volumes         | frontend.deployment.volumes                        | Unchanged.                                                                                                                                                                        |
| frontend.deployment.volumeMounts    | frontend.deployment.volumeMounts                   | Unchanged.                                                                                                                                                                        |
| frontend.service.name               | frontend.service.name                              | Unchanged.                                                                                                                                                                        |
| frontend.service.type               | frontend.service.type                              | Unchanged.                                                                                                                                                                        |
| frontend.service.port               | frontend.service.port                              | Unchanged.                                                                                                                                                                        |
| frontend.service.annotations        | frontend.service.annotations                       | Unchanged.                                                                                                                                                                        |
| frontend.resources                  | frontend.deployment.resources                      | Moved.                                                                                                                                                                            |
| nxApi (section)                     | api (section)                                      | Section renamed to api.                                                                                                                                                           |
| nxApi.serviceAccountName            | api.serviceAccount.name                            | Moved. Chart creates SA by default; disable with api.serviceAccount.create=false.                                                                                                 |
| nxApi.image.registry                | Removed                                            | Use api.image.repository (full name).                                                                                                                                             |
| nxApi.image.imageName               | Removed                                            | Use api.image.repository (full name).                                                                                                                                             |
| nxApi.image.repository              | api.image.repository                               | Must include full image name.                                                                                                                                                     |
| nxApi.image.tag                     | api.image.tag                                      | Unchanged.                                                                                                                                                                        |
| nxApi.image.digest                  | Removed                                            | Not supported.                                                                                                                                                                    |
| nxApi.image.pullPolicy              | api.image.pullPolicy                               | Default changed from Always to IfNotPresent/global.                                                                                                                               |
| nxApi.deployment.replicas           | api.deployment.replicas                            | Unchanged.                                                                                                                                                                        |
| nxApi.deployment.port               | api.deployment.port                                | Unchanged.                                                                                                                                                                        |
| nxApi.deployment.env (list)         | api.deployment.env (object)                        | Format changed to key/value object (ENV_NAME: value).                                                                                                                             |
| nxApi.deployment.readinessProbe     | Removed                                            | Not provided; configure via extra containers or probes if needed.                                                                                                                 |
| nxApi.deployment.volumes            | api.deployment.volumes                             | Unchanged.                                                                                                                                                                        |
| nxApi.deployment.volumeMounts       | api.deployment.volumeMounts                        | Unchanged.                                                                                                                                                                        |
| nxApi.service.name                  | api.service.name                                   | Unchanged.                                                                                                                                                                        |
| nxApi.service.type                  | api.service.type                                   | Unchanged.                                                                                                                                                                        |
| nxApi.service.port                  | api.service.port                                   | Unchanged.                                                                                                                                                                        |
| nxApi.service.annotations           | api.service.annotations                            | Unchanged.                                                                                                                                                                        |
| nxApi.resources                     | api.deployment.resources                           | Moved.                                                                                                                                                                            |
| fileServer.serviceAccountName       | fileServer.serviceAccount.name                     | Moved. Chart creates SA by default; disable with fileServer.serviceAccount.create=false.                                                                                          |
| fileServer.image.registry           | Removed                                            | Use fileServer.image.repository (full name).                                                                                                                                      |
| fileServer.image.imageName          | Removed                                            | Use fileServer.image.repository (full name).                                                                                                                                      |
| fileServer.image.repository         | fileServer.image.repository                        | Must include full image name.                                                                                                                                                     |
| fileServer.image.tag                | fileServer.image.tag                               | Unchanged.                                                                                                                                                                        |
| fileServer.image.digest             | Removed                                            | Not supported.                                                                                                                                                                    |
| fileServer.image.pullPolicy         | fileServer.image.pullPolicy                        | Default changed from Always to IfNotPresent.                                                                                                                                      |
| fileServer.deployment.port          | fileServer.deployment.port                         | Unchanged.                                                                                                                                                                        |
| fileServer.deployment.env (list)    | fileServer.deployment.env (object)                 | Format changed to key/value object.                                                                                                                                               |
| fileServer.service.name             | fileServer.service.name                            | Unchanged.                                                                                                                                                                        |
| fileServer.service.type             | fileServer.service.type                            | Unchanged.                                                                                                                                                                        |
| fileServer.service.port             | fileServer.service.port                            | Unchanged.                                                                                                                                                                        |
| fileServer.service.annotations      | fileServer.service.annotations                     | Unchanged.                                                                                                                                                                        |
| fileServer.resources                | fileServer.deployment.resources                    | Moved.                                                                                                                                                                            |
| fileServer.securityContext          | fileServer.deployment.securityContext              | Moved.                                                                                                                                                                            |
| aggregator.serviceAccountName       | aggregator.serviceAccount.name                     | Moved. Chart creates SA by default; disable with aggregator.serviceAccount.create=false.                                                                                          |
| aggregator.schedule                 | aggregator.cronjob.schedule                        | Moved.                                                                                                                                                                            |
| aggregator.image.registry           | Removed                                            | Use aggregator.image.repository (full name).                                                                                                                                      |
| aggregator.image.imageName          | Removed                                            | Use aggregator.image.repository (full name).                                                                                                                                      |
| aggregator.image.repository         | aggregator.image.repository                        | Must include full image name.                                                                                                                                                     |
| aggregator.image.tag                | aggregator.image.tag                               | Unchanged.                                                                                                                                                                        |
| aggregator.image.digest             | Removed                                            | Not supported.                                                                                                                                                                    |
| aggregator.image.pullPolicy         | aggregator.image.pullPolicy                        | Default changed from Always to IfNotPresent.                                                                                                                                      |
| aggregator.env (list)               | aggregator.cronjob.env (object)                    | Moved and format changed to key/value object.                                                                                                                                     |
| aggregator.volumes                  | aggregator.cronjob.volumes                         | Moved.                                                                                                                                                                            |
| aggregator.volumeMounts             | aggregator.cronjob.volumeMounts                    | Moved.                                                                                                                                                                            |
| aggregator.resources                | aggregator.cronjob.resources                       | Moved.                                                                                                                                                                            |
| messagequeue (section)              | Removed                                            | Must be set up externally. No built-in deployment.                                                                                                                                |
| nxCloudWorkflows (section)          | workflowController (section)                       | Section renamed and structure changed.                                                                                                                                            |
| nxCloudWorkflows.enabled            | workflowController.service.enabled                 | Renamed/moved.                                                                                                                                                                    |
| nxCloudWorkflows.port               | workflowController.service.port                    | Renamed/moved.                                                                                                                                                                    |
| nxCloudWorkflows.name               | workflowController.service.name                    | Renamed/moved.                                                                                                                                                                    |
| nxCloudWorkflows.workflowsNamespace | Removed                                            | Now uses .Release.Namespace.                                                                                                                                                      |
| nxCloudWorkflows.externalName       | workflowController.service.externalName            | Renamed/moved.                                                                                                                                                                    |
| nxCloudWorkflows.headless           | workflowController.service.headless                | Renamed/moved.                                                                                                                                                                    |
| replicas.frontend                   | frontend.deployment.replicas                       | Deprecated in favor of per-component replicas.                                                                                                                                    |
| replicas.nxApi                      | api.deployment.replicas                            | Deprecated in favor of per-component replicas.                                                                                                                                    |
| ingress.skip                        | ingress.enabled                                    | Logic reversed. Set enabled: true instead of skip: false.                                                                                                                         |
| ingress.globalStaticIpName          | ingress.annotations                                | Deprecated; provide ingress controller specific annotations instead.                                                                                                              |
| ingress.managedCertificates         | ingress.annotations                                | Deprecated; use annotations.                                                                                                                                                      |
| ingress.albScheme                   | ingress.annotations                                | Deprecated; use annotations.                                                                                                                                                      |
| ingress.albListenPorts              | ingress.annotations                                | Deprecated; use annotations.                                                                                                                                                      |
| ingress.albCertificateArn           | ingress.annotations                                | Deprecated; use annotations.                                                                                                                                                      |
| ingress.class                       | ingress.className                                  | Renamed.                                                                                                                                                                          |
| ingress.annotations                 | ingress.annotations                                | Unchanged, default includes nx.app/installed-by: 'helm'.                                                                                                                          |
| fileStorage.storageClassName        | fileServer.pvc.storageClassName                    | Moved.                                                                                                                                                                            |
| fileStorage.size                    | fileServer.pvc.size                                | Moved. Note default changed to 10Gi in values.yaml.                                                                                                                               |
| fileStorage.resourcePolicy          | fileServer.pvc.helmResourcePolicy                  | Renamed/moved.                                                                                                                                                                    |
| awsS3.*                             | Removed                                            | Configure via environment variables on the relevant components. See: [Environment variables configured by legacy values](#environment-variables-configured-by-legacy-values).     |
| azure.*                             | Removed                                            | Configure via environment variables on the relevant components. See: [Environment variables configured by legacy values](#environment-variables-configured-by-legacy-values).     |
| useCosmosDb                         | Removed                                            | Configure via environment variables on the relevant components. See: [Environment variables configured by legacy values](#environment-variables-configured-by-legacy-values).     |
| gitlab.*                            | Removed                                            | Configure via environment variables on the relevant components. See: [Environment variables configured by legacy values](#environment-variables-configured-by-legacy-values).     |
| github.*                            | Removed                                            | Configure via environment variables on the relevant components. See: [Environment variables configured by legacy values](#environment-variables-configured-by-legacy-values).     |
| bitbucket.*                         | Removed                                            | Configure via environment variables on the relevant components. See: [Environment variables configured by legacy values](#environment-variables-configured-by-legacy-values).     |
| saml.*                              | Removed                                            | Configure via environment variables on the relevant components. See: [Environment variables configured by legacy values](#environment-variables-configured-by-legacy-values).     |
| selfSignedCertConfigMap             | Removed                                            | Replace with a ConfigMap via extraObjects and mount via volumes if needed.                                                                                                        |
| preBuiltJavaCertStoreConfigMap      | Removed                                            | Replace with a ConfigMap via extraObjects and mount via volumes if needed.                                                                                                        |
| vcsHttpsProxy                       | Removed                                            | Configure via environment variables on the relevant components. See: [Environment variables configured by legacy values](#environment-variables-configured-by-legacy-values).     |
| resourceClassConfiguration          | config.agentConfigs (string)                       | Moved and changed: now a single string containing the agent configs.                                                                                                              |
| secret.*                            | Removed                                            | Use environment variables mounted via env/envFrom/envValueFrom. See: [Environment variables configured by legacy values](#environment-variables-configured-by-legacy-values).     |
| extraManifests                      | extraObjects                                       | Renamed.                                                                                                                                                                          |

## Environment variables configured by legacy values

The following table summarizes which environment variables were implicitly configured by legacy values in pre-1.0.0
charts and how their values were derived.

| Key (values.yaml)                 | Environment variable(s) created in templates              | Where used                                                  |
|-----------------------------------|-----------------------------------------------------------|-------------------------------------------------------------|
| secret.nxCloudMongoServerEndpoint | NX_CLOUD_MONGO_SERVER_ENDPOINT                            | frontend, nx-api, aggregator (via nxCloud.env.mongoSecrets) |
| secret.adminPassword              | ADMIN_PASSWORD                                            | aggregator                                                  |
| secret.awsS3AccessKeyId           | AWS_S3_ACCESS_KEY_ID                                      | nx-api                                                      |
| secret.awsS3SecretAccessKey       | AWS_S3_SECRET_ACCESS_KEY                                  | nx-api                                                      |
| secret.azureConnectionString      | AZURE_CONNECTION_STRING                                   | nx-api (only when azure.enabled is true)                    |
| secret.githubAuthClientId         | GITHUB_AUTH_CLIENT_ID                                     | frontend (when github.auth.enabled is true)                 |
| secret.githubAuthClientSecret     | GITHUB_AUTH_CLIENT_SECRET                                 | frontend (when github.auth.enabled is true)                 |
| secret.githubWebhookSecret        | NX_CLOUD_GITHUB_WEBHOOK_SECRET                            | frontend, nx-api (via nxCloud.frontend.scm.githubAppEnv)    |
| secret.githubAppId                | NX_CLOUD_GITHUB_APP_ID, NX_CLOUD_GITHUB_APP_APP_ID        | frontend, nx-api (via nxCloud.frontend.scm.githubAppEnv)    |
| secret.githubPrivateKey           | NX_CLOUD_GITHUB_PRIVATE_KEY                               | frontend, nx-api (via nxCloud.frontend.scm.githubAppEnv)    |
| secret.githubAppClientId          | NX_CLOUD_GITHUB_APP_CLIENT_ID                             | frontend, nx-api (via nxCloud.frontend.scm.githubAppEnv)    |
| secret.githubAppClientSecret      | NX_CLOUD_GITHUB_APP_CLIENT_SECRET                         | frontend, nx-api (via nxCloud.frontend.scm.githubAppEnv)    |
| awsS3.bucket                      | AWS_S3_BUCKET                                             | nx-api                                                      |
| awsS3.accelerated                 | AWS_S3_ACCELERATED (set to 'TRUE' when true)              | nx-api                                                      |
| awsS3.endpoint                    | AWS_S3_ENDPOINT                                           | nx-api                                                      |
| awsS3.enablePathStyleAccess       | AWS_S3_ENABLE_PATH_STYLE_ACCESS (set to 'TRUE' when true) | nx-api                                                      |
| azure.container                   | AZURE_CONTAINER                                           | nx-api                                                      |
| useCosmosDb                       | NX_CLOUD_USE_MONGO42 (set to 'false' when true)           | nx-api, aggregator                                          |
| gitlab.auth.enabled               | GITLAB_APP_ID, GITLAB_APP_SECRET                          | frontend                                                    |
| gitlab.apiUrl                     | GITLAB_API_URL                                            | frontend                                                    |
| github.auth.enabled               | GITHUB_AUTH_CLIENT_ID, GITHUB_AUTH_CLIENT_SECRET          | frontend                                                    |
| github.pr.apiUrl                  | GITHUB_API_URL                                            | frontend                                                    |
| bitbucket.auth.enabled            | BITBUCKET_APP_ID, BITBUCKET_APP_SECRET                    | frontend                                                    |
| bitbucket.apiUrl                  | BITBUCKET_API_URL                                         | frontend                                                    |
| saml.enabled                      | SAML_ENTRY_POINT, SAML_CERT                               | frontend                                                    |
| vcsHttpsProxy                     | VERSION_CONTROL_HTTPS_PROXY                               | frontend, nx-api                                            |

## Configuring record and artifact expiration

Pre-1.0 charts exposed a single `clearRecordsOlderThanDays` value that drove every expiration env var at once. That value has been removed in v1; expiration is now configured directly via env vars on the relevant components.

The aggregator CronJob deletes Mongo records and the file server deletes cached artifacts on disk. They run independently, so it is the operator's responsibility to keep them in sync.

### Important: keep the file server window longer than the hash window

If the file server deletes an artifact while its hash record still exists in Mongo, cache reads for that hash will fail with "artifact not found". Always set:

```
NX_CACHE_EXPIRATION_PERIOD_IN_DAYS  >  NX_CLOUD_DB_HASH_DATA_EXPIRATION_IN_DAYS
```

A one-day buffer is usually enough.

### Defaults

| Component   | Env var                                          | Code default (when unset) | Chart default                                  |
|-------------|--------------------------------------------------|---------------------------|------------------------------------------------|
| file server | `NX_CACHE_EXPIRATION_PERIOD_IN_DAYS`             | 28                        | `29` (set in `fileServer.deployment.env`)      |
| aggregator  | `NX_CLOUD_DB_RUN_DATA_EXPIRATION_IN_DAYS`        | 92                        | unset (falls back to code default)             |
| aggregator  | `NX_CLOUD_DB_HASH_DATA_EXPIRATION_IN_DAYS`       | 28                        | unset (falls back to code default)             |
| aggregator  | `NX_CLOUD_DB_HASH_DETAILS_EXPIRATION_IN_DAYS`    | 14                        | unset (falls back to code default)             |
| aggregator  | `NX_CLOUD_DB_TERMINAL_OUTPUTS_EXPIRATION_IN_DAYS`| 14                        | unset (falls back to code default)             |

The chart's default file server window (29) is one day longer than the default hash window (28), which is the safe ordering described above.

### Overriding the defaults

To shorten or extend retention, set the env vars directly. For example, to keep 7 days of hash data and clean files one day later:

```yaml
fileServer:
  deployment:
    env:
      NX_CACHE_EXPIRATION_PERIOD_IN_DAYS: "8"

aggregator:
  cronjob:
    env:
      NX_CLOUD_DB_RUN_DATA_EXPIRATION_IN_DAYS: "7"
      NX_CLOUD_DB_HASH_DATA_EXPIRATION_IN_DAYS: "7"
      NX_CLOUD_DB_HASH_DETAILS_EXPIRATION_IN_DAYS: "7"
      NX_CLOUD_DB_TERMINAL_OUTPUTS_EXPIRATION_IN_DAYS: "7"
```

If you only override the hash window, remember to bump the file server window to match.

## Using self-signed certificates

To add self-signed certificates to a Java keystore, you can use a combination of the `initContainers`, `extraObjects` and `extraVolumes` values.

1. Add a ConfigMap with a script that copies Java keystore files to a volume.
    ```yaml
    extraObjects:
      find-java-security:
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: nx-cloud-java-security-script
        data:
          find-java-security.sh: |
            #!/bin/sh
            # For Amazon Corretto, find the security directory dynamically
            if [ -n "$JAVA_HOME" ]; then
              # Use JAVA_HOME if available
              JAVA_PATH="$JAVA_HOME"
            else
              # Look for Corretto installations first
              for DIR in /usr/lib/jvm/java-*-amazon-corretto* /usr/lib/jvm/amazon-corretto-*; do
                if [ -d "$DIR" ]; then
                  JAVA_PATH="$DIR"
                  break
                fi
              done
            
              # Fallback to any Java installation if Corretto not found
              if [ -z "$JAVA_PATH" ]; then
                for DIR in /usr/lib/jvm/* /usr/java/*; do
                  if [ -d "$DIR" ]; then
                    JAVA_PATH="$DIR"
                    break
                  fi
                done
              fi
            fi
            
            # Check various possible security directory locations
            if [ -d "$JAVA_PATH/jre/lib/security" ]; then
              # Path found in some Corretto distributions, including Corretto 17
              cp -r "$JAVA_PATH/jre/lib/security" /cacerts
            elif [ -d "$JAVA_PATH/lib/security" ]; then
              # Alternative path in some Corretto and OpenJDK distributions
              cp -r "$JAVA_PATH/lib/security" /cacerts
            elif [ -d "$JAVA_PATH/conf/security" ]; then
              # Another alternative location in some JDK distributions
              cp -r "$JAVA_PATH/conf/security" /cacerts
            else
              echo "Could not find Java security directory in Corretto installation"
              # List all potential security directories for debugging
              find /usr -name "security" -type d 2>/dev/null | grep -i java
              exit 1
            fi
            echo "Successfully copied Java security files from $JAVA_PATH to /cacerts"
    ```

2. Create a ConfigMap with the certificates through the `extraObjects` value or by providing it through another mechanism such as External Secret Operator.
    ```yaml
    extraObjects:
      self-signed-certs:
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: self-signed-certs
        data:
          self-signed-cert.crt: |
            -----BEGIN CERTIFICATE-----
            ...
            -----END CERTIFICATE-----
            
            -----BEGIN CERTIFICATE-----
            ...
            -----END CERTIFICATE-----
    ```
3. Add values required to copy and store the certificates
    ```yaml
    aggregator:
      cronjob:
        initContainers:
          - command:
              - sh
              - /scripts/find-java-security.sh
            image: nxprivatecloud/nx-cloud-aggregator
            name: copy-cacerts
            volumeMounts:
              - mountPath: /cacerts
                name: cacerts
              - mountPath: /scripts
                name: java-security-script
         
        volumes:
          - name: cacerts
            emptyDir: {}
          - name: self-signed-certs-volume
            configMap:
              name: self-signed-certs  
          - name: java-security-script
            configMap:
              name: nx-cloud-java-security-script
    
        volumeMounts:
          - mountPath: /usr/lib/jvm/java-21-amazon-corretto/jre/lib/security
            name: cacerts
            subPath: security
          - mountPath: /self-signed-certs
            name: self-signed-certs-volume
    
    api:
      deployment:
        initContainers:
          - command:
              - sh
              - /scripts/find-java-security.sh
            image: nxprivatecloud/nx-cloud-nx-api
            name: copy-cacerts
            volumeMounts:
              - mountPath: /cacerts
                name: cacerts
              - mountPath: /scripts
                name: java-security-script
    
        volumes:
          - name: cacerts
            emptyDir: {}
          - name: self-signed-certs-volume
            configMap:
              name: self-signed-certs
          - name: java-security-script
            configMap:
              name: nx-cloud-java-security-script
    
        volumeMounts:
          - mountPath: /usr/lib/jvm/java-21-amazon-corretto/jre/lib/security
            name: cacerts
            subPath: security
          - mountPath: /self-signed-certs
            name: self-signed-certs-volume
    ```
