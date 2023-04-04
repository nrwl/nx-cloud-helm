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

This is a sample connection string you can use when connecting to your instance above. Not the extra params: `mongodb://52.201.253.213:27017/?authSource=admin&directConnection=true`

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
