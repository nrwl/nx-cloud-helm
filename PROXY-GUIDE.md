## NxCloud runner proxy issues

If you have an HTTP proxy, you will need to configure the runner to use your proxy when downloading and uploading artefacts:

1. `yarn add hpagent`
2. Create a new file `custom-proxy-config.js`
3. Customise your proxy using the HPAgent however you like:
   ```javascript
   const { HttpsProxyAgent } = require('hpagent');
    
   const proxyConfig = (nxDefaultConfig) => ({
     ...nxDefaultConfig,
     proxy: false,
     httpsAgent: new HttpsProxyAgent({
       proxy: 'https://your-customproxy.com:4042', // <-- enter your custom proxy details here
       ca: [""], // <-- optional path to a certificate authority
       rejectUnauthorized: false // <-- set this to false if you want it to ignore invalid certificate warnings
     })
   });

   module.exports = {
     nxCloudProxyConfig: proxyConfig,
     fileServerProxyConfig: proxyConfig
   }
    ```
4. Point the nx-cloud runner to your custom config:

    ```json
     "tasksRunnerOptions": {
        "default": {
          "runner": "@nrwl/nx-cloud",
          "options": {
            "accessToken": "…..",
            "cacheableOperations": [
               ….
            ],
            "url": "….",
            "customProxyConfigPath": "./custom-proxy-config.js" <--- here
          }
        }
      },
    ```

## Proxies and external services support (S3, Github etc.)

If you have an internal cluster but are using an external S3 bucket, then your proxy might block connections
from the NxAPI to your S3 bucket. The same issue will happen with connection to your Github/Gitlab instance.

For that, you can try forcing the connection to bypass the proxy by setting the [`NO_PROXY=amazonaws.com,your-github-instance.com`](https://about.gitlab.com/blog/2021/01/27/we-need-to-talk-no-proxy/) env var on your
NxAPI pods.



## Supporting Self-Signed SSL Certificates

If you are using a self-hosted Gitlab or Github instance, or a proxy, you will need to provide the extra CAs
to NxCloud pods.

1. Upload your cert as a ConfigMap

   ```bash
   kubectl create configmap self-signed-certs --from-file=self-signed-cert.crt=./cert.pem
   ```

2. Point your Helm values to the config map:
   ```yaml
   selfSignedCertConfigMap: 'self-signed-certs'
   ```