# mongodb-backup-s3

This image runs mongodump to backup data using cronjob to an arvancloud s3 bucket

## Usage:

```
docker run -d \
  --env ARVAN_ACCESS_KEY=arvancloud_access_key \
  --env ARVAN_SECRET_KEY=arvancloud_secret_key \
  --env ARVAN_ENDPOINT_URL=https://s3.ir-thr-at1.arvanstorage.com \
  --env BUCKET=your_bucket_name \
  --env MONGODB_HOST=mongodb.host \
  --env MONGODB_PORT=27017 \
  --env MONGODB_USER=admin \
  --env MONGODB_PASS=password \
  amirmohseninia/mongodb-backup-arvan-s3
```

If you link `amirmohseninia/mongodb-backup-arvan-s3` to a mongodb container with an alias named mongodb, this image will try to auto load the `host`, `port`, `user`, `pass` if possible. Like this:

```
docker run -d \
  --env ARVAN_ACCESS_KEY=arvancloud_access_key \
  --env ARVAN_SECRET_KEY=arvancloud_secret_key \
  --env BUCKET=mybucketname \
  --env BACKUP_FOLDER=a/sub/folder/path/ \
  --env INIT_BACKUP=true \
  --link my_mongo_db:mongodb \
  amirmohseninia/mongodb-backup-arvan-s3
```

Add to a docker-compose.yml to enhance your robotic army:

For automated backups
```
mongodbbackup:
  image: 'amirmohseninia/mongodb-backup-arvan-s3:latest'
  links:
    - mongodb
  environment:
    - ARVAN_ACCESS_KEY=arvancloud_access_key
    - ARVAN_SECRET_KEY=arvancloud_secret_key
    - BUCKET=my-s3-bucket
    - BACKUP_FOLDER=prod/db/
  restart: always
```

Or use `INIT_RESTORE` with `DISABLE_CRON` for seeding/restoring/starting a db (great for a fresh instance or a dev machine)
```
mongodbbackup:
  image: 'amirmohseninia/mongodb-backup-arvan-s3:latest'
  links:
    - mongodb
  environment:
    - ARVAN_ACCESS_KEY=arvancloud_access_key
    - ARVAN_SECRET_KEY=arvancloud_secret_key
    - BUCKET=my-s3-bucket
    - BACKUP_FOLDER=prod/db/
    - INIT_RESTORE=true
    - DISABLE_CRON=true
```

## Parameters

`ARVAN_ACCESS_KEY` - your arvancloud access key (for your s3 bucket)

`ARVAN_SECRET_KEY`: - your arvancloud secret key (for your s3 bucket)

`ARVAN_ENDPOINT_URL`: - your arvancloud endpoint url (for your s3 bucket)

`BUCKET`: - your s3 bucket name

`BACKUP_FOLDER`: - name of folder or path to put backups (eg `myapp/db_backups/`). defaults to root of bucket.

`MONGODB_HOST` - the host/ip of your mongodb database

`MONGODB_PORT` - the port number of your mongodb database

`MONGODB_USER` - the username of your mongodb database. If MONGODB_USER is empty while MONGODB_PASS is not, the image will use admin as the default username

`MONGODB_PASS` - the password of your mongodb database

`MONGODB_DB` - the database name to dump. If not specified, it will dump all the databases

`EXTRA_OPTS` - any extra options to pass to mongodump command

`CRON_TIME` - the interval of cron job to run mongodump. `0 3 * * *` by default, which is every day at 03:00hrs.

`TZ` - timezone. default: `Asia/Tehran`

`CRON_TZ` - cron timezone. default: `Asia/Tehran`

`INIT_BACKUP` - if set, create a backup when the container launched

`INIT_RESTORE` - if set, restore from latest when container is launched

`DISABLE_CRON` - if set, it will skip setting up automated backups. good for when you want to use this container to seed a dev environment.

## Restore from a backup

To see the list of backups, you can run:
```
docker exec mongodb-backup-s3 /listbackups.sh
```

To restore database from a certain backup, simply run (pass in just the timestamp part of the filename):

```
docker exec mongodb-backup-s3 /restore.sh 20170406T155812
```

To restore latest just:
```
docker exec mongodb-backup-s3 /restore.sh
```

## Acknowledgements

  * forked from [halvves](https://github.com/halvves)'s fork of [halvves/mongodb-backup-s3](https://github.com/halvves/mongodb-backup-s3)
