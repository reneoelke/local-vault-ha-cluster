# Description

This is a multi-container Docker application environment which consists of the following container services:

- 1 x [Nginx web server](https://nginx.org/en/)
- 1 x [HAProxy load balancer](http://www.haproxy.org/)
- 3 x [Vault server](https://www.vaultproject.io/)
- 1 x [DynamoDB local server](http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html)

Every container service has its own subdirectory for configuring and building purposes.

# Quick-Setup

## Requirements

Before running this application environment the following required tools should be installed:

- [Docker](https://docs.docker.com/engine/installation/) >= 1.12.0

Optional the following tools could be installed:

- [Vault client](https://www.vaultproject.io/downloads.html) >= 0.6.1
- [curl](https://curl.haxx.se/download.html) >= 7.43.0

## Run the application environment

Run the application environment with the following command:

```
docker-compose up --build -d
docker-compose logs --no-color --follow --timestamps
```

# Hostnames and ports

Configure the following host names (i.e. in `/etc/hosts`):

```
127.0.0.1 vault
127.0.0.1 vault-lb
127.0.0.1 vault-node-01 vault-node-02 vault-node-03
127.0.0.1 dynamodb
127.0.0.1 rsyslog
```

The following port mapping for the different hosts and protocols will be used:

| Hostname      | Port  | Protocol |
| ------------- | ----- | -------- |
| vault         | 8200  | http     |
| vault-lb      | 8820  | http     |
| vault-node-01 | 18200 | http     |
| vault-node-02 | 28200 | http     |
| vault-node-03 | 38200 | http     |

# Initialization

If the application environment was started for the first time, the Vault cluster has to be initialized and all running nodes have to be unsealed. Only THEN the whole cluster is running. The first unsealed node becomes the active node, all others will be standby nodes.

Run the following commands:

- Check the current status of the cluster (over the Nginx proxy)
```
curl -s http://vault:8200/v1/sys/status | json_pp
{
  "initialized": false
}
```

- Check the current status of the cluster (over the HAProxy load balancer)
```
curl -s http://vault-lb:8820/v1/sys/status | json_pp
{
  "initialized": false
}
```

- Initialize the Vault cluster (details see https://www.vaultproject.io/docs/http/sys-init.html)
```
curl -s -X PUT -d '{"secret_shares":4, "secret_threshold":2}' http://vault:8200/v1/sys/init | json_pp
{
  "keys": [
    ...
  ],
  "keys_base64": [
    ...
  ],
  "root_token": ...
}
```

- Unseal every Vault nodes (details see https://www.vaultproject.io/docs/http/sys-unseal.html)

```
curl -s -X PUT -d '{"key":${KEY_01}}' http://vault-node-01:18200/v1/sys/unseal | json_pp
{
  "version" : "Vault v0.6.1",
  "n" : 5,
  "sealed" : true,
  "t" : 3,
  "progress" : 1
}
curl -s -X PUT -d '{"key":${KEY_02}}' http://vault-node-01:18200/v1/sys/unseal | json_pp
{
  "version" : "Vault v0.6.1",
  "n" : 5,
  "t" : 3,
  "progress" : 2,
  "sealed" : true
}
curl -s -X PUT -d '{"key":${KEY_03}}' http://vault-node-01:18200/v1/sys/unseal | json_pp
{
  "version" : "Vault v0.6.1",
  "n" : 5,
  "t" : 3,
  "progress" : 0,
  "sealed" : false,
  "cluster_id" : "ce155b3b-e97a-8151-2492-094f7cc4f23e",
  "cluster_name" : "vault-cluster-f84291f2"
}

curl -s -X PUT -d '{"key":${KEY_01}}' http://vault-node-02:28200/v1/sys/unseal | json_pp
{
...
}
curl -s -X PUT -d '{"key":${KEY_02}}' http://vault-node-02:28200/v1/sys/unseal | json_pp
{
...
}
curl -s -X PUT -d '{"key":${KEY_03}}' http://vault-node-02:28200/v1/sys/unseal | json_pp
{
...
}

curl -s -X PUT -d '{"key":${KEY_01}}' http://vault-node-03:38200/v1/sys/unseal | json_pp
{
...
}
curl -s -X PUT -d '{"key":${KEY_02}}' http://vault-node-03:38200/v1/sys/unseal | json_pp
{
...
}
curl -s -X PUT -d '{"key":${KEY_03}}' http://vault-node-03:38200/v1/sys/unseal | json_pp
{
...
}
```

- Check the current status for every Vault node
```
curl -s http://vault-node-01:18200/v1/sys/seal-status | json_pp
{
  ...
  "sealed" : false,
  ...
}
curl -s http://vault-node-02:28200/v1/sys/seal-status | json_pp
{
  ...
  "sealed" : false,
  ...
}
curl -s http://vault-node-02:28200/v1/sys/seal-status | json_pp
{
  ...
  "sealed" : false,
  ...
}
```

# Authorization

"Before performing any operation with Vault, the connecting client must be authenticated" (https://www.vaultproject.io/docs/concepts/auth.html).

"Root tokens are tokens that have the root policy attached to them. Root tokens can do anything in Vault. Anything. In addition, they are the only type of token within Vault that can be set to never expire without any renewal needed." (https://www.vaultproject.io/docs/concepts/tokens.html)

*TODO* Currently only a root token was created with the initialization (see above). The root token should not be used in production mode. Therefore more user tokens with corresponding policies should be created and used in production environment.

To get more details about the current used token run the folloing command (see https://www.vaultproject.io/docs/auth/token.html):

```
curl -s -L -H "X-Vault-Token:${TOKEN}" http://vault:8200/v1/auth/token/lookup-self
{
  "lease_id" : "",
  "data" : {
    "path" : "auth/token/root",
    "creation_ttl" : 0,
    "ttl" : 0,
    "creation_time" : 1473350339,
    "policies" : [
       "root"
    ],
    "orphan" : true,
    "display_name" : "root",
    "accessor" : "4dd3e9b1-fe02-97ad-d186-73b78991b6d4",
    "id" : "8263fdcf-1f2f-fdb9-791e-35143e2b48ee",
    "num_uses" : 0,
    "explicit_max_ttl" : 0,
    "meta" : null
  },
  "renewable" : false,
  "request_id" : "c361fe65-6b35-ef2b-e3bf-27d6efd863d4",
  "auth" : null,
  "lease_duration" : 0,
  "wrap_info" : null,
  "warnings" : null
}
```

# Testing the high availability

The Vault cluster is completed if all available Vault nodes are running in unsealed mode (see above). The HAProxy picks the first available unsealed node and if the health check passes through it will be the active node. To find out which node is the current active node run the following command:

```
curl -s -L -H "X-Vault-Token:{TOKEN}" http://vault-node-01:18200/v1/sys/leader | json_pp
{
  ...
  "is_self" : true,
  ...
}
curl -s -L -H "X-Vault-Token:{TOKEN}" http://vault-node-02:28200/v1/sys/leader | json_pp
{
  ...
  "is_self" : false,
  ...
}
curl -s -L -H "X-Vault-Token:{TOKEN}" http://vault-node-03:38200/v1/sys/leader | json_pp
{
  ...
  "is_self" : false,
  ...
}
```

In high availability (HA) setup the active node should change to the next available standby node and the load balancer should detect it and should change the active node. To test if a standby node will get the leader and if HAProxy picks it as the active node the following things are possible:

- Degrade the current leader to standby
```
curl -s -L -X PUT -H "X-Vault-Token:{TOKEN}" http://vault-node-01:18200/v1/sys/step-down

docker-compose logs -f
...
vault-node-01_1  | 2016/09/15 14:51:43.124894 [WRN] core: stepping down from active operation to standby
vault-node-01_1  | 2016/09/15 14:51:43.219142 [INF] core: pre-seal teardown starting
vault-node-01_1  | 2016/09/15 14:51:43.219174 [INF] rollback: stopping rollback manager
vault-node-01_1  | 2016/09/15 14:51:43.219264 [INF] core: pre-seal teardown complete
vault-node-02_1  | 2016/09/15 14:51:43.895482 [INF] core: acquired lock, enabling active operation
vault-node-02_1  | 2016/09/15 14:51:44.008062 [INF] core: post-unseal setup starting
vault-node-02_1  | 2016/09/15 14:51:44.066326 [INF] core: successfully mounted backend type=generic path=secret/
vault-node-02_1  | 2016/09/15 14:51:44.067847 [INF] core: successfully mounted backend type=cubbyhole path=cubbyhole/
vault-node-02_1  | 2016/09/15 14:51:44.069137 [INF] core: successfully mounted backend type=system path=sys/
vault-node-02_1  | 2016/09/15 14:51:44.069915 [INF] rollback: starting rollback manager
vault-node-02_1  | 2016/09/15 14:51:44.141560 [INF] core/startClusterListener: clustering disabled, not starting listeners
vault-node-02_1  | 2016/09/15 14:51:44.144609 [INF] core: post-unseal setup complete
rsyslog_1        | 2016-09-15T14:51:47+00:00 vaultcluster_vault-lb_1.vaultcluster_default haproxy[8]: Server vault_pool/vault-node-02 is UP, reason: Layer7 check passed, code: 200, info: "OK", check duration: 0ms. 2 active and 0 backup servers online. 0 sessions requeued, 0 total in queue.
rsyslog_1        | 2016-09-15T14:51:48+00:00 vaultcluster_vault-lb_1.vaultcluster_default haproxy[8]: Server vault_pool/vault-node-01 is DOWN, reason: Layer7 wrong status, code: 429, info: "Too Many Requests", check duration: 0ms. 1 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
...
```

- Seal the current leader
```
curl -s -L -X PUT -H "X-Vault-Token:{TOKEN}" http://vault-node-02:28200/v1/sys/seal

docker-compose logs -f
...
vault-node-02_1  | 2016/09/15 15:07:47.002971 [WRN] core: stopping active operation
vault-node-02_1  | 2016/09/15 15:07:47.070340 [INF] core: pre-seal teardown starting
vault-node-02_1  | 2016/09/15 15:07:47.070603 [INF] rollback: stopping rollback manager
vault-node-02_1  | 2016/09/15 15:07:47.070915 [INF] core: pre-seal teardown complete
vault-node-02_1  | 2016/09/15 15:07:47.108525 [INF] core: vault is sealed
vault-node-01_1  | 2016/09/15 15:07:47.281812 [INF] core: acquired lock, enabling active operation
vault-node-01_1  | 2016/09/15 15:07:47.363378 [INF] core: post-unseal setup starting
vault-node-01_1  | 2016/09/15 15:07:47.405166 [INF] core: successfully mounted backend type=generic path=secret/
vault-node-01_1  | 2016/09/15 15:07:47.405201 [INF] core: successfully mounted backend type=cubbyhole path=cubbyhole/
vault-node-01_1  | 2016/09/15 15:07:47.405425 [INF] core: successfully mounted backend type=system path=sys/
vault-node-01_1  | 2016/09/15 15:07:47.406315 [INF] rollback: starting rollback manager
vault-node-01_1  | 2016/09/15 15:07:47.453575 [INF] core/startClusterListener: clustering disabled, not starting listeners
vault-node-01_1  | 2016/09/15 15:07:47.453604 [INF] core: post-unseal setup complete
rsyslog_1        | 2016-09-15T15:07:50+00:00 vaultcluster_vault-lb_1.vaultcluster_default haproxy[8]: Server vault_pool/vault-node-01 is UP, reason: Layer7 check passed, code: 200, info: "OK", check duration: 0ms. 2 active and 0 backup servers online. 0 sessions requeued, 0 total in queue.
rsyslog_1        | 2016-09-15T15:07:52+00:00 vaultcluster_vault-lb_1.vaultcluster_default haproxy[8]: Server vault_pool/vault-node-02 is DOWN, reason: Layer7 wrong status, code: 503, info: "Service Unavailable", check duration: 0ms. 1 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
...
```

- Stop the container with the current leader
```
docker-compose stop vault-node-01

docker-compose logs -f
...
vault-node-01_1  | ==> Vault shutdown triggered
vault-node-01_1  | 2016/09/15 15:10:19.047566 [WRN] core: stopping active operation
vault-node-01_1  | 2016/09/15 15:10:19.119939 [INF] core: pre-seal teardown starting
vault-node-01_1  | 2016/09/15 15:10:19.119969 [INF] rollback: stopping rollback manager
vault-node-01_1  | 2016/09/15 15:10:19.119987 [INF] core: pre-seal teardown complete
vault-node-01_1  | 2016/09/15 15:10:19.151266 [INF] core: vault is sealed
vaultcluster_vault-node-01_1 exited with code 0
vault-node-02_1  | 2016/09/15 15:10:20.040676 [INF] core: acquired lock, enabling active operation
vault-node-02_1  | 2016/09/15 15:10:20.120659 [INF] core: post-unseal setup starting
vault-node-02_1  | 2016/09/15 15:10:20.160029 [INF] core: successfully mounted backend type=generic path=secret/
vault-node-02_1  | 2016/09/15 15:10:20.160284 [INF] core: successfully mounted backend type=cubbyhole path=cubbyhole/
vault-node-02_1  | 2016/09/15 15:10:20.160687 [INF] core: successfully mounted backend type=system path=sys/
vault-node-02_1  | 2016/09/15 15:10:20.161816 [INF] rollback: starting rollback manager
vault-node-02_1  | 2016/09/15 15:10:20.216546 [INF] core/startClusterListener: clustering disabled, not starting listeners
vault-node-02_1  | 2016/09/15 15:10:20.216653 [INF] core: post-unseal setup complete
rsyslog_1        | 2016-09-15T15:10:22+00:00 vaultcluster_vault-lb_1.vaultcluster_default haproxy[8]: Server vault_pool/vault-node-02 is UP, reason: Layer7 check passed, code: 200, info: "OK", check duration: 0ms. 2 active and 0 backup servers online. 0 sessions requeued, 0 total in queue.
rsyslog_1        | 2016-09-15T15:10:30+00:00 vaultcluster_vault-lb_1.vaultcluster_default haproxy[8]: Server vault_pool/vault-node-01 is DOWN, reason: Layer4 timeout, check duration: 2002ms. 1 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
...
```

# PKI secret backend

Details see https://www.vaultproject.io/docs/secrets/pki/index.html

*TODO*
