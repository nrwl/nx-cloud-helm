# Nx Cloud Helm Chart

A lot of organizations deploy Nx Cloud to Kubernetes.

This repo contains:

* Nx Cloud Helm Chart
* Instructions on how to install Nx Cloud using Helm
* Instructions on how to install Nx Cloud using kubectl. See [here](./no-helm/README.md).

## Installing Using Helm

Steps:

1. Deploy MongoDB Kubernetes Operator
    * using helm: https://github.com/mongodb/helm-charts
    * using kubectl: https://github.com/mongodb/mongodb-kubernetes-operator
2. Create a mongodb replica set
3. Create a secret
4. Install Nx Cloud using helm

### Step 1: Deploy MongoDB Kubernetes Operator

If you are using a hosted MongoDB installation (e.g., Mongo Atlas or CosmosSB, or you are running one yourself), you can
skip steps 1 and 2.

```
> helm repo add mongodb https://mongodb.github.io/helm-charts
> helm install community-operator mongodb/community-operator
```

### Step 2: Deploy a MongoDB replica set

```
> kubectl apply -f examples/mongodb.yml
```

This will create a secret. You can get the value of the secret as follows:

```
> kubectl get secret cloud-mongodb-nrwl-api-admin-user -o go-template='{{range $k,$v := .data}}{{"### "}}{{$k}}{{"n"}}{{$v|base64decode}}{{"nn"}}{{end}}'
```

You might need to wait a bit for the Pods to be created before this secret will be available.

The result should look like
this: `mongodb+srv://admin-user:DB_PASSWORD@cloud-mongodb-svc.default.svc.cluster.local/nrwl-api?replicaSet=cloud-mongodb&ssl=false`
.

Extract the connection string and paste it into your `secret.yml`.

### Step 3: Create a secret

Create a secret by running `kubectl apply -f examples/secret.yml`

### Step 4: Install Nx Cloud using helm

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
2. nx-cloud-api (deployment)
3. nx-cloud-nx-api (deployment)
4. nx-cloud-file-server (deployment)
5. nx-cloud-aggregator (cron job)

## Ingress, IP, Certificates

You can configure Ingress. For instance, the following will see the ingress class to 'gce', the global static ip name
to 'nx-cloud-ip', and will set a global Google managed certificate.

```yaml
image:
  tag: 'latest'

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

If you aren't using GKE, `ingress.class` will also be different.

## Variations

### External File Storage

If you use AWS or Azure, you can configure Nx Cloud to store cached artifacts on S3 or Azure Blob. In this case, you
won't need the PVC or the file-server container. S3 and Azure Blob also tend to be faster.

```yaml
image:
  tag: 'latest'

nxCloudAppURL: 'https://nx-cloud.myorg.com'

awsS3:
  enabled: true
  bucket: 'nx-cloud'
  # accelerated: true  uncomment when using accelerated bucket
  # endpoint: ''  uncomment when using a custom endpoint

secret:
  name: 'cloudsecret'
  nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
  adminPassword: 'ADMIN_PASSWORD'
  awsS3AccessKeyId: 'AWS_S3_ACCESS_KEY_ID'
  awsS3SecretAccessKey: 'AWS_S3_SECRET_ACCESS_KEY'
```

```yaml
image:
  tag: 'latest'

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

Note that the secret must contain `AWS_S3_ACCESS_KEY_ID`, `AWS_S3_SECRET_ACCESS_KEY` or `AZURE_CONNECTION_STRING`.

### GitHub Auth

To use GitHub for user authentication, you can use the following configuration:

```yaml
image:
  tag: 'latest'

nxCloudAppURL: 'https://nx-cloud.myorg.com'

github:
  auth:
    enabled: true

secret:
  name: 'cloudsecret'
  nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
  githubAuthClientId: 'GITHUB_AUTH_CLIENT_ID'
  githubAuthClientSecret: 'GITHUB_AUTH_CLIENT_SECRET'
```

Note that the secret must contain `GITHUB_AUTH_CLIENT_ID` and `GITHUB_AUTH_CLIENT_SECRET`.
Read [here](https://nx.dev/nx-cloud/private-cloud/auth-github) on how to get those values.

### GitHub Integration

To enable the GitHub PR integration, you can use the following configuration:

```yaml
image:
  tag: 'latest'

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

## More Information

You can find more information about Nx Cloud and running it on
prem [here](https://nx.dev/nx-cloud/private-cloud/get-started).
