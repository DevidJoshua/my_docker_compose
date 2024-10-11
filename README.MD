## Commands
```
    docker-compose --env-file envs/windows.environment -f .\plink_local_dev\plink_snap_devlocal.yml down
    
    deploy docker swarm with single env:
     
    env $(cat envs/local_plink.env | grep ^[A-Z] | xargs) docker stack deploy --compose-file plink_local_dev/plink_local_payment_ecosystem.yml plink
```
**Running with env file**
```
    docker-compose --env-file windows.environment -f standalone/mariadb.yml down
```

## Setup
### Postgresql
**Restore** 
```
    pg_restore -U deyo -d plink_local < /var/backups/dump-PLINK9-202211212146` run in container `docker exec -it [container name] bash
    or
    psql -U username -d dbname < filename.sql
```
**Backup**
```
    pg_restore -U deyo -d PLINK3 < /var/backups/PLINK3-2023-08-06.dump
```

# Mariadb
## Enter the shell
```
    > su root
    > mariadb -u deyo -p
```
