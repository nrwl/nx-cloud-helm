# EKS Installation

1. Configure your cluster's VPC to be auto-discoverable: https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
   1. This [video might help](https://www.youtube.com/watch?v=3WbEt_sfTWU)
2. Install the [AWS Load Balancer](https://aws.amazon.com/premiumsupport/knowledge-center/eks-alb-ingress-aws-waf/)
   1. Skip the parts where it says to create a K8S Ingress resource, we will let the NxCloud Helm chart create our Ingress
3. Configure a service account that is mapped to an IAM role that has access to the bucket you specified above
   1. See this article for hints: https://mjarosie.github.io/dev/2021/09/15/iam-roles-for-kubernetes-service-accounts-deep-dive.html
   2. Configure the NxCloud Ingress options to work with your new load balancer:

       ```
       image:
           tag: 'latest'
    
       nxCloudAppURL: 'https://nx-cloud.myorg.com'

       awsS3:
           enabled: true
           bucket: 'my-nxcloud-bucket'
           accelerated: true
           # see below, we'll add this later
           serviceAccountName: iam-test-access
           # accelerated: true  uncomment when using accelerated bucket
           # endpoint: ''  uncomment when using a custom endpoint
    
       ingress:
           class: 'alb'
           albScheme: 'internet-facing'
           albListenPorts: '[{"HTTPS":443}]'
           albCertificateArn: 'arn:aws:acm:us-east-1:411686525067:certificate/8adf7812-a1af-4eae-af1b-ea425a238a67'
    
       secret:
           name: 'cloud'
           nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
           adminPassword: 'ADMIN_PASSWORD'
       ```
   

   2. Optionally, you can also specify an access key ID and secret for an IAM user that has permission to connect to your bucket:
   
    ```
    image:
      tag: 'latest'
    
    nxCloudAppURL: 'https://nx-cloud.myorg.com'
    
    awsS3:
      enabled: true
      bucket: 'my-nxcloud-bucket'
      # accelerated: true  uncomment when using accelerated bucket
      # endpoint: ''  uncomment when using a custom endpoint
    
    secret:
      name: 'cloudsecret'
      nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
      adminPassword: 'ADMIN_PASSWORD'
      awsS3AccessKeyId: 'AWS_S3_ACCESS_KEY_ID'
      awsS3SecretAccessKey: 'AWS_S3_SECRET_ACCESS_KEY'
    ```

5. Apply the Helm chart you configured above: `helm upgrade --install nx-cloud --values=./values.yml`