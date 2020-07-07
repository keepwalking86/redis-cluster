# Create a java app sample that all read operation on slave nodes on Redis Cluster

- Create a project

`mvn archetype:generate -DgroupId=com.keepwalking.redis -DartifactId=redis-cluster -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=false`

```
├── pom.xml
├── redis-cluster.iml
└── src
    ├── main
    │   └── java
    │       └── com
    │           └── keepwalking
    │               └── redis
    │                   └── App.java
    └── test
        └── java
            └── com
                └── keepwalking
                    └── redis
                        └── AppTest.java

11 directories, 4 files
```

- Update Pom.xml

- Build project with dependencies

`maven package`

- Update App.java

- Creating an Executable JAR with dependencies

`mvn clean compile assembly:single`

- Run java file

`java -jar target/redis-cluster-1.0-SNAPSHOT-jar-with-dependencies.jar`


