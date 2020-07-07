package com.keepwalking.redis;

import io.lettuce.core.ReadFrom;
import io.lettuce.core.RedisURI;
import io.lettuce.core.cluster.RedisClusterClient;
import io.lettuce.core.cluster.api.StatefulRedisClusterConnection;
import io.lettuce.core.cluster.api.sync.RedisAdvancedClusterCommands;

import java.util.Arrays;

/**
 * Hello world!
 *
 */
public class App {
    public static void main(String[] args) {
        //Connecting to Redis server on localhost
        RedisURI node1 = RedisURI.create("192.168.1.240", 30001);
        RedisURI node2 = RedisURI.create("192.168.1.240", 30002);
        RedisURI node3 = RedisURI.create("192.168.1.240", 30003);
        RedisURI node4 = RedisURI.create("192.168.1.240", 30004);
        RedisURI node5 = RedisURI.create("192.168.1.240", 30005);
        RedisURI node6 = RedisURI.create("192.168.1.240", 30006);

        RedisClusterClient clusterClient = RedisClusterClient.create(Arrays.asList(node1, node2, node3, node4, node5, node6));
        StatefulRedisClusterConnection<String, String> connection = clusterClient.connect();
        connection.setReadFrom(ReadFrom.REPLICA);
        System.out.println("Connected to Redis");

        RedisAdvancedClusterCommands<String, String> sync = connection.sync();
        sync.set("hi1", "keepwalking1");
        sync.set("hi2", "keepwalking2");
        sync.set("hi3", "keepwalking3");

        sync.get("hi1"); // replica read
        sync.get("hi2"); // replica read
        sync.get("hi3"); // replica read
        //sync.get(hi2); // replica read

        connection.close();
        clusterClient.shutdown();
    }
}