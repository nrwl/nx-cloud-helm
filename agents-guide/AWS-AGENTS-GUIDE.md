# Deploy an Nx Agents cluster on AWS

## Create the cluster

```bash
# init the cluster
eksctl create cluster --name nx-cloud-cluster --region us-east-1 \
  --nodegroup-name ng-1 --node-type t3.medium --nodes 5 --managed
  
 # associate the oidc provider
 eksctl utils associate-iam-oidc-provider \ 
  --cluster=nx-cloud-cluster --approve
```

## Installing the EBS CSI add-on

```bash
# create a service account for the controller to use
eksctl create iamserviceaccount \
--name ebs-csi-controller-sa \
--namespace kube-system \
--cluster ami-test-agents-cluster \
--attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
--approve \
--override-existing-serviceaccounts

# install the add-on via helm
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
--namespace kube-system \
--set controller.serviceAccount.create=false \
--set controller.serviceAccount.name=ebs-csi-controller-sa
```

## Install valkey

1. Add a valkey password in [agents-secrets.yml](./agents-secrets.yml)
2. Deploy valkey:

```bash
kubectl apply -f agents-secrets.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install valkey bitnami/valkey --set auth.usePassword=true --set auth.existingSecret=nx-cloud-agents-secret
```

## Connecting an S3 bucket

1. Create an S3 for the agents to store their cache and their logs
2. Create a policy that allows access to the bucket:
```json
{
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
                "arn:aws:s3:::your-bucket-name",
                "arn:aws:s3:::your-bucket-name/*"
            ]
        }
    ]
}
```
3. Attach the above policy to the NodeGroup IAM Role for your EKS Cluster

## Deploy Nx Agents

```bash
helm upgrade --install nx-agents nx-cloud/nx-agents \
--values=./nx-agents.yml \
--set controller.image.tag="2405.02.15"
```

## Copy the public URL 

```bash
# copy the EXTERNAL-IP value
kubectl get service nx-cloud-workflow-controller-service
```

## Connect your NxCloud cluster to your Nx Agents cluster

Continue following the instructions here for instructions on how to connect your NxCloud cluster to the above address.

## Other resources

Please also check the generic [Agents Guide](./AGENTS-GUIDE.md) for background on how why we need some of the pieces above, such as valkey.