#!/usr/bin/env sh

set -e

cat << EOF > /home/backup/.env
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-auto}
export BACKUP_NAME=${BACKUP_NAME}
export TARGET="${TARGET}"
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
export R2_BUCKET_URL=${R2_BUCKET_URL}
export BUCKET=${BUCKET:-backup}
export R2_STORAGE_CLASS=${R2_STORAGE_CLASS}
export R2_ENDPOINT=${R2_ENDPOINT}
EOF

echo "creating crontab"
printf "${CRON_SCHEDULE} su - backup -c /dobackup.sh\n" > /tmp/crontab
crontab - < /tmp/crontab

echo "starting $@"
exec "$@"
