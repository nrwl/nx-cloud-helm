# Getting started with Nx Agents

We recommend deploying Nx Agents onto a new cluster, but you can also deploy onto your existing NxCloud cluster under a different namespace.

### Install Valkey

Valkey is an in-memory key-value store (like Redis) that is used by the workflow controller to hold temporary state.

1. Create a secret similar to `agents-guide/agents-secrets.yml` and create a valkey password in there.
   - Important: the key `valkey-password` needs to be remain unchanged
   - You do not need to set the secret values for the S3 bucket yet. They are there as an example. Please refer to `charts/nx-agents/values.yaml` for examples on what Agent storage options we support.
2. Apply the secret: `kubectl apply -f agents-secrets.yml`
3. Now let's deploy Valkey:
    ```bash
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm install valkey bitnami/valkey --set auth.usePassword=true --set auth.existingSecret=nx-cloud-agents-secret
    ```

### Deploy the Agents chart onto your cluster

```bash
helm repo add nx-cloud https://nrwl.github.io/nx-cloud-helm
helm repo update nx-cloud
helm upgrade --install nx-agents nx-cloud/nx-agents --values=nx-agents.yml
```

Use the values file in `charts/nx-agents/values.yaml` as an example.

Note on storage: 
1. The Agents need a storage bucket for storing logs as well as cached folders (such as `node_modules`)
2. You do not need to use S3, we also support Azure Blob Storage and GCloud buckets

### Connect NxCloud to your Nx Agents deployment

These are the options you can use to configure how NxCloud connects to your Nx Agents cluster.

Depending on how you deployed your Nx Agents cluster (which namespace you used, whether it was in the same or a different cluster etc.) you might need
to use different combinations of the below values.

Set these in your NxCloud `values.yaml` file:

```yaml
nxCloudWorkflows:
  enabled: true
  port: 9000
  name: 'nx-cloud-workflow-controller-service'
  workflowsNamespace: 'nx-cloud-workflows'

  # If externalName is left unset, the applications will look for ane existing service with the name defined
  # by `nxCloudWorkflows.name` in the namespace `nxCloudWorkflows.workflowsNamespace`. Use this option if you are
  # also running the nx-agents chart in the same cluster as this nx-cloud chart
  #
  # If externalName is set, an additional service will be created with the name `nxCloudWorkflows.name`
  # in the global namespace of this chart, and applications will use that service to connect to the workflow controller.
  # Use this option if your nx-agents are running in a different cluster than this nx-cloud chart
  externalName: ''

  # If you find that an externalName service is not working as expected, you can set this to true to create a headless service
  # which will create an endpoint group as an alternative. Please continue to set `externalName` to the IP address
  # you wish to direct traffic to as we will use it to populate the endpoint slice.
  headless: false
```

Please see `charts/nx-cloud/values.yaml` for up to date docs on the above options.

Finally, push the updates to your NxCloud cluster:

```bash
helm upgrade --install nx-cloud nx-cloud/nx-cloud --values=nx-cloud-values.yml
```