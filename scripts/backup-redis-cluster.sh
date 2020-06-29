#!/bin/bash
## Script for backup full database
## Create by Keepwalking86

#Declare variables
SMTP_SERVER="mail.example.com:25"
SMTP_USER="notify@example.com"
SMTP_PASS="P@ssw0rd"
TO_USER="keepwalking86@example.com"
REDIS_NODE01=192.168.1.100
REDIS_NODE01_PORT01=30001

#root store directory
DEST="/backup/redis-cluster"
[[ ! -d $DEST ]] && mkdir -p $DEST

# datetime
NOW="$(date +"%Y%m%d")"
 
# Remove backups older than 7 days
find $DEST -maxdepth 1 -type f -mtime +7 -exec rm -rf {} \;

#Starting time to backup
start_time=$(date)

cluster_nodes=$(redis-cli -h $REDIS_NODE01 -p $REDIS_NODE01_PORT01 cluster nodes)
slave_nodes=$(echo "${cluster_nodes}" | grep slave | cut -d' ' -f2 | tr ' ' ',')
slave_node=$(echo "${slave_nodes}" |cut -d '@' -f1)

for slave in ${slave_node}
do
    #master_id=$(echo "${slave}" | cut -d',' -f2)
    slave_ip=$(echo "${slave}" | cut -d':' -f1)
    slave_port=$(echo "${slave}" | cut -d':' -f2)
    #Transfer rdp dump from redis slave_node to local file
    cd $DEST
    redis-cli --rdb dump-${slave_port}.rdb -h ${slave_ip} -p ${slave_port}

    # Checksum rdb files
    echo "Require redis-check-rdb same RDB format version"
    rdb_check=$(redis-check-rdb dump-${slave_port}.rdb)
    echo ${rdb_check} | grep "Checksum OK" | grep "RDB looks OK!" >/dev/null 2>&1
    #compress and move dump file
    if [ $? -eq 0 ]; then
        status="RDB dump successfully"
        mkdir -p ${DEST}/${NOW}
        dump_file=dump-${slave_ip}-${slave_port}.rdb.gz
        gzip dump-${slave_port}.rdb
        mv dump-${slave_port}.rdb.gz $DEST/${NOW}/${dump_file}
    else
        status="RDB failed!"
        rm -f dump-${slave_port}.rdb
    fi
done

# Send notify backup result
#require: install mailx
mailx -v -r "$SMTP_USER" -s "Notify Redis cluster backup" -S smtp="$SMTP_SERVER" -S smtp-auth=login -S smtp-auth-user="$SMTP_USER" -S smtp-auth-password="$SMTP_PASS" $TO_USER <<EOF
The backup job finished.
Start date: $start_time
End date: $(date)
Status: $status
EOF