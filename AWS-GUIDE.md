# EKS Installation

1. Create a new cluster config file for EKS and give it enough compute resources to scale up when necesarry: 

```yaml
# cluster.yaml

apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: nx-cloud-cluster
  region: us-east-1

nodeGroups:
   - name: ng-2
     instanceType: t3.medium
     desiredCapacity: 4
     volumeSize: 5
```

2. `eksctl create cluster -f cluster.yaml` `create cluster --name in28minutes-cluster --nodegroup-name in28minutes-cluster-node-group  --node-type t2.medium --nodes 3 --nodes-min 3 --nodes-max 7 --managed --asg-access --zones=us-east-1a,us-east-1b`
   1. Notes on resources:
      1. the NxCloud services do not require a lot of compute power. Open up [the K8s templates here](https://github.com/nrwl/nx-cloud-helm/blob/main/nx-cloud/templates/cloud.yml) and look for `resource` annotations - this will tell you how many resources each Pod needs. 
      2. the biggest resource you'll need to consider is space required for your cache. Depending on whether you're using an external S3 bucket, or internal Pods to your cluster (both will be configured below), you might need to allocate a few GBs of space later on, the more active your workspace is.
      3. Make sure to [configure autoscaling](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html#cluster-autoscaler) so you only create Nodes that are needed

3. Switch contexts
   1. `kubectl config get-contexts`
   2. `kubectl config use-context <your-new-cluster-context>`

4. Create an IAM OIDC provider associated with your cluster
   3. `eksctl utils associate-iam-oidc-provider --cluster=nx-cloud-cluster --approve`
   1. This will help us authenticate with all kinds of services below from within the cluster using Service Accounts
   2. See [this](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) and this [deep dive](https://mjarosie.github.io/dev/2021/09/15/iam-roles-for-kubernetes-service-accounts-deep-dive.html) for more details

## 1. Using a Mongo operator

NxCloud needs a Mongo database to store details about your runs and record your hashes. You can either point it to your existing external Mongo instance or let it create its own inside the above cluster.
Below, we'll create one inside the cluster. **If you already have an external Mongo instance, you can skip this section.**

1. Create your Amazon EBS CSI plugin IAM role ():

   ```shell
   eksctl create iamserviceaccount \
     --name ebs-csi-controller-sa \
     --namespace kube-system \
     --cluster nx-cloud-cluster \
     --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
     --approve \
     --override-existing-serviceaccounts \
     --role-only \
     --role-name AmazonEKS_EBS_CSI_DriverRole
   ```
   
   1. See [guide here](https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html) for explanation on the above and more advanced options

2. Add the Amazon EBS CSI add-on:
   1. Replace `111122223333` with your account ID
   
   ```shell
   eksctl create addon --name aws-ebs-csi-driver --cluster nx-cloud-cluster --service-account-role-arn arn:aws:iam::111122223333:role/AmazonEKS_EBS_CSI_DriverRole --force
   ```

3. Install the MongoDB community operator:
   ```shell
   helm repo add mongodb https://mongodb.github.io/helm-charts
   helm install community-operator mongodb/community-operator
   ```
4. Apply a replica set that will use the operator you created above:
   1. Download the example config file `curl -o mongodb.yml https://raw.githubusercontent.com/nrwl/nx-cloud-helm/main/examples/mongodb.yml`
   2. Chose a SAFER password for your internal DB: `sed -i '' 's/DB_PASSWORD/my_password_123/' mongodb.yml`
   3. Apply the config `kubectl apply -f mongodb.yml`
   4. Check if your Mongo pods are getting created. If you have 3 replica sets, you should see 3 MongoDB pods: `kubectl get pods`
      1. if it doesn't work, you can check for issues `kubectl describe pod cloud-mongodb-0`

## 2. Configure secrets

Note: If you'd like to use something like the "AWS Secrets Manager", you can skip this step and check out the guide below.

(TODO upload the new secrets file with the new secrets name on Helm)
1. Download an example secrets file: `curl -o secrets.yml https://raw.githubusercontent.com/nrwl/nx-cloud-helm/main/examples/secret.yml` 
2. Mongo connection string
   1. If you used the Mongo operator above, your connection string will look something like this (replace `DB_PASSWORD` with your configured password): `mongodb+srv://admin-user:DB_PASSWORD@cloud-mongodb-svc.default.svc.cluster.local/nrwl-api?replicaSet=cloud-mongodb&ssl=false`
   2. If you have an external MongoDB, you can now add its connection string. 
3. Configure an Admin password. You will use this to initially log-in to NxCloud. This can be anything you'd like
   1. Apply the secrets file: `kubectl apply -f secrets.yml`

## 3. Install a Load Balancer

1. Download an IAM policy for the AWS Load Balancer Controller: `curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json`
2. Create an IAM policy using the policy that you downloaded from the step above: `aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json`
3. Create a service account for the AWS Load Balancer Controller and attach the policy you created above: `eksctl create iamserviceaccount --cluster=nx-cloud-cluster --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::YOUR_AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve`
4. Install the AWS Load Balancer Controller
   1. Install the TargetGroupBinding custom resource definitions: `kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"`
   2. Add the `eks-charts` Helm charts repository: `helm repo add eks https://aws.github.io/eks-charts`
   3. Install the AWS Load Balancer Controller using the command that corresponds to the AWS Region for your cluster: `helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller --set clusterName=nx-cloud-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller -n kube-system`
   4. Verify that the load balancer is installed: `kubectl get deployment -n kube-system aws-load-balancer-controller`

## 4. Optional: HTTPS support

We recommend setting up HTTPS for your NxCloud cluster, but you can skip this step if you'd just like to see it working for now:

1. [Request a new certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html) for your custom domain
2. Validate it (step 3. in the above guide) **and copy its ARN**

## 5. Install NxCloud:

1. We will use Helm to deploy NxCloud. Create a new NxCloud `helm-values.yml` config:
   (TODO upload this file on the helm repo)
   ```yaml
   cat > helm-values.yml << ENDOFFILE
   image:
      tag: 'latest'
   
   nxCloudAppURL: 'https://your-domain-nx-cloud.com' # <-- if you are using HTTPS and you know your domain name, change this value now. Otherwise, we'll configure it later below.
   
   ingress:
      class: 'alb'
      albScheme: 'internet-facing'
      albListenPorts: '[{"HTTPS":443}]' # this can also be "HTTP":80 if you skipped the certificate part above
      albCertificateArn: 'arn:aws:acm:us-east-1:411686525067:certificate/8adf7812-a1af-4eae-af1b-ea425a238a67' # your certificate ARN here which you copied above. Remove this option if you only want HTTP.
   
   secret:
      name: 'nx-cloud-k8s-secret'
      nxCloudMongoServerEndpoint: 'NX_CLOUD_MONGO_SERVER_ENDPOINT'
      adminPassword: 'ADMIN_PASSWORD'
   ENDOFFILE
   ```
   
   Note: Make sure to read through the comments above to ensure your Ingress is configured correctly for HTTPS/HTTP.

2. Deploy NxCloud to your cluster: `helm upgrade --install nx-cloud nx-cloud/nx-cloud --values=./helm-values.yml`

3. Configure your NxCloud URL
   1. Get the ingress address: `kubectl get ingress`
   2. If using HTTPS: Point your custom domain name's CNAME to the address above (TODO add screenshot here)
   3. If HTTP-only: Just copy the "ADDRESS" field from step 1. above
   4. In your `helm-values.yml` file update the NxCloud URL with either your custom domain or your Load Balancer HTTP address from step 3.: 
      1. `nxCloudAppURL: 'https://your-new-nx-cloud-url.com'`
      2. OR `nxCloudAppURL: 'http://k8s-default-nxcloudi-f36cd47328-1606205137.us-east-1.elb.amazonaws.com'`
   5. Re-apply the changes: `helm upgrade --install nx-cloud nx-cloud/nx-cloud --values=./helm-values.yml`
   6. You might need to restart your deployments as well so they can pick up the new URL `kubectl rollout restart deployment nx-cloud-nx-api nx-cloud-api`

4. In your Nx workspace, enable NxCloud and point it to the above URL: `NX_CLOUD_API=https://your-nx-cloud-url.com nx connect`
5. Run a command, you should start seeing NxCloud Run URLs at the end
   
## 6. External S3 access:

1. [Create an IAM policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create-console.html) that can read/write/delete from your S3 bucket. Make sure to copy its ARN. Here's an example:

   ```shell
   POLICY_ARN=$(aws iam create-policy --policy-name s3-bucket-access-policy --policy-document '{
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "VisualEditor0",
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObjectAcl",
                   "s3:GetObject",
                   "s3:ListBucket",
                   "s3:DeleteObject",
                   "s3:PutObjectAcl"
               ],
               "Resource": [
                   "arn:aws:s3:::<your-bucket-name>",
                   "arn:aws:s3:::<your-bucket-name>/*"
               ]
           }
       ]
   }' | jq -r .Policy.Arn)
   ```

2. Create an `nx-cloud-service-account` service account and an IAM role attached to it, using the Permission Policy you created above (replace the items in angled brackets):

   ```shell
   eksctl create iamserviceaccount \
     --name nx-cloud-service-account \
     --cluster nx-cloud-cluster \
     --attach-policy-arn $POLICY_ARN \
     --override-existing-serviceaccounts \
     --approve \
     --role-name nx-cloud-cluster-s3-access-role
   ```

3. Add these options to the helm.yaml file:

   ```yaml
   awsS3:
      enabled: true
      bucket: '<your-bucket-name>'
      serviceAccountName: 'nx-cloud-service-account'
   ```

4. Push the new config: `helm upgrade --install nx-cloud nx-cloud/nx-cloud --values=./helm-values.yml`

## 7. Set-up external secrets management

1. Make sure you remove any previous k8s secrets named `nx-cloud-k8s-secret`, otherwise it will affect the below
   1. `kubectl delete secret nx-cloud-k8s-secret`
2. [Create a new `AWS Secret Manager` secret](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_secret.html) with key/value pairs called `nx-cloud-secrets`
   1. TODO: add screenshot here
3. Create a policy that can read secrets:

```shell
POLICY_ARN=$(aws iam create-policy --policy-name secrets-reader --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
     {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "<SECRET-ARN>"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
        }
    ]
}
' | jq -r .Policy.Arn)
```

2. Create a service account role and attach the above policy to it:

```shell
eksctl create iamserviceaccount \
    --name read-secrets-service-account \
    --cluster nx-cloud-cluster \
    --role-name read-secrets-role \
    --attach-policy-arn $POLICY_ARN \
    --approve \
    --override-existing-serviceaccounts
```

3. Install the External Secrets Operator
   1. Add the External Secrets Helm repo `helm repo add external-secrets https://charts.external-secrets.io`
   2. Install the External Secrets operators:

   ```shell
   helm install external-secrets \
      external-secrets/external-secrets \
      -n external-secrets \
      --create-namespace \
      --set installCRDs=true \
      --set webhook.port=9443
   ```

4. Create a `secret-store.yaml` file:

   ```yaml
   apiVersion: external-secrets.io/v1beta1
   kind: SecretStore
   metadata:
     name: nx-cloud-secret-store
   spec:
     provider:
       aws:
         service: SecretsManager
         region: us-east-1
         auth:
           jwt:
             serviceAccountRef:
               name: read-secrets-service-account
   ```

5. Then apply it: `kubectl apply -f secret-store.yaml`
6. Create an `external-secret.yaml` file:

   ```yaml
   ---
   apiVersion: external-secrets.io/v1beta1
   kind: ExternalSecret
   metadata:
     name: nx-cloud-external-secret
   spec:
     refreshInterval: 10m
     secretStoreRef:
       kind: SecretStore
       name: nx-cloud-secret-store # the name of the store resource we created above
     target:
       name: nx-cloud-k8s-secret # need to match the secret name in your NxCloud helm-values.yaml
       creationPolicy: Owner
     dataFrom:
       - extract:
           key: nx-cloud-secrets # name of your secret in the AWS Secret Manager
   ```

7. Then apply it `kubectl apply -f external-secret.yaml`

8. Check the status of the secrets:
   1. Check if secret keys are being retrieved correctly: `kubectl get secrets nx-cloud-k8s-secret -o json`
   2. You can see any errors by `kubectl describe externalsecrets.external-secrets.io nx-cloud-external-secret`
9. You might need to restart your deployments as well so they can pick up the new secret values `kubectl rollout restart deployment nx-cloud-nx-api nx-cloud-api`
