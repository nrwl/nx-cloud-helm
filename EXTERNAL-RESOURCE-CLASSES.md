# External Resource Classes Configuration

## Overview

Nx Cloud supports configuring resource classes for agents through an external ConfigMap. This feature allows you to define different resource classes for your agents without having to rebuild the Nx Cloud image or modify the Helm chart values directly.

## Requirements

This feature is only available with the following versions:

- nx-cloud chart version >= 0.15.15
- nx-agents chart version >= 1.2.11
- Nx Cloud image versions 2504.01 and newer

## Configuring the Application

### Recommended Approach: Using extraManifests

The simplest way to configure resource classes is to define the ConfigMap directly in your Helm values file using the `extraManifests` feature. This allows you to deploy the ConfigMap alongside the chart without having to create it separately:

```yaml
extraManifests:
  resource-class-config:
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: resource-class-config
    data:
      agentConfigs.yaml: |
        resourceClasses:
          - identifier: my-custom-resource-class-small
            architecture: amd64
          - identifier: my-custom-resource-class-medium
            architecture: amd64
          - identifier: my-custom-resource-class-large
            architecture: amd64

resourceClassConfiguration:
  name: "resource-class-config"      # Name of the configmap containing resource class configuration
  path: "agentConfigs.yaml"         # Path to the specific key within the configmap that contains the configuration
```

With this approach, you can define, deploy, and reference the ConfigMap all in one Helm values file, making it easier to manage your configuration.

**Important Notes:**
- Both `name` and `path` properties are required if this feature is used
- The `path` value should match the key in your ConfigMap that contains the resource class configuration

### Alternative Approach: Creating a ConfigMap Separately

Alternatively, you can create the ConfigMap separately and then reference it in your Helm values:

1. Create a ConfigMap containing your resource class configuration. The configuration should be in YAML format and follow the structure shown in the example below:

```yaml
resourceClasses:
  - identifier: my-custom-resource-class-small
    architecture: amd64

  # Add more resource classes as needed

```

2. Create the ConfigMap using kubectl:

```bash
kubectl create configmap resource-class-config --from-file=agentConfigs.yaml=/path/to/your/config.yaml -n your-namespace
```

3. Update your Nx Cloud Helm values to reference the ConfigMap:

```yaml
resourceClassConfiguration:
  name: "resource-class-config"      # Name of the configmap containing resource class configuration
  path: "agentConfigs.yaml"         # Path to the specific key within the configmap that contains the configuration
```

## How It Works

When configured, the Nx Cloud Helm chart will:

1. Mount the specified ConfigMap to the Nx Cloud API and Aggregator pods
2. Set the environment variable `NX_CLOUD_RESOURCE_CLASS_FILEPATH` to point to the mounted configuration file
3. The Nx Cloud services will read this configuration and use it to determine the resource requirements for agent pods

## Deployment

Once you've configured your resource classes using one of the approaches above, deploy or upgrade your Nx Cloud Helm release:

```bash
helm upgrade nx-cloud nx-cloud/nx-cloud -f values.yaml -n nx-cloud
```

## Configuring the Workflow Controller

When using custom resource classes, the Workflow Controller must be provided a list of resource classes where the identifiers match the ones provided to the application chart. The configuration follows a similar pattern but is applied to the workflow controller's values file.

### Using extraManifests in the Workflow Controller

```yaml
extraManifests:
  resourceclasses:
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: agent-configuration
    data:
      agentConfigs.yaml: |
        resourceClasses:
        - platform: docker
          architecture: amd64
          os: linux
          identifier: my-custom-resource-class-small
          size: small
          cpu: "1"
          memory: "2Gi"
          memoryLimit: "3.5Gi"
          cpuLimit: "1.5"
        - platform: docker
          architecture: amd64
          os: linux
          identifier: my-custom-resource-class-medium
          size: medium
          cpu: "2"
          memory: "4Gi"
          memoryLimit: "5.5Gi"
          cpuLimit: "3"
        - platform: docker
          architecture: amd64
          os: linux
          identifier: my-custom-resource-class-large
          size: large
          cpu: "3"
          memory: "8Gi"
          memoryLimit: "9.5Gi"
          cpuLimit: "6"
        # You can also configure agent affinities if needed
        agentAffinities:
          - affinity:
              nodeAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  nodeSelectorTerms:
                    - matchExpressions:
                        - key: nx.app/node-role
                          operator: In
                          values:
                            - agent
            targetClasses:
              - my-custom-resource-class-small
              - my-custom-resource-class-medium
          - affinity:
              nodeAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  nodeSelectorTerms:
                    - matchExpressions:
                        - key: cloud.google.com/gke-nodepool
                          operator: In
                          values:
                            - high-performance-pool
            targetClasses:
              - my-custom-resource-class-large
```

### Configuring the Workflow Controller Deployment

In addition to creating the ConfigMap with resource classes, you need to configure the workflow controller deployment to mount the ConfigMap and set the appropriate environment variable. Add the following to your workflow controller values file:

```yaml
controller:
  deployment:
    # Other deployment configuration...
    env:
      # Other environment variables...
      - name: K8S_RESOURCECLASS_CONFIG_PATH
        value: "/opt/nx-cloud/resource-classes/agentConfigs.yaml"
    volumes:
      - name: resource-classes-config
        configMap:
          name: agent-configuration  # Must match the name in your extraManifests
          items:
            - key: agentConfigs.yaml  # Must match the key in your ConfigMap
              path: agentConfigs.yaml
    volumeMounts:
      - name: resource-classes-config
        mountPath: /opt/nx-cloud/resource-classes
```

This configuration:

1. Creates a volume named `resource-classes-config` that references the ConfigMap containing your resource class definitions
2. Mounts this volume to the path `/opt/nx-cloud/resource-classes` in the workflow controller container
3. Sets the environment variable `K8S_RESOURCECLASS_CONFIG_PATH` to point to the specific file within the mounted volume

The workflow controller will read this configuration file to determine the resource requirements for agent pods and apply the appropriate affinities when scheduling them.

### Resource Class Properties

#### Required Fields for API and Aggregator

For the Nx Cloud API and Aggregator components, only the following fields are required:

- **identifier**: Unique identifier for the resource class
- **architecture**: CPU architecture (e.g., amd64, arm64)

#### Additional Fields for Workflow Controller

The following fields are required by the workflow controller in the nx-cloud-workflow-controller chart:

- **identifier**: Unique identifier for the resource class
- **architecture**: CPU architecture (e.g., amd64, arm64)
- **platform**: The container platform (e.g., docker)
- **os**: Operating system (e.g., linux)
- **size**: Human-readable size name
- **cpu**: Requested CPU resources
- **memory**: Requested memory resources
- **cpuLimit**: CPU limit
- **memoryLimit**: Memory limit

### Agent Affinities

The `agentAffinities` section allows you to control which resource classes are scheduled on specific nodes based on node labels or other Kubernetes affinity rules. Each affinity consists of two parts:

1. **affinity**: A standard Kubernetes affinity definition that determines which nodes are eligible for scheduling. This is a direct 1:1 mapping with Kubernetes affinity rules and supports all the same properties (requiredDuringSchedulingIgnoredDuringExecution, preferredDuringSchedulingIgnoredDuringExecution, etc.).

2. **targetClasses**: A list of resource class identifiers that should be scheduled according to this affinity rule. These identifiers must match resource classes defined in the `resourceClasses` section.

Example:
```yaml
agentAffinities:
  - affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: nx.app/node-role
                  operator: In
                  values:
                    - agent
    targetClasses:
      - my-custom-resource-class-small
      - my-custom-resource-class-medium
```

In this example, the `my-custom-resource-class-small` and `my-custom-resource-class-medium` resource classes will only be scheduled on nodes with the label `nx.app/node-role: agent`.

## Troubleshooting

If you encounter issues with the resource class configuration:

1. Verify that both the `name` and `path` properties are correctly set in your Helm values
2. Check that the ConfigMap exists in the correct namespace
3. Ensure the key specified in the `path` property exists in the ConfigMap
4. Validate that your resource class configuration follows the correct format
5. Check the logs of the Nx Cloud API and Aggregator pods for any error messages related to resource class configuration

