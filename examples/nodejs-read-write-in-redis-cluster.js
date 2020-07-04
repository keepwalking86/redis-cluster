//requirement: enable readonly mode
//https://github.com/luin/ioredis
var Redis = require("ioredis");
var cluster = new Redis.Cluster([
{
port: 30001,
host: "192.168.1.240",
},
{
port: 30002,
host: "192.168.1.240",
},
{
port: 30003,
host: "192.168.1.240",
},
{
port: 30004,
host: "192.168.1.240",
},
{
port: 30005,
host: "192.168.1.240",
},
{
port: 30006,
host: "192.168.1.240",
},
],
{
scaleReads: "slave",
}
);

cluster.set("hi", "Keepwalking");
cluster.get("hi", function (err, res) {
console.log(res);
});
cluster.set("hi2", "Keepwalking2");
cluster.get("hi2", function (err, res) {
console.log(res);
});
cluster.set("hi3", "Keepwalking3");
cluster.get("hi3", function (err, res) {
console.log(res);
});
cluster.set("hi4", "Keepwalking4");
cluster.get("hi4", function (err, res) {
console.log(res);
});
