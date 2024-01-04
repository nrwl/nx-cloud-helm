# Deploy Workflows

Create a storage class:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: premium-rwo
parameters:
  type: gp2
  fsType: ext4
provisioner: kubernetes.io/aws-ebs #change this according to your cloud provider
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```