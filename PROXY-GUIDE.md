## NxCloud runner proxy issues 

If you have an HTTP proxy, you will need to configure the runner to use your proxy when downloading and uploading artefacts:

1. `yarn add hpagent`
2. Create a new file `custom-proxy-config.js`
3. Customise your proxy using the HPAgent however you like:
   ```javascript
    const {HttpsProxyAgent} = require('hpagent');
    
    const proxyConfig = (nxDefaultConfig) => ({
     ...nxDefaultConfig,
     proxy: false,
     httpsAgent: new HttpsProxyAgent({
       proxy: 'https://your-customproxy.com:4042', // <-- enter your custom proxy details here
       ca: [""], // --- optional path to a certificate authority
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

## External S3 bucket

If you have an internal cluster but are using an external S3 bucket, then your proxy might block connections 
from the NxAPI to your S3 bucket.

For that, you can try forcing the connection to bypass the proxy by setting the [`NO_PROXY=amazonaws.com`](https://about.gitlab.com/blog/2021/01/27/we-need-to-talk-no-proxy/) env var on your
NxAPI pods.

## Supporting Self-Signed SSL Certificates

If you are using a self-hosted Gitlab or Github instance, or a proxy, you will need to provide the extra CAs
to NxCloud pods.

There are two pods that will talk to your GitHub/Gitlab instance, and they both need to be made aware 
of the location of your certificate:
1. `nx-cloud-api`: this is Node based backend. 
   1. If you are using self-signed certs on your GitHub instance
      1. You will need to set `NODE_EXTRA_CA_CERTS=./path-to-ca.pem` on it
      2. And make sure the `.pem` file is available on the pod's filesystem
   2. If you are using a proxy
      1. you can try adding the `NO_PROXY=your-github-instance.com` env var to your pod, or the `NODE_EXTRA_CA_CERTS=./path-to-ca.pem` path to your proxy CA
2. `nx-cloud-nx-api`: this is a Java based backend
   1. If you are using a self-signed certs on your GitHub instance
      1. [Expose your root CA to the JVM](https://stackoverflow.com/a/4326346)
   2. If you are using a proxy
      1. You can try adding the `NO_PROXY=your-github-instance.com` env var to the pod



