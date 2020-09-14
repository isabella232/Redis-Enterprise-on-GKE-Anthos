# Convert from OpenSource Redis to Redis Enterprise

For this section we'll convert from using OpenSource Redis to Redis Enterprise.

This will involve the following steps:
1. Deploy the Redis Enterprise Operator
2. Create a Redis Enterprise cluster
3. Deploy a Redis Enterprise Database (`redis-enterprise-database`) including setting the password to the null string
4. Modify the `cartservice.yaml` to point to the new database service and port
5. Update the services (particularly the cartservice)
6. Delete the now unused `redis-cart` service

## Steps

1. Deploy the Redis Enterprise Operator

```
kubectl apply -f https://raw.githubusercontent.com/RedisLabs/redis-enterprise-k8s-docs/master/bundle.yaml
```

You can see that this has created a new deployment `redis-enterprise-operator` and a pod `redis-enterprise-operator-6498bcf4c7-mps6p` (yours will be named differently)

2. Create a Redis Enterprise cluster

```
kubectl apply -f https://raw.githubusercontent.com/RedisLabs/redis-enterprise-k8s-docs/master/crds/app_v1_redisenterprisecluster_cr.yaml
```

This uses the operator to create a rigger deployment (`redis-enterprise-services-rigger`) and pod (`redis-enterprise-services-rigger-7b8cdb6ff-qn69w`), along with two new services:
* `redis-enterprise` - the redis enterprise cluster
* `redis-enterprise-ui` - the redis enterprise management interface

The `redis-enterprise` service has 3 pods associated with it (the nodes in the Redis Enterprise cluster): `redis-enterprise-{1,2,3}`


3. Deploy the Redis Enterprise Database
Deploying a database requires a secret and a database specification, as per  [RedisEnterpriseDatabaseSpec](https://github.com/RedisLabs/redis-enterprise-k8s-docs/blob/master/redis_enterprise_database_api.md#redisenterprisedatabasespec)

This is done using [Kubernetes Kustomization](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/) by applying the files in the `Kustomization` directory.

The `Kustomization` directory contains two files:
* `Kustomization.yaml` -which references the other two:
* `rdb-secret.yaml` - which creates the default password for the cluster (it actually deletes the password by setting it to the null string)
* `redis-enterprise-database.yaml` - which configures the redis enterprise database

```
kubectl apply -k Kustomization

```
This will create two new services:
* redis-enterprise-database - the database itself
* redis-enterprise-database-headless - I don't know what this is :-(

You can get the port that the Redis Enterprise database is listening on with the following command:

```
kubectl get service/redis-enterprise-database -o jsonpath='{.spec.ports[?(@.name=="redis")].port}'
```

4. Modify the `cartservice.yaml`
You need to disconnect the cart service from the OpenSource Redis database and start using the new one (no data migrations are configured - so anything in the old cart will be lost)

Edit `knative/*/services.yaml` and replace this line:
```
            value: "redis-cart:6379"
```
            value: "redis-enterprise-database:DBPORT"
```
where DBPORT is the value you found for the port number for the redis-enterprise-database previously. 

This sed script will do it for you:
```
for dir in v{1..3}
do
        sed -i .bak s/redis-cart:6379/redis-enterprise-database:$(kubectl get service/redis-enterprise-database -o jsonpath='{.spec.ports[?(@.name=="redis")].port}')/ knative/$dir/services.yaml
done
```

5. Update the knative services

```
kubectl apply -f knative/v1
```

6. Delete the `redis-cart` service
Deleting the service is achieved by deleting the deployment:
```
kubectl delete deployment/redis-cart
```
If you list the pods you'll see that the redis-cart pod is terminating. However your web site will continue to function!

### Note to Kubernetes/Knative experts

If you know of a better way of achieving steps 4 thru' 6 above then do
let me know. I was expecting some way of linking the port number so it
could be discovered dynamically at run time, rather than hard-coding
the port number into the file using a script!

## Redis Enterprise

### Redis Enterprise Cluster Manager UI

The Redis Enterprise Cluster Manager UI is available via port forwarding. Its not intended that you manage the Redis Enterprise Cluster on Kubernetes using it (you should instead use `kubectl` and the [Redis Enterprise Cluster API](https://github.com/RedisLabs/redis-enterprise-k8s-docs/blob/master/redis_enterprise_cluster_api.md)), but many people are used to viewing this UI so its useful to view it.

To setup for this UI you'll need to:
1. In one terminal setup up port forwarding port 8443 from your laptop to a Redis Enterprise pod
```
kubectl port-forward redis-enterprise-0 8443
```
2. In another terminal get the login credentials:
```
kubectl get secrets redis-enterprise -o json | jq -r '[.data.username, .data.password] | map(@base64d) | .[]'
```
3. In a browser, go to http://localhost:8443, where you'll  be forward to the Redis Enterprise Cluster Manager UI

### Redis-cli access
If you want to interact with your database using the redis cli you must attach to one of the kubernetes containers in the cluster. The simplest way to do that is like this:
1. Get the database port inside the cluster
```
kubectl get service/redis-enterprise-database -o jsonpath='{.spec.ports[?(@.name=="redis")].port}'
```
2. Create a shell on a redis-enterprise container:
```
kubectl exec -it redis-enterprise-0 -c redis-enterprise-node -- /bin/bash
```
	3. Use the redis-cli to connect to your database, using the database service name (`redis-enterprise-database`) database port. 
```
redis-cli -h redis-enterprise-database -p PORT
```

---
[[toc]](README.md) [[back]](03-knative-configuration.md) [[next]](05-autoscaling.md)
