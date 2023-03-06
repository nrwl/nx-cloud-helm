# Self-hosted Mongo Operator guide

We recommend using an external Mongo service, such as [Atlas](https://mongodb.com/atlas/). If you'd like to run Mongo in the same cluster 
as your other NxCloud services, then please continue following this guide.

### Step 1: Deploy MongoDB Kubernetes Operator

```
> helm repo add mongodb https://mongodb.github.io/helm-charts
> helm install community-operator mongodb/community-operator
```

### Step 2: OPTIONAL - configure encryption

If you'd like to encrypt you Mongo volumes, apply the encrypted storage 
class `kubectl apply -f encrypted-storage-class.yml`

### Step 3: Deploy a MongoDB replica set

```
# NO ENCRYPTION (if you skipped the above step)
> kubectl apply -f examples/mongodb.yml

# WITH ENCRYPTION (if you followed step 2 above)
> kubectl apply -f examples/encrypted-mongodb.yml
```

This will create a secret. You can get the value of the secret as follows:

```
> kubectl get secret cloud-mongodb-nrwl-api-admin-user -o go-template='{{range $k,$v := .data}}{{"### "}}{{$k}}{{"n"}}{{$v|base64decode}}{{"nn"}}{{end}}'
```

You might need to wait a bit for the Pods to be created before this secret will be available.

The result should look like
this: `mongodb+srv://admin-user:DB_PASSWORD@cloud-mongodb-svc.default.svc.cluster.local/nrwl-api?replicaSet=cloud-mongodb&ssl=false`
.

Extract the connection string and remember it. You'll need to use in your `secrets.yml` file.

Next steps: continue from [step 2. onwards](./README.md#step-2-create-a-secret).
