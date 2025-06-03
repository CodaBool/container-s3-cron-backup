build:
  docker build -t backup-to-s3 .

upload:
  docker build -t ghcr.io/codabool/backup-to-s3:latest .
  docker push ghcr.io/codabool/backup-to-s3:latest
