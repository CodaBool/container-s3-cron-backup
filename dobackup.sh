#!/usr/bin/env sh

set -e

source /home/backup/.env

# default storage class to standard if not provided
S3_STORAGE_CLASS=${S3_STORAGE_CLASS:-GLACIER}
NAME=${BACKUP_NAME:-backup}

# generate file name for tar
FILE_NAME=/tmp/${NAME}-$(date "+%Y-%m-%d_%H-%M-%S").tar.gz

# Check if TARGET variable is set
if [ -z "${TARGET}" ]; then
  echo "TARGET env var is not set so we use the default value (/data)"
  TARGET=/data
fi

if [ -z "${S3_ENDPOINT}" ]; then
  AWS_ARGS=""
else
  AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

echo -e "archiving folders: ${TARGET}\n"
# 800000 is arbitrary, lower to have more checkpoints
tar -zcf "${FILE_NAME}" ${TARGET} \
  --checkpoint=800000 \
  --checkpoint-action="echo=%T"

echo -e "\nuploading to S3 [${FILE_NAME}, class - ${S3_STORAGE_CLASS}]"
aws s3 ${AWS_ARGS} cp --storage-class "${S3_STORAGE_CLASS}" "${FILE_NAME}" "${S3_BUCKET_URL}"
echo "removing local archive"
rm "${FILE_NAME}"
echo "done"

if [ -n "${WEBHOOK_URL}" ]; then
    echo "notifying webhook"
    curl -m 10 --retry 5 "${WEBHOOK_URL}"
fi

echo "checking existing backups in S3..."
BACKUP_OBJECTS=$(aws s3 ${AWS_ARGS} ls "${S3_BUCKET_URL}" | sort | awk '{print $4}')
OBJECT_COUNT=$(echo "$BACKUP_OBJECTS" | wc -l)

if [ "$OBJECT_COUNT" -gt 7 ]; then
    NUM_TO_DELETE=$(($OBJECT_COUNT - 7))
    echo "too many backups ($OBJECT_COUNT), deleting $NUM_TO_DELETE oldest..."

    echo "$BACKUP_OBJECTS" | head -n $NUM_TO_DELETE | while read -r obj; do
        echo "deleting $obj"
        aws s3 ${AWS_ARGS} rm "${S3_BUCKET_URL}${obj}"
    done
else
    echo "backup count ($OBJECT_COUNT) is within limit"
fi