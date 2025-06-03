# Backup S3 Cron Backup

[:star: Forked Source](https://github.com/peterrus/docker-s3-cron-backup)

## What Changed?
I used the `TARGET` environment variable and there was an issue related to double quotes.
I have that resolved in my fork.


## Variables
The container is configured via a set of required environment variables:
- `AWS_ACCESS_KEY_ID`: Get this from Amazon IAM
- `AWS_SECRET_ACCESS_KEY`: Get this from Amazon IAM, **you should keep this a secret**
- `S3_BUCKET_URL`: in most cases this should be `s3://name-of-your-bucket/`
- `AWS_DEFAULT_REGION`: The AWS region your bucket resides in
- `CRON_SCHEDULE`: Check out [crontab.guru](https://crontab.guru/) for some examples:
- `BACKUP_NAME`: A name to identify your backup among the other files in your bucket, it will be postfixed with the current timestamp (date and time)

And the following optional environment variables:
- `S3_ENDPOINT`: (Optional, defaults to whatever aws-cli provides) configurable S3 endpoint URL for non-Amazon services (e.g. [Wasabi](https://wasabi.com/) or [Minio](https://min.io/))
- `S3_STORAGE_CLASS`: (Optional, defaults to `STANDARD`) S3 storage class, see [aws cli documentation](https://docs.aws.amazon.com/cli/latest/reference/s3/cp.html) for options
- `TARGET`: (Optional, defaults to `/data`) Specifies the target location to backup. Useful for sidecar containers and to filter files.
  - Example with multiple targets: `TARGET="/var/log/*.log /var/lib/mysql/*.dmp"` (Arguments will be passed to `tar`).
- `WEBHOOK_URL`: (Optional) URL to ping after successful backup, e.g. [StatusCake push monitoring](https://www.statuscake.com/kb/knowledge-base/what-is-push-monitoring/) or [healthchecks.io](https://healthchecks.io)


### Directly via Docker
```
docker run \
  -e AWS_ACCESS_KEY_ID=SOME8AWS3ACCESS9KEY \
  -e AWS_SECRET_ACCESS_KEY=sUp3rS3cr3tK3y0fgr34ts3cr3cy \
  -e S3_BUCKET_URL=s3://name-of-your-bucket/ \
  -e AWS_DEFAULT_REGION=your-aws-region \
  -e CRON_SCHEDULE="0 * * * *" \
  -e BACKUP_NAME=make-something-up \
  -v /your/awesome/data:/data:ro \
  peterrus/s3-cron-backup
```

## It doesn't do X!

Let this container serve as a starting point and an inspiration! Feel free to modify it and even open a PR if you feel others can benefit from these changes.

## Source Contributors
- [jayesh100](https://github.com/jayesh100)
- [ifolarin](https://github.com/ifolarin)
- [stex79](https://github.com/stex79)
- [f213](https://github.com/f213)
