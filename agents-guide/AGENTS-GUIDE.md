# Getting started with Nx Agents

We recommend deploying Nx Agents onto a new cluster, but you can also deploy onto your existing NxCloud cluster under a different namespace.

### Install Valkey

Valkey is an in-memory key-value store (like Redis) that is used by the workflow controller to hold temporary state.

1. Create a secret similar to `agents-guide/agents-secrets.yml` and set your valkey password in there.
   - Important: the key `valkey-password` itself shouldn't be changed, only its value
   - You do not need to set the secret values for the S3 bucket yet. They are there as an example. Please refer to `charts/nx-agents/values.yaml` for info on what Agent storage options we support.
2. Apply the secret: `kubectl apply -f agents-secrets.yml`
3. Now let's deploy Valkey:
    ```bash
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm install valkey bitnami/valkey --set auth.usePassword=true --set auth.existingSecret=nx-cloud-agents-secret
    ```

### Deploy the Agents chart onto your cluster

##### Configuring nx-agents.yaml
Here is an example `nx-agents.yml` config for deployment on AWS you can use as a starting point: [`basic-agents-config.yaml`](./basic-agents-config.yaml)
(you can also refer to the full [`values.yaml`](../charts/nx-agents/values.yaml) for full docs on all the values we support)

Modify your `nx-agents.yml` values file, and make sure the secrets we created above are linked up:
1. Ensure `secret.name: nx-cloud-agents-secret` (see [here](https://github.com/nrwl/nx-cloud-helm/blob/main/charts/nx-agents/values.yaml#L132))
2. Ensure `secret.valkeyPassword: 'valkey-password'`. The name needs to match the exact key you declared in the secret above (example [here](https://github.com/nrwl/nx-cloud-helm/blob/main/charts/nx-agents/values.yaml#L132)).

##### Deploying the Nx Agents cluster

Now you can push your chart changes so your controller can connect to valkey:

```bash
helm repo add nx-cloud https://nrwl.github.io/nx-cloud-helm
helm repo update nx-cloud
helm upgrade --install nx-agents nx-cloud/nx-agents --values=nx-agents.yml
```

###### Custom valkey URL

If you have deployed valkey in a custom location you can overwrite the default url:

```yaml
controller:
  useDefaultValkeyAddress: false # set this to false
  deployment:
    port: 9000
    env:
      - name: VALKEY_CONNECTION_STRING # declare the custom connection string
        valueFrom: # you can insert the value from a secret or hardcode it in the nx-agents.yml
          secretKeyRef:
            name: nx-cloud-k8s-secret
            key: valkey-connection-string
```
---
Note on storage:
1. The Agents need a storage bucket for storing logs and cached items (such as `node_modules`)
2. You do not need to use S3, we also support Azure Blob Storage and GCloud buckets
3. To choose a storage service you can configure the below values:
   - `NX_CLOUD_GCS_BUCKET=...`
   - `NX_CLOUD_AWS_BUCKET=...`
   - `AZURE_CONNECTION_STRING=...`
4. You'll then need to make sure your pods either have the correct service account attached for interacting with the above buckets (see [the AWS example](./AWS-AGENTS-GUIDE.md#connecting-an-s3-bucket))

### Connect NxCloud to your Nx Agents deployment

These are the options you can use to configure how NxCloud connects to your Nx Agents cluster.

Depending on how you deployed your Nx Agents cluster (which namespace you used, whether it was in the same or a different cluster etc.) you might need
to use different combinations of the below values.

Set these in your NxCloud `values.yaml` file:

```yaml
nxCloudWorkflows:
   enabled: true
   port: 9000
   
   # if you have deployed Nx Agents in the same cluster use these options
   name: 'nx-cloud-workflow-controller-service'
   workflowsNamespace: 'nx-cloud-workflows'

   # use these options if Nx Agents was deployed in a separate cluster
   externalName: 'external-address-or-ip.com'
   # If you find that an externalName service is not working as expected, you can set this to true to create a headless service
   # which will create an endpoint group as an alternative. Please continue to set `externalName` to the IP address
   # you wish to direct traffic to as we will use it to populate the endpoint slice.
   headless: false
```

Please see `charts/nx-cloud/values.yaml` for up to date documentation on the above options.

Finally, push the updates to your NxCloud cluster:

```bash
helm upgrade --install nx-cloud nx-cloud/nx-cloud --values=nx-cloud-values.yml
```