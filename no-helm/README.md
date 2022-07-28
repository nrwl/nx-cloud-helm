# Nx Cloud & K8s Example

A lot of organizations deploy Nx Cloud to Kubernetes. This repo is an example of how to deploy Nx Cloud to
Google Cloud (GKE) without using helm. See the docs on [installing Nx Cloud using helm](../README.md) (which is
recommended).

## Steps

1. Create a GKE cluster
2. Deploy MongoDB Kubernetes Operator. [See here](https://github.com/mongodb/mongodb-kubernetes-operator)
3. Create a MongoDB replica set by running `kubectl apply -f examples/mongodb.yml`
4. Create a persistent volume claim by running `kubectl apply -f no-helm/pvc.yml`
5. Create Nx Cloud containers by running `kubectl apply -f no-helm/cloud.yml` (you need to
   replaces `NX_CLOUD_APP_URL_VALUE`
   , `NX_CLOUD_MONGO_SERVER_ENDPOINT_VALUE` and `ADMIN_PASSWORD_VALUE` with correct values first).

See the information below about each step.

## MongoDB

If you are using a hosted MongoDB installation (e.g., Mongo Atlas or CosmosSB, or you are running one yourself), you can
skip steps 2 and 3.

## Nx Cloud Containers

The `cloud.yml` file defines the following:

1. nx-cloud-frontend (deployment)
2. nx-cloud-api (deployment)
3. nx-cloud-nx-api (deployment)
4. nx-cloud-file-server (deployment)
5. nx-cloud-aggregator (cron job)

## Ingress, IP, Certificates

THe `cloud.yml` file also configures ingress, which contains the following:

```yaml
annotations:
  kubernetes.io/ingress.global-static-ip-name: nx-cloud-ip
  networking.gke.io/managed-certificates: cloud-cert
  kubernetes.io/ingress.class: 'gce'
```

This configuration will look different for you. You will have a different global static ip and your cert name will also
be different. If you are interested in creating the two using GKE, check out the following links:

* [Reserving a static external IP address](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
* [Using Google-managed SSL certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs)

If you aren't using GKE, `ingress.class` will also be different.

## Env Variables

* `NX_CLOUD_APP_URL` - this is the url used to access ingress from CI and dev machines (
  e.g., `https://nx-cloud.myorg.com`).
* `NX_CLOUD_MONGO_SERVER_ENDPOINT` - the connection string used by apis to connect to MongoDB (starts
  with `mongodb+srv://`).
* `ADMIN_PASSWORD` - the password used by the admin user.

`cloud.yml` contains the following placeholder values: `NX_CLOUD_APP_URL_VALUE` , `NX_CLOUD_MONGO_SERVER_ENDPOINT_VALUE`
and `ADMIN_PASSWORD_VALUE`. You need to replace them before running `kubectl apply -f cloud.yml`. For production
deployments we strongly recommend you don't embed those values in `cloud.yml` and instead use a secure way to define
them.

## Variations

### External File Storage

If you use AWS or Azure, you can configure Nx Cloud to store cached artifacts on S3 or Azure Blob. In this case, you
won't need the PVC or the file-server container. S3 and Azure Blob also tend to be faster.

[cloud-aws.yml](./cloud-aws.yml) is an example configuration using S3. The three value you will need to replaces
are `AWS_S3_ACCESS_KEY_ID_VALUE` , `AWS_S3_SECRET_ACCESS_KEY_VALUE` , and `AWS_S3_BUCKET_VALUE`.

If you are using Azure Blob, the configuration will look the same except that:

```yaml
- name: AWS_S3_ACCESS_KEY_ID
  value: AWS_S3_ACCESS_KEY_ID_VALUE
- name: AWS_S3_SECRET_ACCESS_KEY
  value: AWS_S3_SECRET_ACCESS_KEY_VALUE
- name: AWS_S3_BUCKET
  value: AWS_S3_BUCKET_VALUE
```

will have to be replaced with:

```yaml
- name: AZURE_CONNECTION_STRING
  value: AZURE_CONNECTION_STRING_VALUE
- name: AZURE_CONTAINER
  value: AZURE_CONTAINER_VALUE
```

### GitHub Auth

To use GitHub for user authentication, you need to pass the `GITHUB_AUTH_CLIENT_ID` and `GITHUB_AUTH_CLIENT_SECRET` env
variables to the `nx-cloud-api` container. Read [here](https://nx.dev/nx-cloud/private-cloud/auth-github) on how to get
those values.

### GitHub Integration

To enable the GitHub PR integration, pass the `GITHUB_WEBHOOK_SECRET`, `GITHUB_AUTH_TOKEN`, and `GITHUB_API_URL` env
variables to the `nx-cloud-nx-api` container. Read [here](https://nx.dev/nx-cloud/private-cloud/github) on how to get
those
values.

### GitLab Auth

To use GitLab for user authentication, you need to pass the `GITLAB_APP_ID` and `GITLAB_APP_SECRET` env variables to
the `nx-cloud-api` container. Read [here](https://nx.dev/nx-cloud/private-cloud/auth-gitlab) on how to get those values.

## More Information

You can find more information about Nx Cloud and running it on
prem [here](https://nx.dev/nx-cloud/private-cloud/get-started).
