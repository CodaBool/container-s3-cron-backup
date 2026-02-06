#!/usr/bin/env sh
set -e

# alpine /bin/sh doesn't guarantee "source" in all shells; "." is POSIX
. /home/backup/.env

NAME=${BACKUP_NAME:-backup}
KEEP_LAST=${KEEP_LAST:-7}

FILE_NAME="/tmp/${NAME}-$(date "+%Y-%m-%d_%H-%M-%S").tar.gz"

if [ -z "${TARGET}" ]; then
  echo "TARGET env var is not set so we use the default value (/data)"
  TARGET=/data
fi

AWS_ARGS=""
if [ -n "${R2_ENDPOINT}" ]; then
  AWS_ARGS="--endpoint-url ${R2_ENDPOINT}"
fi


echo -e "archiving folders: ${TARGET}\n"
tar -zcf "${FILE_NAME}" ${TARGET} \
  --ignore-failed-read \
  --checkpoint=800000 \
  --checkpoint-action="echo=%T"

echo -e "\nuploading to R2 [${FILE_NAME}]"

aws s3 --endpoint-url ${R2_BUCKET_URL} cp "${FILE_NAME}" "s3://${BUCKET}"

echo "removing local archive"
rm "${FILE_NAME}"
echo "done"

if [ -n "${WEBHOOK_URL}" ]; then
  echo "notifying webhook"
  curl -m 10 --retry 5 "${WEBHOOK_URL}"
fi

echo "R2_ENDPOINT=$R2_ENDPOINT"
echo "R2_BUCKET_URL=$R2_BUCKET_URL"
echo "BUCKET=$BUCKET"

echo "SANITY CHECK: $R2_ENDPOINT"
aws s3 --endpoint-url "$R2_BUCKET_URL" ls
aws s3 --endpoint-url "$R2_BUCKET_URL" ls "s3://$BUCKET/"


echo "checking existing backups..."
BACKUP_OBJECTS="$(
  aws s3 --endpoint-url ${R2_BUCKET_URL} ls "s3://${BUCKET}/" |
    awk '{print $4}' |
    grep -v '^$' |
    sort
)"

OBJECT_COUNT="$(printf "%s\n" "$BACKUP_OBJECTS" | grep -c '.*' || true)"


if [ "$OBJECT_COUNT" -gt "$KEEP_LAST" ]; then
  NUM_TO_DELETE=$((OBJECT_COUNT - KEEP_LAST))
  echo "too many backups ($OBJECT_COUNT), deleting $NUM_TO_DELETE oldest..."

  printf "%s\n" "$BACKUP_OBJECTS" | head -n "$NUM_TO_DELETE" | while read -r obj; do
    [ -z "$obj" ] && continue
    echo "deleting $obj"
    aws s3 ${AWS_ARGS} rm "${R2_BUCKET_URL}${obj}"
  done
else
  echo "backup count ($OBJECT_COUNT) is within limit"
fi
