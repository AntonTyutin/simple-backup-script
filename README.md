# Simple backup bash-script

Bash-script for making backups of files and MySQL databases.

### Requirements

* `rsync` (if used to make backup copy to remote host)
* `mysqldump` and `gzip` (if used to make database dumps)
* `tar` (if used to make files backups)

### Usage

First of all, fill in appropriate credentials to ` ~/.my.cnf`
and `~/.ssh/config` files.

Then make directory for storing backups

```bash
mkdir ~/backups
```

Create backup scenario file

```bash
cat >~/backups/.backup.conf <<EOF

# makes incremental backup of "some-project" directory (full backup after
# 5 increments) to tarball named "some-project"
INCREMENTAL=5 backup_files ~/projects some-project
# delete backup files with "some-project_files_" prefix to store recent 10 files
purge 10

# makes backup of "util1", "util2" and "util3" to tarball named "utils"
backup_files ~/bin utils util1 util2 util3
# upload created file by secure copy (ssh) to remote host
upload_ssh backup.example.com:/backups/prod-1
# upload created file to "backups" bucket of Selectel Cloud Storage
upload_selectel $SELECTEL_USER $SELECTEL_PASS backups
# delete backup files with "utils_files_" prefix to store recent 10 files
purge 10

# makes dump of "project_someproject" database to gzipped sql-file named "project_someproject"
backup_mysql project_someproject
upload_ssh backup.example.com:/backups/prod-1
upload_selectel $SELECTEL_USER $SELECTEL_PASS backups
# delete backup files with "project_someproject_mysql_" prefix to store recent 30 files
purge 30

EOF

```

Now, execute

```bash
./backup.sh ~/backups
```

That's all!
