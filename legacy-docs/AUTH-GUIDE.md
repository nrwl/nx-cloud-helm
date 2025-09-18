# Configure GitHub App integration

If you want to setup our Pull Request integration, please follow this section. If you need instead to setup auth with GitHub, [scroll to the Auth section below](#configure-auth)

⚠️ *If you use any other source control provider ignore this section completely and follow the instructions on your NxCloud workspace setup screen.*

If you use GitHub, the best way to benefit from our integration is to set-up an app:
1. Please follow the instructions [here to setup your GitHub App](https://nx.dev/ci/recipes/enterprise/single-tenant/custom-github-app#creating-a-github-oauth-app)
2. Then configure the below values in your `helm-config.yaml`

```yaml
# helm-values.yml
secret:
  name: 'cloudsecret'
  nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
  adminPassword: 'ADMIN_PASSWORD'
  # define them here
  githubAppId: 'NX_CLOUD_GITHUB_APP_ID'
  githubPrivateKey: 'NX_CLOUD_GITHUB_PRIVATE_KEY'
  githubWebhookSecret: 'NX_CLOUD_GITHUB_WEBHOOK_SECRET'
  githubAppClientId: 'NX_CLOUD_GITHUB_APP_CLIENT_ID'
  githubAppClientSecret: 'NX_CLOUD_GITHUB_APP_CLIENT_SECRET'

# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudsecret
type: Opaque
stringData:
  NX_CLOUD_MONGO_SERVER_ENDPOINT: '....'
  ADMIN_PASSWORD: '....'
  NX_CLOUD_GITHUB_APP_ID: '<from the values in step 1>'
  NX_CLOUD_GITHUB_PRIVATE_KEY: '<from the values in step 1>'
  NX_CLOUD_GITHUB_WEBHOOK_SECRET: '<from the values in step 1>'
  NX_CLOUD_GITHUB_APP_CLIENT_ID: '<from the values in step 1>'
  NX_CLOUD_GITHUB_APP_CLIENT_SECRET: '<from the values in step 1>'
```

3. Finally, proceed to your NxCloud web app (and your workspace Settings screen) and finish the setup there

# Configure Auth

### GitHub Auth

To use GitHub for user authentication, you will need two values: `GITHUB_AUTH_CLIENT_ID` and `GITHUB_AUTH_CLIENT_SECRET`. Read [here](https://nx.dev/ci/recipes/enterprise/single-tenant/auth-github) on how to get
those values.

Then update your `helm-values.yaml` and `secrets.yaml`:

```yaml
# helm-values.yml
github:
    auth:
        enabled: true

secret:
  name: 'cloudsecret'
  nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
  adminPassword: 'ADMIN_PASSWORD'
  # define them here
  githubAuthClientId: 'GITHUB_AUTH_CLIENT_ID'
  githubAuthClientSecret: 'GITHUB_AUTH_CLIENT_SECRET'

# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudsecret
type: Opaque
stringData:
  NX_CLOUD_MONGO_SERVER_ENDPOINT: '....'
  ADMIN_PASSWORD: '....'
  GITHUB_AUTH_CLIENT_ID: '<from the values above>'
  GITHUB_AUTH_CLIENT_SECRET: '<from the values above>'
```


### GitLab Auth

To use GitHub for user authentication, you will need two values: `GITLAB_APP_ID` and `GITLAB_APP_SECRET`. Read [here](https://nx.dev/ci/recipes/enterprise/single-tenant/auth-gitlab) on how to get
those values.

Then update your `helm-values.yaml` and `secrets.yaml`:

```yaml
# helm-values.yml
gitlab:
    auth:
        enabled: true
        

secret:
  name: 'cloudsecret'
  nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
  adminPassword: 'ADMIN_PASSWORD'
  # define them here
  gitlabAppId: 'GITLAB_APP_ID'
  gitlabAppSecret: 'GITLAB_APP_SECRET'

# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudsecret
type: Opaque
stringData:
  NX_CLOUD_MONGO_SERVER_ENDPOINT: '....'
  ADMIN_PASSWORD: '....'
  GITLAB_APP_ID: '<from the values above>'
  GITLAB_APP_SECRET: '<from the values above>'
```

### Bitbucket Auth

To use GitHub for user authentication, you will need two values: `BITBUCKET_APP_ID` and `BITBUCKET_APP_SECRET`. Read [here](https://nx.dev/ci/recipes/enterprise/single-tenant/auth-bitbucket) on how to get
those values.

Then update your `helm-values.yaml` and `secrets.yaml`:

```yaml
# helm-values.yml
bitbucket:
    auth:
        enabled: true

secret:
  name: 'cloudsecret'
  nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
  adminPassword: 'ADMIN_PASSWORD'
  # define them here
  bitbucketAppId: 'BITBUCKET_APP_ID'
  bitbucketAppSecret: 'BITBUCKET_APP_SECRET'

# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudsecret
type: Opaque
stringData:
  NX_CLOUD_MONGO_SERVER_ENDPOINT: '....'
  ADMIN_PASSWORD: '....'
  BITBUCKET_APP_ID: '<from the values above>'
  BITBUCKET_APP_SECRET: '<from the values above>'
```

### SAML Auth

To use SAML for user authentication, you will need two values: `SAML_ENTRY_POINT` and `SAML_CERT`. Read [here](https://nx.dev/ci/recipes/enterprise/single-tenant/auth-bitbucket-data-center) on how to get
those values.

Then update your `helm-values.yaml` and `secrets.yaml`:

```yaml
# helm-values.yml
saml:
  enabled: true

secret:
  name: 'cloudsecret'
  nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
  adminPassword: 'ADMIN_PASSWORD'
  # define them here
  samlEntryPoint: 'SAML_ENTRY_POINT'
  samlCert: 'SAML_CERT'

# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudsecret
type: Opaque
stringData:
  NX_CLOUD_MONGO_SERVER_ENDPOINT: '....'
  ADMIN_PASSWORD: '....'
  SAML_ENTRY_POINT: '<from the values above>'
  SAML_CERT: '<from the values above>'
```
