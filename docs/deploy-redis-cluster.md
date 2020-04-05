# Setup Redis cluster on CentOS 7

We will setup a Redis cluster include 03 nodes (06 instances), with 03 master and 03 slave instances.

Node01: 192.168.10.111
Node02: 192.168.10.112
Node03: 192.168.10.113

## Install redis server on nodes

- Install repositories and redis server

```
yum install eple-release -y
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum --enablerepo=remi install redis -y
```

- Check redis version

`redis-server --version`

*Redis server v=5.0.8 sha=00000000:0 malloc=jemalloc-5.1.0 bits=64 build=18ca9d7ea1c3e9cc*

## Setup redis instances on nodes

- Create directories contain configuration files and database files

mkdir -p /etc/redis/cluster/
mkdir -p /var/lib/redis/
chown -R redis. /etc/redis/cluster
chown -R redis. /var/lib/redis

- Create configuration files

```
cat >/etc/redis/cluster/redis_30001.conf<<EOF
port 30001
dir /var/lib/redis
appendonly yes
protected-mode no
cluster-enabled yes
cluster-node-timeout 5000
cluster-config-file /etc/redis/cluster/nodes_30001.conf
pidfile /var/run/redis_30001.pid
EOF
```

```
cat >/etc/redis/cluster/redis_30002.conf<<EOF
port 30002
dir /var/lib/redis
appendonly yes
protected-mode no
cluster-enabled yes
cluster-node-timeout 5000
cluster-config-file /etc/redis/cluster/nodes_30002.conf
pidfile /var/run/redis_30002.pid
EOF
```

- Run redis service as systemd

cat >/etc/systemd/system/redis_30001.service<<EOF
[Unit]
Description=Redis persistent key-value database
After=network.target
[Service]
ExecStart=/usr/bin/redis-server /etc/redis/cluster/redis_30001.conf --supervised systemd
ExecStop=/bin/redis-cli -h 127.0.0.1 -p 30001 shutdown
Type=notify
User=redis
Group=redis
RuntimeDirectory=/etc/redis/cluster
RuntimeDirectoryMode=0755
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/redis_30002.service<<EOF
[Unit]
Description=Redis persistent key-value database
After=network.target
[Service]
ExecStart=/usr/bin/redis-server /etc/redis/cluster/redis_30002.conf --supervised systemd
ExecStop=/bin/redis-cli -h 127.0.0.1 -p 30002 shutdown
Type=notify
User=redis
Group=root
RuntimeDirectory=/etc/redis/cluster
RuntimeDirectoryMode=0755
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

```
systemctl daemon-reload
systemctl start redis_30001.service
systemctl start redis_30002.service
```

## Redis Cluster Setup

**On the first node**

Run command the following to create redis cluster

`redis-cli --cluster create 192.168.10.111:30001 192.168.10.111:30002 192.168.10.112:30001 192.168.10.112:30002 192.168.10.113:30001 192.168.10.113:30002 --cluster-replicas 1`

>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 192.168.10.112:30002 to 192.168.10.111:30001
Adding replica 192.168.10.113:30002 to 192.168.10.112:30001
Adding replica 192.168.10.111:30002 to 192.168.10.113:30001
M: da2260124d356252841845686bb3c46275a19a0d 192.168.10.111:30001
   slots:[0-5460] (5461 slots) master
S: 0206ba833dc93e49c6bb7027804ae25c663c6e34 192.168.10.111:30002
   replicates d7a9bbb078b9310ccacb9709d92e8246b610f22a
M: 448727dad9dba52e9d17261b321e1567f45da227 192.168.10.112:30001
   slots:[5461-10922] (5462 slots) master
S: 182f43ce3236b8a16d78caa770d269e927df0ee7 192.168.10.112:30002
   replicates da2260124d356252841845686bb3c46275a19a0d
M: d7a9bbb078b9310ccacb9709d92e8246b610f22a 192.168.10.113:30001
   slots:[10923-16383] (5461 slots) master
S: 51934375bb1f5aeed182aa18f97a6b1df90fc327 192.168.10.113:30002
   replicates 448727dad9dba52e9d17261b321e1567f45da227
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
...
>>> Performing Cluster Check (using node 192.168.10.111:30001)
M: da2260124d356252841845686bb3c46275a19a0d 192.168.10.111:30001
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: 448727dad9dba52e9d17261b321e1567f45da227 192.168.10.112:30001
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
S: 182f43ce3236b8a16d78caa770d269e927df0ee7 192.168.10.112:30002
   slots: (0 slots) slave
   replicates da2260124d356252841845686bb3c46275a19a0d
S: 51934375bb1f5aeed182aa18f97a6b1df90fc327 192.168.10.113:30002
   slots: (0 slots) slave
   replicates 448727dad9dba52e9d17261b321e1567f45da227
S: 0206ba833dc93e49c6bb7027804ae25c663c6e34 192.168.10.111:30002
   slots: (0 slots) slave
   replicates d7a9bbb078b9310ccacb9709d92e8246b610f22a
M: d7a9bbb078b9310ccacb9709d92e8246b610f22a 192.168.10.113:30001
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.