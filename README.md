# Nx Cloud Helm Chart

A lot of organizations deploy Nx Cloud to Kubernetes.

This repo contains:

* Nx Cloud Helm Chart
* Nx Agents Helm Chart

> Important: Breaking changes in nx-cloud chart version 1.0.0
>
> Starting with chart version 1.0.0, there are breaking changes to values and templates. Please review the migration guide before upgrading and plan for required adjustments.
>
> See charts/nx-cloud/MIGRATION.md for details: [MIGRATION.md](charts/nx-cloud/MIGRATION.md)


### Compatibility Matrix

| Chart Version | Compatible Images                  |
|---------------|------------------------------------|
| <= `0.10.11`  | `2306.01.2.patch4` **and earlier** |
| >= `0.11.0`   | `2308.22.7` **and later**          |
| >= `0.12.0`   | `2312.11.7` **and later**          |
| >= `1.0.0`    | `2025.07.1` **and later**          |

## Cloud Containers

The installation will create the following:

1. nx-cloud-frontend (deployment)
2. nx-cloud-nx-api (deployment)
3. nx-cloud-file-server (deployment)
4. nx-cloud-aggregator (cron job)

## Suggested resources

Suggested resources for the NxCloud cluster are (you can always start with less and scale up to this as needed):
- 9 vCPUS
- 23GB memory
- Or you can use the equivalent of 5 `t3.medium` AWS Nodes (or 7 if running Mongo)

Disk size:
- The biggest resource consideration will be the permanent Volume where your cached artefacts will be stored. This depends on the size/activity of the workspace. You can start with 20-50GB and scale up if needed.
- For Mongo, 5-10GB should be enough

## More Information

You can find more information about Nx Cloud and running it on
prem [here](https://nx.dev/nx-cloud/private-cloud/get-started).
