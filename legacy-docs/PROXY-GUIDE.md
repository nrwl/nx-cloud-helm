## Nx Cloud Proxy Issues

If you have an HTTP proxy, you will need to configure the runner to use it when downloading and uploading artifacts. We recommend using the library `hpagent` for this:

1. `yarn add hpagent`
2. Create a new file `custom-proxy-config.js`
3. Customise your proxy using the HPAgent however you like:
   ```javascript
   const { HttpsProxyAgent } = require('hpagent');
    
   const proxyConfig = (nxDefaultConfig) => ({
     ...nxDefaultConfig,
     proxy: false,
     httpsAgent: new HttpsProxyAgent({
       proxy: 'https://your-customproxy.com:4042', // <-- your custom proxy url
       ca: [""], // <-- optional path to a certificate authority
       rejectUnauthorized: false // <-- set this to false if you want to ignore invalid certificate warnings - ⚠️ Not Recommended
     })
   });

   module.exports = {
     nxCloudProxyConfig: proxyConfig,
     fileServerProxyConfig: proxyConfig
   }
    ```
4. Point the runner to your custom configuration:

    ```json
     "tasksRunnerOptions": {
        "default": {
          "runner": "nx-cloud",
          "options": {
            "accessToken": "…..",
            "cacheableOperations": [
               ….
            ],
            "url": "….",
            "customProxyConfigPath": "./custom-proxy-config.js" // <--- here
          }
        }
      },
    ```

## Proxies and external services support (S3, Github etc.) 

If you have an internal cluster but are using an external S3 bucket, then your proxy might block connections 
from the NxAPI to your S3 bucket. The same issue will happen with connection to your Github/Gitlab instance.

For that, you can try forcing the connection to bypass the proxy by setting the [`NO_PROXY=amazonaws.com,your-github-instance.com`](https://about.gitlab.com/blog/2021/01/27/we-need-to-talk-no-proxy/) env var on your
NxAPI pods.

If you need the calls to go through a proxy, you can define this at the root of your `helm-values.yaml`:

```yaml
vcsHttpsProxy: 'http://your-proxy.com:80'
```

## Self-Signed SSL Certificates

If you have set-up your NxCloud cluster with a self-signed certificate you can use the same strategy as in the case of running behind a proxy, but this time you can use `node:https`. Change the contents of the `custom-proxy-config.js` file detailed above to the following:

  ```javascript
  const https = require('node:https');
  
  const selfSignedConfig = (nxDefaultConfig) => ({
    ...nxDefaultConfig,
    proxy: false,
    httpsAgent: new https.Agent({
      ca: "./path/to/your/certificate.pem", // <-- path to the self-signed certificate
    })
  });

  module.exports = {
    nxCloudProxyConfig: selfSignedConfig,
    fileServerProxyConfig: selfSignedConfig,
  }
  ```


## Self-hosted Services

If you are using a self-hosted service such as Gitlab or Github and securing connections to them with a self-signed certificate, you will need to provide the extra certificates to the Nx Cloud pods:

1. Upload your cert as a ConfigMap

   ```bash
   kubectl create configmap self-signed-certs --from-file=self-signed-cert.crt=./cert.pem
   ```

2. Point your Helm values to the config map:
   ```yaml
   selfSignedCertConfigMap: 'self-signed-certs'
   ```

#### Pre-built Java cacerts 

If you provide a custom `cert.pem` file above, containing multiple certs, because the Java services need to be import each one by one into the keystore, this can sometimes result in long
nx-api pod startup times. As an alternative, you can "pre-build" a Java keystore containing your custom CAs:

1. Pull our "custom keystore creator" Docker image: `docker pull nxprivatecloud/create-custom-cacerts:latest`
2. Make sure your custom `cert.pem` file is available locally, for example in `${HOME}/custom-certs/cert.pem` (make sure it's called `cert.pem`)
3. Run the image and mount the folder where your `cert.pem` file is located: `docker run -v ${HOME}/custom-certs:/certs nxprivatecloud/create-custom-cacerts:latest`
4. The image will import all your custom certs and should output a new custom certs store for you in your mounted folder: `${HOME}/custom-certs/cacerts`
5. Apply a new configmap with this: `cd ${HOME}/custom-certs && kubectl create configmap pre-built-java-cert-store --from-file=cacerts=./cacerts`
6. Add this option to your Helm values file: 
    ```yaml
   preBuiltJavaCertStoreConfigMap: 'pre-built-java-cert-store'
   ```
7. IMPORTANT: make sure you keep your previously created `self-signed-certs` configMap and the `selfSignedCertConfigMap` option also stays defined in your Helm values. The frontend pod will continue to need this.