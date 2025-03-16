#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Resolve MongoDB address and port
MONGODB_HOST="${MONGODB_PORT_27017_TCP_ADDR:-${MONGODB_HOST}}"
MONGODB_HOST="${MONGODB_PORT_1_27017_TCP_ADDR:-${MONGODB_HOST}}"
MONGODB_PORT="${MONGODB_PORT_27017_TCP_PORT:-${MONGODB_PORT}}"
MONGODB_PORT="${MONGODB_PORT_1_27017_TCP_PORT:-${MONGODB_PORT}}"
MONGODB_USER="${MONGODB_USER:-${MONGODB_ENV_MONGODB_USER}}"
MONGODB_PASS="${MONGODB_PASS:-${MONGODB_ENV_MONGODB_PASS}}"

# S3 configuration
S3PATH="s3://${S3_BUCKET}/"
cat <<EOF > /.s3cfg
[default]
access_key = ${ARVAN_ACCESS_KEY}
secret_key = ${ARVAN_SECRET_KEY}
host_base = ${ARVAN_ENDPOINT_URL}
host_bucket = ${ARVAN_ENDPOINT_URL}
enable_multipart = True
multipart_chunk_size_mb = 15
use_https = True
EOF

# Default MongoDB user if not provided
[[ -z "${MONGODB_USER}" && -n "${MONGODB_PASS}" ]] && MONGODB_USER='admin'

# Command options
[[ -n "${MONGODB_USER}" ]] && USER_STR=" --username ${MONGODB_USER}"
[[ -n "${MONGODB_PASS}" ]] && PASS_STR=" --password '${MONGODB_PASS}'"
[[ -n "${MONGODB_DB}" ]] && DB_STR=" --db ${MONGODB_DB}"

# Create backup script
echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF > /backup.sh
#!/bin/bash

cp /.s3cfg /data/db/.s3cfg
cp /.s3cfg /root/.s3cfg

TIMESTAMP=\$(/bin/date +"%Y-%m-%dT%H:%M:%S")
BACKUP_NAME=\${TIMESTAMP}.dump.gz
S3BACKUP=${S3PATH}\${BACKUP_NAME}
S3LATEST=${S3PATH}latest.dump.gz

echo "=> Backup started"
if mongodump --host ${MONGODB_HOST} --port ${MONGODB_PORT} ${USER_STR}${PASS_STR} --authenticationDatabase=admin --archive=\${BACKUP_NAME} --gzip ${EXTRA_OPTS} && s3cmd put \${BACKUP_NAME} \${S3BACKUP}; then
    echo "   > Backup succeeded"
else
    echo "   > Backup failed" >&2
    exit 1
fi
echo "=> Done"
EOF
chmod +x /backup.sh
echo "=> Backup script created"

# Create restore script
echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF > /restore.sh
#!/bin/bash

RESTORE_ME="\${1:-latest}.dump.gz"
S3RESTORE=${S3PATH}\${RESTORE_ME}

echo "=> Restore database from \${RESTORE_ME}"
if s3cmd get \${S3RESTORE} \${RESTORE_ME} && mongorestore --host ${MONGODB_HOST} --port ${MONGODB_PORT} ${USER_STR}${PASS_STR}${DB_STR} --drop ${EXTRA_OPTS} --archive=\${RESTORE_ME} --gzip; then
    echo "   Restore succeeded"
    rm \${RESTORE_ME}
else
    echo "   Restore failed" >&2
    exit 1
fi
echo "=> Done"
EOF
chmod +x /restore.sh
echo "=> Restore script created"

# Create list backups script
echo "=> Creating list script"
rm -f /listbackups.sh
cat <<EOF > /listbackups.sh
#!/bin/bash

s3cmd ls ${S3PATH}
EOF
chmod +x /listbackups.sh
echo "=> List script created"

# Symlink scripts for easier access
ln -sf /restore.sh /usr/bin/restore
ln -sf /backup.sh /usr/bin/backup
ln -sf /listbackups.sh /usr/bin/listbackups

# Log file for MongoDB backup
touch /mongo_backup.log

# Initial backup if requested
if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on the startup"
    /backup.sh
fi

# Initial restore if requested
if [ -n "${INIT_RESTORE}" ]; then
    echo "=> Restore from latest backup on startup"
    /restore.sh
fi

# Setup cron job if not disabled
if [ -z "${DISABLE_CRON}" ]; then
    echo "${CRON_TIME} /backup.sh >> /mongo_backup.log 2>&1" > /crontab.conf
    crontab /crontab.conf
    echo "=> Running cron job"
    cron && tail -f /mongo_backup.log
fi
