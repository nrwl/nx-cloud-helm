# Getting started with Nx Agents

We recommend deploying Nx Agents onto a new cluster, but you can also deploy onto your existing NxCloud cluster under a different namespace.

### Install Valkey

Valkey is an in-memory DB (like Redis) that is used by the workflow controller to store temporary state.

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