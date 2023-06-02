### GitHub Auth

To use GitHub for user authentication, you will need two values: `GITHUB_AUTH_CLIENT_ID` and `GITHUB_AUTH_CLIENT_SECRET`. Read [here](https://nx.dev/nx-cloud/private-cloud/auth-github) on how to get
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

To use GitHub for user authentication, you will need two values: `GITLAB_APP_ID` and `GITLAB_APP_SECRET`. Read [here](https://nx.dev/nx-cloud/private-cloud/auth-gitlab) on how to get
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

To use GitHub for user authentication, you will need two values: `BITBUCKET_APP_ID` and `BITBUCKET_APP_SECRET`. Read [here](https://nx.dev/nx-cloud/private-cloud/auth-bitbucket) on how to get
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

To use GitHub for user authentication, you will need two values: `GITHUB_AUTH_CLIENT_ID` and `GITHUB_AUTH_CLIENT_SECRET`. Read [here](https://nx.dev/nx-cloud/private-cloud/auth-saml) on how to get
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