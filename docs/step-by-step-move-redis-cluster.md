# I. Requirements

**Old Servers**

- 192.168.1.11 port 30001,30002

- 192.168.1.12 port 30001,30002

- 192.168.1.13 port 30001,30002

**New Servers**

- 192.168.1.31 port 30001,30002

- 192.168.1.32 port 30001,30002

- 192.168.1.33 port 30001,30002

# II. Deployments

Các bước chuyển từ Redis cluster đến hệ thống mới redis cluster mới.

- Trong qúa trình start redis cluster, yêu cầu turn off AppendOnlyFile(.aof)

## Step1: Dump data trên từng old redis servers (master instances)

Thực hiện dump all redis instances với chế độ `BGSAVE`, tức là quá trình hệ thống cũ vẫn hoạt động bình thường

```
/opt/redis/src/redis-cli -h 192.168.1.11 -p 30001
192.168.1.11:30001>BGSAVE
/opt/redis/src/redis-cli -h 192.168.1.12 -p 30001
192.168.1.12:30001>BGSAVE
/opt/redis/src/redis-cli -h 192.168.1.13 -p 30001
192.168.1.13:30001>BGSAVE
/opt/redis/src/redis-cli -h 192.168.1.11 -p 30002
192.168.1.11:30002>BGSAVE
/opt/redis/src/redis-cli -h 192.168.1.12 -p 30002
192.168.1.12:30002>BGSAVE
/opt/redis/src/redis-cli -h 192.168.1.13 -p 30002
192.168.1.13:30002>BGSAVE
```

## Step2: Cài đặt Redis cluster trên 03 nodes với cấu hình appendonly=no

- Copy bộ cài redis-5.0.6 lên 03 nodes vào thư mục /opt/redis

- Start redis trên 03 nodes

```
cd /opt/redis/utils/create-cluster
./create-cluster start
```

Kiểm tra thông tin các instance xem:

```
[root@db1 create-cluster]# ../../src/redis-cli -h 192.168.1.31 -p 30001 info replication
# Replication
role:master
connected_slaves:0
master_replid:5836d772e7e0fbcb7807a2264569f0a8fd1fba8f
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:0
second_repl_offset:-1
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
[root@db1 create-cluster]# ../../src/redis-cli -h 192.168.1.31 -p 30002 info replication
# Replication
role:master
connected_slaves:0
master_replid:816fabe2746344b099c7c5510af35490f938fb8c
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:0
second_repl_offset:-1
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
```

Lúc này chúng ta thấy instance vẫn là các host độc lập, đều ở role là master.

- Create cluster trên node01

cd /opt/redis/utils/create-cluster

./create-cluster create

```
./create-cluster create
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 192.168.1.32:30002 to 192.168.1.31:30001
Adding replica 192.168.1.33:30002 to 192.168.1.32:30001
Adding replica 192.168.1.31:30002 to 192.168.1.33:30001
M: 696af2c06bf2e02ec12ec78d102f3a16c55f8732 192.168.1.31:30001
   slots:[0-5460] (5461 slots) master
M: e911dffb0ac4e4f58da3a43a82a2ca33cf27933e 192.168.1.32:30001
   slots:[5461-10922] (5462 slots) master
M: 0802d3965bad300a5bdba071fa881aa856691600 192.168.1.33:30001
   slots:[10923-16383] (5461 slots) master
S: 515809a113cc52bb260c37d37b6ffbee0b86795f 192.168.1.31:30002
   replicates 0802d3965bad300a5bdba071fa881aa856691600
S: 52a9915d2fbf300f7167ebca8c2a396b62879756 192.168.1.32:30002
   replicates 696af2c06bf2e02ec12ec78d102f3a16c55f8732
S: 389437d7f5dcd71734ec4e78fada5d2af21b57c4 192.168.1.33:30002
   replicates e911dffb0ac4e4f58da3a43a82a2ca33cf27933e
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
..
>>> Performing Cluster Check (using node 192.168.1.31:30001)
M: 696af2c06bf2e02ec12ec78d102f3a16c55f8732 192.168.1.31:30001
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: e911dffb0ac4e4f58da3a43a82a2ca33cf27933e 192.168.1.32:30001
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
S: 389437d7f5dcd71734ec4e78fada5d2af21b57c4 192.168.1.33:30002
   slots: (0 slots) slave
   replicates e911dffb0ac4e4f58da3a43a82a2ca33cf27933e
M: 0802d3965bad300a5bdba071fa881aa856691600 192.168.1.33:30001
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 515809a113cc52bb260c37d37b6ffbee0b86795f 192.168.1.31:30002
   slots: (0 slots) slave
   replicates 0802d3965bad300a5bdba071fa881aa856691600
S: 52a9915d2fbf300f7167ebca8c2a396b62879756 192.168.1.32:30002
   slots: (0 slots) slave
   replicates 696af2c06bf2e02ec12ec78d102f3a16c55f8732
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

Kiểm tra thông tin các instance

```
[root@db1 create-cluster]# ../../src/redis-cli -h 192.168.1.31 -p 30002 info replication
# Replication
role:slave
master_host:192.168.1.33
master_port:30001
master_link_status:up
master_last_io_seconds_ago:1
master_sync_in_progress:0
slave_repl_offset:182
slave_priority:100
slave_read_only:1
connected_slaves:0
master_replid:c8da87a8e7f3568cca0e227bc106d5fc61c5d5e0
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:182
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:182
```

## Step3: Copy dump (.rdb) đến new redis server

- Stop redis trên 03 nodes

Thực hiện stop redis trên 03 nodes trước khi copy rdb từ old redis servers đến new redis servers

```
cd /opt/redis/utils/create-cluster
./create-cluster stop
```

- Copy rdb từ các master redis hiện tại đến master redis mới tương ứng

**On 192.168.1.11**

Thực hiện copy dump files đến 192.168.1.31

```
scp /opt/redis/utils/create-cluster/dump-30001.rdb root@192.168.1.31:/opt/redis/utils/create-cluster/

scp /opt/redis/utils/create-cluster/dump-30001.rdb root@192.168.1.31:/opt/redis/utils/create-cluster/
```

**On 192.168.1.12**

Thực hiện copy dump files đến 192.168.1.32

```
scp /opt/redis/utils/create-cluster/dump-30001.rdb root@192.168.1.32:/opt/redis/utils/create-cluster/

scp /opt/redis/utils/create-cluster/dump-30001.rdb root@192.168.1.32:/opt/redis/utils/create-cluster/
```

**On 192.168.1.13**

Thực hiện copy dump files đến 192.168.1.33

```
scp /opt/redis/utils/create-cluster/dump-30001.rdb root@192.168.1.33:/opt/redis/utils/create-cluster/

scp /opt/redis/utils/create-cluster/dump-30001.rdb root@192.168.1.33:/opt/redis/utils/create-cluster/
```

## Step4: Start redis on nodes


**On 192.168.1.31**

```
cd /root/redis/utils/create-cluster/
./create-cluster start
```

**On 192.168.1.32**

```
cd /root/redis/utils/create-cluster/
./create-cluster start
```

**On 192.168.1.33**

```
cd /root/redis/utils/create-cluster/
./create-cluster start
```

Khi các redis instance được start, nó đọc dữ liệu từ tệp dump sau đó load dữ liệu vào memory.

## Step5: Enable AppendOnly (AOF)

Trong trường hợp cần cố định log write xuống disk, thực hiện enable appendonly=yes ( Trường hợp không cần thiết có thể bỏ qua bước này)

Thực hiện chạy lệnh sau trên các redis instance để enable Append Only File (AOF)

```
redis-cli -h 192.168.1.31 -p 30001
>config set appendonly yes

redis-cli -h 192.168.1.32 -p 30001
>config set appendonly yes

redis-cli -h 192.168.1.33 -p 30001
>config set appendonly yes

redis-cli -h 192.168.1.31 -p 30002
>config set appendonly yes

redis-cli -h 192.168.1.32 -p 30002
>config set appendonly yes

redis-cli -h 192.168.1.33 -p 30002
>config set appendonly yes
```