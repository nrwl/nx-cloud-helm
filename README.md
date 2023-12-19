# Nx Cloud Helm Chart

A lot of organizations deploy Nx Cloud to Kubernetes.

This repo contains:

* Nx Cloud Helm Chart
* Instructions on how to install Nx Cloud using Helm
* Instructions on how to install Nx Cloud using kubectl. See [here](./no-helm/README.md).

## An important note on updates!

Please note, as of version `0.11.0` this helm chart is no longer compatible with legacy frontend containers by default. 

**To avoid issues, please ensure the container version you are targeting is >=** `2308.22.7`.

### Compatibility Matrix

| Chart Version | Compatible Images                  |
|---------------| ---------------------------------- |
| <= `0.10.11`  | `2306.01.2.patch4` **and earlier** |
| >= `0.11.0`   | `2308.22.7` **and later**          |
| >= `0.12.0`   | `2312.11.7` **and later**          |

## Deployments on AWS/EKS

If you're deploying on EKS, check out our [AWS Guide](./aws-guide/AWS-GUIDE.md). Otherwise, continue reading below.

## Installing Using Helm


### Step 1: OPTIONAL - Create Mongo replicas

Skip if you already have a hosted Mongo instance, such as Atlas or CosmosDB): [Install the Mongo Community operator](./MONGO-OPERATOR-GUIDE.md)


### Step 2: Create a secret

Create a secret by running `kubectl apply -f examples/secret.yml`

### Step 3: Install Nx Cloud using helm

```
> helm repo add nx-cloud https://nrwl.github.io/nx-cloud-helm
> helm install nx-cloud nx-cloud/nx-cloud --values=overrides.yml
```

`examples/overrides` contains the min overrides files. You need to provision:

1. The image tag you want to install
2. `nxCloudAppURL` which is the url used to access ingress from CI and dev machines (
   e.g., `https://nx-cloud.myorg.com`).
3. `secret/name` the name of the secret you created in Step 3.
4. `secret/nxCloudMongoServerEndpoint`, the name of the key from the secret.
   5`secret/adminPassword`, the name of the key from the secret.

If you only applied the secret from Step 3, the only thing you will need to change is `nxCloudAppURL`.

## Cloud Containers

The installation will create the following:

1. nx-cloud-frontend (deployment)
3. nx-cloud-nx-api (deployment)
4. nx-cloud-file-server (deployment)
5. nx-cloud-aggregator (cron job)

## Ingress, IP, Certificates

You can configure Ingress. For instance, the following will see the ingress class to 'gce', the global static ip name
to 'nx-cloud-ip', and will set a global Google managed certificate.

```yaml
global:
  imageTag: 'latest'

nxCloudAppURL: 'https://nx-cloud.myorg.com'

ingress:
  class: 'gce'
  globalStaticIpName: 'nx-cloud-ip'
  managedCertificates: 'cloud-cert'

secret:
  name: 'cloud'
  nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
  adminPassword: 'ADMIN_PASSWORD'
```

This configuration will look different for you. You will have a different global static ip and your cert name will also
be different. If you are interested in creating the two using GKE, check out the following links:

* [Reserving a static external IP address](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
* [Using Google-managed SSL certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs)

If you aren't using GKE, `ingress.class` will also be different. For example, see [our example config for AWS](https://github.com/nrwl/nx-cloud-helm/blob/main/aws-guide/helm-values.yml#L7) or check out the AWS Load Balancer set-up section [here for AWS set-up instructions.](./aws-guide/AWS-GUIDE.md#3-install-a-load-balancer)

If you need to have a detailed Ingress configuration, you can tell the package to skip defining ingress:

```yaml
image:
   tag: 'latest'

nxCloudAppURL: 'https://nx-cloud.myorg.com'

ingress:
    skip: true
```




<details>
<summary>⤵️ and then define it yourself (expand me)</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nx-cloud-ingress
  annotations:
     
  labels:
    app: nx-cloud
spec:
  rules:
    - http:
        paths:
          # define the next /file section only if you use the built-in file server
          - path: /file
            pathType: Prefix
            backend:
              service:
                name: nx-cloud-file-server-service
                port:
                  number: 5000
          - path: /nx-cloud
            pathType: Prefix
            backend:
              service:
                name: nx-cloud-nx-api-service
                port:
                  number: 4203
          - pathType: Prefix
            backend:
               service:
                  name: nx-cloud-frontend-service
                  port:
                     number: 8080
```

</details>

## Variations

### External File Storage

If you use AWS or Azure, you can configure Nx Cloud to store cached artifacts on S3 or Azure Blob. In this case, you
won't need the PVC or the file-server container. S3 and Azure Blob also tend to be faster.

For S3 buckets, see the [AWS Guide](./aws-guide/AWS-GUIDE.md#6-external-s3-access)

For Azure:

```yaml
global:
  imageTag: 'latest'

nxCloudAppURL: 'https://nx-cloud.myorg.com'

azure:
  enabled: true
  container: 'nx-cloud'

secret:
  name: 'cloudsecret'
  nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
  adminPassword: 'ADMIN_PASSWORD'
  azureConnectionString: 'AZURE_CONNECTION_STRING'
```

Note that the secret for setting up Azure must contain `AZURE_CONNECTION_STRING`.

### Auth

Please refer to [this guide](./AUTH-GUIDE.md).

### GitHub Integration

To enable the GitHub PR integration, you can use the following configuration:

```yaml
global:
  imageTag: 'latest'

nxCloudAppURL: 'https://nx-cloud.myorg.com'

github:
  pr:
    enabled: true
    # apiUrl: '' uncomment when using github enterprise 

secret:
  name: 'cloudsecret'
  nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
  githubWebhookSecret: 'GITHUB_WEBHOOK_SECRET'
  githubAuthToken: 'GITHUB_AUTH_TOKEN'
```

Note that the secret must contain `GITHUB_WEBHOOK_SECRET` and `GITHUB_AUTH_TOKEN`.
Read [here](https://nx.dev/nx-cloud/private-cloud/github) on how to get those values.

## Proxies and self-signed certificates

Please refer to [this guide](./PROXY-GUIDE.md).

## Suggested resources

Suggested resources for the NxCloud cluster are (you can always start with less and scale up to this as needed):
- 9 vCPUS
- 23GB memory
- Or you can use the equivalent of 5 `t3.medium` AWS Nodes (or 7 if running Mongo)

Disk size:
- The biggest resource consideration will be the permanent Volume where your cached artefacts will be stored. This depends on the size/activity of the workspace. You can start with 20-50GB and scale up if needed.
- For Mongo, 5-10GB should be enough

## More Information

You can find more information about Nx Cloud and running it on
prem [here](https://nx.dev/nx-cloud/private-cloud/get-started).
