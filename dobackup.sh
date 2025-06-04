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
tar -zcf "${FILE_NAME}" ${TARGET} \
  --checkpoint=800000 \
  --checkpoint-action="echo=%T"

echo "uploading archive to S3 [${FILE_NAME}, storage class - ${S3_STORAGE_CLASS}]"
aws s3 ${AWS_ARGS} cp --storage-class "${S3_STORAGE_CLASS}" "${FILE_NAME}" "${S3_BUCKET_URL}"
echo "removing local archive"
rm "${FILE_NAME}"
echo "done"

if [ -n "${WEBHOOK_URL}" ]; then
    echo "notifying webhook"
    curl -m 10 --retry 5 "${WEBHOOK_URL}"
fi
