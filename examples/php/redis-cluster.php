<!-- https://github.com/phpredis/phpredis -->
<?php

$servers = array(
   'tcp://192.168.1.240:30001',
   'tcp://192.168.1.240:30002',
   'tcp://192.168.1.240:30003',
   'tcp://192.168.1.240:30004',
   'tcp://192.168.1.240:30005',
   'tcp://192.168.1.240:30006',
);

// $client = new RedisCluster(NULL, Array('192.168.1.240:30001', '192.168.1.240:30002','192.168.1.240:30003','192.168.1.240:30004','192.168.1.240:30005','192.168.1.240:30006'));
$client = new RedisCluster(NULL, $servers);
$client->setOption(
   RedisCluster::OPT_SLAVE_FAILOVER, RedisCluster::FAILOVER_DISTRIBUTE
);

$client->set("hello1", "keepwalking1");
$client->set("hello2", "keepwalking2");
$client->set("hello3", "keepwalking3");
$client->set("hello4", "keepwalking4");
$client->set("hello5", "keepwalking5");
$client->set("hello6", "keepwalking6");

$key1 = $client->get('hello1');
$key2 = $client->get('hello2');
$key3 = $client->get('hello3');
$key4 = $client->get('hello4');
$key5 = $client->get('hello5');
$key6 = $client->get('hello6');
var_dump($key1, $key2, $key3, $key4, $key5, $key6);die;
?>
