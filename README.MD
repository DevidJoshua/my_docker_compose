
# Commands
`docker-compose -f postgresql.yml up -d`

# Setup
## Postgresql
### Restore
`pg_restore -U deyo -d plink_local < /var/backups/dump-PLINK9-202211212146` *run in container `docker exec -it [container name] bash`
