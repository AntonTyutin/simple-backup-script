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

# makes backup of "some-project" directory to tarball named "some-project"
tgz ~/projects some-project
purge 10 some-project_*

# makes backup of "util1", "util2" and "util3" to tarball named "utils"
tgz ~/bin utils util1 util2 util3
purge 10 utils_*

# makes dump of "project_someproject" database to gzipped sql-file named "project_someproject"
dump project_someproject
purge 30 project_someproject_*

# stores backups to ssh-host
sync backup.example.com:/backups/prod-1

EOF

```

Now, execute

```bash
./backup.sh ~/backups
```

That's all!
