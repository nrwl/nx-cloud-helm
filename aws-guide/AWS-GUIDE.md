# EKS Installation

1. Create a new EKS cluster: 

   ```shell
   eksctl create cluster --name nx-cloud-cluster --region us-east-1 --nodegroup-name ng-1  --node-type t3.medium --nodes 5 --managed
   ```

   1. Notes on resources:
      1. the NxCloud services do not require a lot of compute power. Open up [the K8s templates here](https://github.com/nrwl/nx-cloud-helm/blob/main/nx-cloud/templates/cloud.yml) and look for `resource` annotations - this will tell you how many resources each Pod needs. 
      2. the biggest resource you'll need to consider is space required for your cache. Depending on whether you're using an external S3 bucket, or internal Pods to your cluster (both will be configured below), you might need to allocate a few GBs of space later on, the more active your workspace is.
      3. Make sure to [configure autoscaling](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html#cluster-autoscaler) so you only create Nodes that are needed

2. Switch contexts
   1. `kubectl config get-contexts`
   2. `kubectl config use-context <your-new-cluster-context>`

3. Create an IAM OIDC provider associated with your cluster
   3. `eksctl utils associate-iam-oidc-provider --cluster=nx-cloud-cluster --approve`
   1. This will help us authenticate with all kinds of services below from within the cluster using Service Accounts
   2. See [this](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) and this [deep dive](https://mjarosie.github.io/dev/2021/09/15/iam-roles-for-kubernetes-service-accounts-deep-dive.html) for more details

## 1. Using a Mongo operator

NxCloud needs a Mongo database to store details about your runs and record your hashes. You can either point it to your existing external Mongo instance or let it create its own inside the above cluster.
Below, we'll create one inside the cluster. **If you already have an external Mongo instance, you can skip this section.**

1. Create your Amazon EBS CSI plugin IAM role:

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
   1. Download the example config file `curl -o mongodb.yml https://raw.githubusercontent.com/nrwl/nx-cloud-helm/main/aws-guide/mongodb.yml`
   2. Chose a SAFER password for your internal DB: `sed -i '' 's/DB_PASSWORD/my_password_123/' mongodb.yml`
   3. Apply the config `kubectl apply -f mongodb.yml`
   4. Check if your Mongo pods are getting created. If you have 3 replica sets, you should see 3 MongoDB pods: `kubectl get pods`
      1. if it doesn't work, you can check for issues `kubectl describe pod cloud-mongodb-0`

## 2. Configure secrets

Note: If you'd like to use something like the "AWS Secrets Manager", you can skip this step and check out the guide below.

1. Download an example secrets file: `curl -o secrets.yml https://raw.githubusercontent.com/nrwl/nx-cloud-helm/main/aws-guide/secret.yml` 
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

1. We will use Helm to deploy NxCloud.
   1. Download the example AWS Helm config file: `curl -o helm-values.yml https://raw.githubusercontent.com/nrwl/nx-cloud-helm/main/aws-guide/helm-values.yml`
   2. Open and make sure to read all end of line comments
   3. Read our [generic guide here](https://github.com/nrwl/nx-cloud-helm/) for all the different ways you can configure NxCloud

4. Deploy NxCloud to your cluster: `helm upgrade --install nx-cloud nx-cloud/nx-cloud --values=./helm-values.yml`

5. Configure your NxCloud URL
   1. Get the ingress address: `kubectl get ingress`
   2. If using HTTPS: Point your custom domain name's CNAME to the address above
      1. ![cname-dns-config-example](/aws-guide/CNAME-DNS-config.png) 
   3. If HTTP-only: Just copy the "ADDRESS" field from step 1. above
   4. In your `helm-values.yml` file update the NxCloud URL with either your custom domain or your Load Balancer HTTP address from step 3.: 
      1. for HTTPS: `nxCloudAppURL: 'https://your-new-nx-cloud-url.com'`
      2. or for HTTP: `nxCloudAppURL: 'http://k8s-default-nxcloudi-f36cd47328-1606205137.us-east-1.elb.amazonaws.com'`
   5. Re-apply the changes: `helm upgrade --install nx-cloud nx-cloud/nx-cloud --values=./helm-values.yml`
   6. You might need to restart your deployments as well so they can pick up the new URL `kubectl rollout restart deployment nx-cloud-nx-api nx-cloud-api`

6. In your Nx workspace, enable NxCloud and point it to the above URL: `NX_CLOUD_API=https://your-nx-cloud-url.com nx connect`
7. Run a command, you should start seeing NxCloud Run URLs at the end
   
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
   
3. Increase the session duration of the role to 5 hours:

   ```shell
   aws iam update-role --role-name nx-cloud-cluster-s3-access-role --max-session-duration=18000
   ```
   
   We need to do this because the URLs for writing artefacts to your S3 cache are generated at the beginning of your CI run. And depending on how long your CI run takes, the URLs might expire if we don't give them a long enough time window.

3. Add these options to the helm.yaml file:

   ```yaml
   awsS3:
      enabled: true
      bucket: '<your-bucket-name>'
      serviceAccountName: 'nx-cloud-service-account'
      # accelerated: true  uncomment when using accelerated bucket
      # endpoint: ''  uncomment when using a custom endpoint
   ```

4. Push the new config: `helm upgrade --install nx-cloud nx-cloud/nx-cloud --values=./helm-values.yml`

## 7. Set-up external secrets management

1. Make sure you remove any previous k8s secrets named `nx-cloud-k8s-secret`, otherwise it will affect the below
   1. `kubectl delete secret nx-cloud-k8s-secret`
2. [Create a new `AWS Secret Manager` secret](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_secret.html) with key/value pairs called `nx-cloud-secrets`
   1. ![aws-secret-manager-example](/aws-guide/aws-secret-manager-example.png)
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
   2. We'll be using the [External Secrets operators](https://external-secrets.io/) to sync our Kubernetes secrets with the "AWS Secrets Manager"
   1. Add the External Secrets Helm repo `helm repo add external-secrets https://charts.external-secrets.io`
   3. Install the External Secrets operators:

   ```shell
   helm install external-secrets \
      external-secrets/external-secrets \
      -n external-secrets \
      --create-namespace \
      --set installCRDs=true \
      --set webhook.port=9443
   ```

4. Download the example Secret Store config `curl -o secret-store.yml https://raw.githubusercontent.com/nrwl/nx-cloud-helm/main/aws-guide/secret-store.yml`
   1. Have a look through it to ensure it applies to your cluster
5. Then apply it: `kubectl apply -f secret-store.yml`
6. Download the example External Secret config ``curl -o secret-store.yml https://raw.githubusercontent.com/nrwl/nx-cloud-helm/main/aws-guide/external-secret.yml``
   1. Read through and the its comments to ensure it applies to your configuration.
8. Then apply it `kubectl apply -f external-secret.yml`
9. Check the status of the secrets:
   1. Check if secret keys are being retrieved correctly: `kubectl get secrets nx-cloud-k8s-secret -o json`
   2. You can see any errors by `kubectl describe externalsecrets.external-secrets.io nx-cloud-external-secret`
10. You might need to restart your deployments as well so they can pick up the new secret values `kubectl rollout restart deployment nx-cloud-nx-api nx-cloud-api`


## Common Issues

1. When setting up Ingress "unable to discover at least one subnet"

   - You'll need to configure your VPC subnets for auto-discovery. [See Guide here](https://www.youtube.com/watch?v=3WbEt_sfTWU).
   - If that doesn't work, try changing the [`alb.ingress.kubernetes.io/target-type`](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/ingress/annotations/#traffic-routing) to `ip` 
