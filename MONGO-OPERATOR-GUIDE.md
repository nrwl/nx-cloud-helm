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

## Alternative - run the Mongo NxCloud Image

If you can't run Mongo in Kubernetes, you can also set it up manually using our approved Docker image.

1. Deploy this Docker image on ECS, or a custom VM: `nxprivatecloud/nx-cloud-mongo:latest`
2. Here is an example of how to run it, and what options you should pass to it. Please adapt the command to the deployment env of your choice (We will provide an example ECS set-up below):
    ```shell
    docker run -t -i -p 27017:27017 \
      -e MONGO_INITDB_ROOT_USERNAME=some-admin-usernamne -e MONGO_INITDB_ROOT_PASSWORD=someAdminPassword123 \
      -v $PWD/mongo-data:/data/db \
      --rm --name nx-cloud-mongo nxprivatecloud/nx-cloud-mongo:latest \
      --wiredTigerCacheSizeGB 2 --bind_ip_all \
      --replSet rs0 \
      --keyFile /mongo-security/keyfile.txt
    ```
   
   - There are a few important options we need to pass:
     - `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD` - this will enable auth on our DB
     - `-v $PWD/mongo-data:/data/db` - this will create a persistent volume mapping to the host, so the DB doesn't disappear when the Docker image gets recreated.
     - `--wiredTigerCacheSizeGB 2` - This sets the memory limit of the DB. Try increasing it if you are having a lot of activity.
     - `--replSet rs0 --keyFile /mongo-security/keyfile.txt` - this sets up a simple replica set. You can ignore this, it's an implementation detail needed for NxCloud connections.

#### Connecting to the instance

This is a sample connection string you can use when connecting to your instance above (note the extra URL params at the end): `mongodb://<your-server-ip-or-address>:27017/?authSource=admin&directConnection=true`

<details>
<summary>⤵️ Here is an example ECS implementation</summary>

```json
{
  "family": "nx-cloud-mongo-standalone",
  "containerDefinitions": [
    {
      "name": "NxCloudMongo",
      "image": "nxprivatecloud/nx-cloud-mongo:latest",
      "cpu": 1024,
      "memory": 3072,
      "portMappings": [
        {
          "name": "nxcloudmongo-27017-tcp",
          "containerPort": 27017,
          "hostPort": 27017,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "command": [
        "--wiredTigerCacheSizeGB",
        "3",
        "--bind_ip_all",
        "--replSet",
        "rs0",
        "--keyFile",
        "/mongo-security/keyfile.txt"
      ],
      "environment": [
        {
          "name": "MONGO_INITDB_ROOT_USERNAME",
          "value": "some-admin-user"
        },
        {
          "name": "MONGO_INITDB_ROOT_PASSWORD",
          "value": "adminPass123"
        }
      ],
      "mountPoints": [
        {
          "sourceVolume": "data",
          "containerPath": "/data/db",
          "readOnly": false
        }
      ],
      "volumesFrom": [],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/DeployCloud",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "executionRoleArn": "arn:aws:iam::623002322076:role/ecsTaskExecutionRole",
  "volumes": [
    {
      "name": "data",
      "dockerVolumeConfiguration": {
        "scope": "shared",
        "autoprovision": true,
        "driver": "local"
      }
    }
  ],
  "requiresCompatibilities": [
    "EC2"
  ],
  "cpu": "1024",
  "memory": "3072"
}
```
</details>

### Upgrading to Mongo 6

As of version `latest-11-05-2023T11-28-04` (and all new calver based versions that are similar to `2305.11.3`) and higher, we strongly recommend you update from Mongo 4.2 to Mongo 6 for
your NxCloud installation.

Mongo upgrades need to be done incrementally between major versions. In both scenarios below, we'll upgrade from Mongo 4.2
to 4.4 then to 5.0 then to 6.0.

##### Mongo Atlas

If you're using Mongo Atlas, you can do a rolling upgrade by editing your cluster's configuration:

<img src="examples/images/atlas-edit-cluster-config.png">

and first selecting Mongo 4.4, then Mongo 5.0, finally Mongo 6.0 (notice how it doesn't let us upgrade from 4.4 straight to 6):

<img src="examples/images/atlas-upgrade-mongo-version.png">

##### Mongo Operator

If you're using the Mongo Operator, you'll need to edit your Mongo ReplicaSet and apply the version changes incrementally, as Mongo doesn't allow a direct 4.2 to 6.0 upgrade.
During the upgrade, we'll need to continually update our [feature compatibility version](https://www.mongodb.com/docs/manual/reference/command/setFeatureCompatibilityVersion/) also.
Mongo requires that this `featureCompatibilityVersion` always trails the version we want to upgrade to. For example, if our pods are on Mongo 4.4 and we want to upgrade them to Mongo 5, our featureCompatibilityVersion needs to be first set to 4.4.

It's important you follow the exact steps in order:

1. [Backup your database first](https://docs.bitnami.com/tutorials/backup-restore-data-mongodb-kubernetes/) using a tool like `mongodump`. You can ssh into any one of your pods, as they should have the same data. 
1. Edit your `/mongo.yml` file
2. Change to Mongo version 4.4: `version: '4.4.20'`
   - Then, we'll also set this option right below it: `featureCompatibilityVersion: '4.2'`
   - Your `mongo.yml` file should now contain these 2 lines:
     ```yaml
     version: '4.4.20'
     featureCompatibilityVersion: '4.2'
      ```
2. Apply your changes `kubectl apply -f mongo.yml`
3. Your replica pods will slowly start upgrading now
   1. use `kubectl get pods` to monitor this 
   2. This process will take around 10-20 minutes to complete.
   3. It's very important to let all the pods completely upgrade before moving on to the next step.
6. Once all pods have upgraded and are in a healthy state, they should look similar to the below:
   7. <img src="examples/images/mongo-pods-healthy.png">
   8. The age of the pods needs to be a very low number. This means they have recently been re-created with the new Mongo version.
3. Now set `featureCompatibilityVersion: '4.4'`
   - `kubectl apply -f mongo.yml` 
   - This will set the [feature compatibility version](https://www.mongodb.com/docs/manual/reference/command/setFeatureCompatibilityVersion/) of the Mongo pods to a version that we need for the next step of the upgrade.
4. Now set `version: '5.0.17'`
   5. Apply the change
   6. Leave it to upgrade for the next 20-30 minutes. 
   7. Your `kubectl get pods` output should show healthy pods, with `2/2` availability and the `AGE` of the pods should now also be reset (similar to the screenshot we saw above)
3. Set `featureCompatibilityVersion: '5.0'` 
   4. Apply the changes. You don't need to wait/watch for pod upgrades as this change will be applied very quickly.
3. Change to `version: '6.0.5'` and apply it.
   4. Wait for 20 minutes
   5. Then check your pods are in a healthy state `kubectl get pods`
3. Finally, set `featureCompatibilityVersion: '6.0'` and apply the change. This change will be very quick.
4. All your pods should now be on Mongo 6. Congratulations!

##### How to check pod Mongo version and featureCompatibilityVersion:

If you are unsure if your pods have finished upgrading between Mongo versions (as this a long, based on the steps above) and you'd like to check what Mongo version your pods are on, you can exec into a pod and:

```shell
mongo --version # you can do this for each pod part of your replica set
```

To check the `featureCompatibilityVersion`, exec into the pod and:

```shell
mongo -u admin-user -p <password> --authenticationDatabase nrwl-api
use nrwl-api
db.adminCommand({getParameter: 1, featureCompatibilityVersion: 1})
```

Although not necessary, you can use the above commands to check each of your 3 replicas is on the correct Mongo version and `featureCompatibilityVersion` between the upgrade steps above.