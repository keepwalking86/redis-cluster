## About Redis

Redis thường được gọi là máy chủ cấu trúc dữ liệu, có thể được sử dụng như một database, cache hoặc message broker. Nó lưu trữ dữ liệu kiểu key-value. Redis hỗ rất nhiều kiểu cấu trúc dữ liệu như Strings, Lists, Sets, Sorted Sets, Hashes, HyperLogLogs, Bitmaps

Cấu trúc dữ liệu được đưa vào Redis có một số thuộc tính đặc biệt sau:

- Redis quan tâm đến phần lưu trữ dữ liệu trên disk, ngay cả khi chúng đang thực hiện việc xử lý trong memory. Nghĩa là Redis có thể vừa xử lý nhanh thông qua memory, và cũng an toàn hơn khi data đã lưu ở trên disk.

- Redis sử dụng ít memory hơn khi so sánh với các language khác có cùng mô hình cấu trúc dữ liệu

- Redis cung cấp đầy đủ các tính năng như replication, cluster, high available

## About Redis Cluster

Redis cluster cung cấp cách thức cài đặt redis mà dữ liệu tự động sharding qua nhiều node redis.

Redis cluster cung cấp vài cấp độ phân vùng dữ liệu mà cho phép tiếp tục thao tác dữ liệu khi một vài redis nodes lỗi hoặc không có sẵn (Tất nhiên vì một số node redis lỗi hoặc không thể giao tiếp được nên thao tác lấy dữ liệu từ ứng dụng đến redis sẽ chậm). Tuy nhiên cluster dừng thao tác khi có số lượng lỗi lớn như nhiều master node lỗi chẳng hạn.

## Install redis cluster from source

Requirement: Redis-3.0+

03 nodes:

- node01: 192.168.10.111
- node02: 192.168.10.112
- node03: 192.168.10.113

**Step1: Download script**

- Thực hiện download script đến 03 nodes

Thực hiện download source tại: [https://github.com/antirez/redis](https://github.com/antirez/redis). 

Phiên bản hiện tại là 5. Ở đây, chúng ta thực hiện với phiên bản thấp hơn là 4.0

```
cd /opt/
wget https://github.com/antirez/redis/archive/4.0.11.tar.gz
tar zxvf 4.0.11.tar.gz
mv redis-4.0.11 redis
```

**Step2: Build redis**

Chúng ta thực hiện build redis trước khi create instance và cluster

```
cd /opt/redis
make
make test
```

**Step3: Tạo instance trên node01**

Chúng ta sử script `create-cluster` để tạo instance và cluster thay vì thao tác thủ công.

- Thực hiện sửa tệp cấu hình redis trên node01

`cd /opt/redis/utils/create-cluster`

Chúng ta sửa tệp **create-cluster** với một số nội dung sau cho phù hợp với nhu cầu (read from create-cluster). Với một số chú ý như sau:

- NODES=3 Số node cần create cluster
- REPLICAS=1 nghĩa là sẽ tạo 01 slave với mỗi node master tạo ra. 
- BIND_HOST=192.168.1.X Gán địa chỉ IP để cho phép giao tiếp với các nodes trong cluster (mặc định BIND_HOST=127.0.0.1, vì vậy chỉ có thể truy cập chính node đó)

Ngoài ra thêm giá trị tùy chọn `--protected-mode no --bind $BIND_HOST --maxmemory 5120mb` khi tạo instance. Với ý nghĩa như sau:

- protected-mode no --> Thiết lập chế độ không yêu cầu authentication, cho test
- bind $BIND_HOST --> Gán giá trị địa chỉ IP cho node
- maxmemory 5120mb --> Thiết lập giá trị lưu trữ in-memory cho redis là 5120mb

Thực hiện start create-cluster để tạo instance

`./create-cluster start`

Check instances đang chạy

`netstat -ntlp`

- Check version của redis

`/opt/redis/src/redis-cli -h 192.168.1.223 -p 30001 -v`

Copy nội dung tệp **create-cluster** đến 02 nodes còn lại

```
scp create-cluster root@192.168.10.112:/opt/redis/utils/create-cluster
scp create-cluster root@192.168.10.113:/opt/redis/utils/create-cluster
```

**Step4: Thực hiện chạy redis trên 02 nodes còn lại**

Sửa nội dung tệp cấu hình create-cluster

Thay giá trị **BIND_HOST=192.168.1.112** và **BIND_HOST=192.168.1.113** tương ứng với IP của redis server đang cấu hình

Start redis

`./create-cluster start`

**Step5: Thực hiện tạo cluster và replicas**

Sau khi tạo và chạy các instances, chúng ta thực hiện tạo cluster với replicas cho redis. Với phiên bản redis 5, chúng ta dễ dàng thực hiện tạo cluster với dòng lệnh `redis-cli`. Đối với redis version 3 hoặc 4, chúng ta sử dụng công cụ dòng lệnh cũ hơn là `redis-trib.rb`. Để chạy được `redis-trib.rb`, chúng ta cần cài đặt **redis gem**

- Install RVM

rvm( Ruby version manager) dùng quản lý gói ruby. Mặc định trong repo của centos 7 chỉ có sẵn ruby-2.0. Trong khi yêu cầu về cài đặt redis các version sau này yêu cầu ruby bản cao hơn 2.3+.

```
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L get.rvm.io | bash -s stable
```

- Load RVM environment

```
source /etc/profile.d/rvm.sh
rvm reload
```

- Install ruby

Tùy thuộc vào nhu cầu để cài phiên bản ruby phù hợp. Ở đây, tôi cài đặt ruby-2.6.

`rvm install 2.6`

- Install gem và redis

```
yum install gem -y
gem install redis
```

- Thực hiện tạo cluster cho replicas với 6 nodes (03 masters và 03 slaves)

```
./create-cluster create
>>> Creating cluster
>>> Performing hash slots allocation on 6 nodes...
Using 3 masters:
192.168.1.223:30001
192.168.1.223:30002
192.168.1.223:30003
Adding replica 192.168.1.223:30005 to 192.168.1.223:30001
Adding replica 192.168.1.223:30006 to 192.168.1.223:30002
Adding replica 192.168.1.223:30004 to 192.168.1.223:30003
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: 81d8753dcb0e6c6022312511969373aeb580e119 192.168.1.223:30001
   slots:0-5460 (5461 slots) master
M: 1285aab406fb15c4f08c1950fb909fef551e9cc6 192.168.1.223:30002
   slots:5461-10922 (5462 slots) master
M: a613930c2c310008dfa6ca58e4ed10e9e015badc 192.168.1.223:30003
   slots:10923-16383 (5461 slots) master
S: 70ef3ed73afada2484d678cb186e89aec95e6602 192.168.1.223:30004
   replicates 1285aab406fb15c4f08c1950fb909fef551e9cc6
S: e648bad5eaed144c4339120f779d771ce386c7a7 192.168.1.223:30005
   replicates a613930c2c310008dfa6ca58e4ed10e9e015badc
S: 44fe5f17f9ae41649b3a3fbd88cfcb5c36230fd5 192.168.1.223:30006
   replicates 81d8753dcb0e6c6022312511969373aeb580e119
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join..
>>> Performing Cluster Check (using node 192.168.1.223:30001)
M: 81d8753dcb0e6c6022312511969373aeb580e119 192.168.1.223:30001
   slots:0-5460 (5461 slots) master
   1 additional replica(s)
M: 1285aab406fb15c4f08c1950fb909fef551e9cc6 192.168.1.223:30002
   slots:5461-10922 (5462 slots) master
   1 additional replica(s)
M: a613930c2c310008dfa6ca58e4ed10e9e015badc 192.168.1.223:30003
   slots:10923-16383 (5461 slots) master
   1 additional replica(s)
S: e648bad5eaed144c4339120f779d771ce386c7a7 192.168.1.223:30005
   slots: (0 slots) slave
   replicates a613930c2c310008dfa6ca58e4ed10e9e015badc
S: 44fe5f17f9ae41649b3a3fbd88cfcb5c36230fd5 192.168.1.223:30006
   slots: (0 slots) slave
   replicates 81d8753dcb0e6c6022312511969373aeb580e119
S: 70ef3ed73afada2484d678cb186e89aec95e6602 192.168.1.223:30004
   slots: (0 slots) slave
   replicates 1285aab406fb15c4f08c1950fb909fef551e9cc6
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

**Step6: Thực hiện kiểm tra thông tin cluster**

- Truy cập redis với tool redis-cli

`/opt/redis/src/redis-cli -h 192.168.1.223 -p 30001`

- Check thông tin tổng quan của cluster

```
192.168.1.223:30001> INFO
#Server
redis_version:4.0.11
redis_git_sha1:00000000
redis_git_dirty:0
redis_build_id:3020d12947b9f562
redis_mode:cluster
os:Linux 3.10.0-957.5.1.el7.x86_64 x86_64
arch_bits:64
multiplexing_api:epoll
atomicvar_api:atomic-builtin
gcc_version:4.8.5
process_id:9043
run_id:3a28ff03429ad6123e3fdcd89638ada4b5ff53c6
tcp_port:30001
uptime_in_seconds:3504
uptime_in_days:0
hz:10
lru_clock:413144
executable:/root/redis/src/redis-server
config_file:

#Clients
connected_clients:1
client_longest_output_list:0
client_biggest_input_buf:0
blocked_clients:0

#Memory
used_memory:2642048
used_memory_human:2.52M
used_memory_rss:10076160
used_memory_rss_human:9.61M
used_memory_peak:2681768
used_memory_peak_human:2.56M
used_memory_peak_perc:98.52%
used_memory_overhead:2560504
used_memory_startup:1445368
used_memory_dataset:81544
used_memory_dataset_perc:6.81%
total_system_memory:3973615616
total_system_memory_human:3.70G
used_memory_lua:37888
used_memory_lua_human:37.00K
maxmemory:5368709120
maxmemory_human:5.00G
maxmemory_policy:noeviction
mem_fragmentation_ratio:3.81
mem_allocator:jemalloc-4.0.3
active_defrag_running:0
lazyfree_pending_objects:0

#Persistence
loading:0
rdb_changes_since_last_save:2
rdb_bgsave_in_progress:0
rdb_last_save_time:1560690832
rdb_last_bgsave_status:ok
rdb_last_bgsave_time_sec:1
rdb_current_bgsave_time_sec:-1
rdb_last_cow_size:6467584
aof_enabled:1
aof_rewrite_in_progress:0
aof_rewrite_scheduled:0
aof_last_rewrite_time_sec:-1
aof_current_rewrite_time_sec:-1
aof_last_bgrewrite_status:ok
aof_last_write_status:ok
aof_last_cow_size:0
aof_current_size:81
aof_base_size:0
aof_pending_rewrite:0
aof_buffer_length:0
aof_rewrite_buffer_length:0
aof_pending_bio_fsync:0
aof_delayed_fsync:0

#Stats
total_connections_received:11
total_commands_processed:3301
instantaneous_ops_per_sec:1
total_net_input_bytes:174311
total_net_output_bytes:112410
instantaneous_input_kbps:0.04
instantaneous_output_kbps:0.00
rejected_connections:0
sync_full:1
sync_partial_ok:0
sync_partial_err:1
expired_keys:0
expired_stale_perc:0.00
expired_time_cap_reached_count:0
evicted_keys:0
keyspace_hits:0
keyspace_misses:0
pubsub_channels:0
pubsub_patterns:0
latest_fork_usec:649
migrate_cached_sockets:0
slave_expires_tracked_keys:0
active_defrag_hits:0
active_defrag_misses:0
active_defrag_key_hits:0
active_defrag_key_misses:0
#Replication
role:master
connected_slaves:1
slave0:ip=192.168.1.223,port=30006,state=online,offset=1036,lag=1
master_replid:80dcd3540523da23fb78280576aaa609a45eaf2b
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:1036
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:1036

#CPU
used_cpu_sys:1.26
used_cpu_user:0.64
used_cpu_sys_children:0.00
used_cpu_user_children:0.00

#Cluster
cluster_enabled:1

#Keyspace
```
Khi đó ta thấy các thông tin về redis như: version, connect, cpu, memory, ..

- Check thông tin replication

```
192.168.1.223:30001> info replication
#Replication
role:master
connected_slaves:1
slave0:ip=192.168.1.223,port=30006,state=online,offset=4463,lag=0
master_replid:80dcd3540523da23fb78280576aaa609a45eaf2b
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:4463
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:4463
```

Ở đây, ta thấy bind port hiện tại 192.168.1.223:30001 có vai trò là master và có 01 slave0 đang connect là 192.168.1.223:30006

```
172.25.80.78:30001> INFO replication
#Replication
role:master
connected_slaves:1
slave0:ip=172.25.80.77,port=30002,state=online,offset=142295630168,lag=1
master_replid:93ac7e41dd61cbb298bf864fb270b49e16400f70
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:142295630182
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:142294581607
repl_backlog_histlen:1048576
172.25.80.78:30001> 
```

**Check benchmark redis**

`redis-benchmark -h localhost -p 30001 -q -n 1000 -c 10 -P 5`

Ý nghĩa:

Chạy redis-benchmark ở chế độ quiet, thực hiện tổng 1000 requests, chạy với 10 kết nối song song và pipepline 5 requests.

kết quả:

```
PING_INLINE: 142857.14 requests per second
PING_BULK: 166666.67 requests per second
SET: 124999.99 requests per second
GET: 124999.99 requests per second
INCR: 124999.99 requests per second
LPUSH: 111111.12 requests per second
RPUSH: 124999.99 requests per second
LPOP: 124999.99 requests per second
RPOP: 124999.99 requests per second
SADD: 142857.14 requests per second
HSET: 142857.14 requests per second
SPOP: 142857.14 requests per second
LPUSH (needed to benchmark LRANGE): 142857.14 requests per second
LRANGE_100 (first 100 elements): 43478.26 requests per second
LRANGE_300 (first 300 elements): 15873.02 requests per second
LRANGE_500 (first 450 elements): 8695.65 requests per second
LRANGE_600 (first 600 elements): 7042.25 requests per second
MSET (10 keys): 111111.12 requests per second
```
