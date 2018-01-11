#!/bin/bash
#
# PUPPET MANAGED: This script is managed and deployed by the postgres:check-postgres-replication module
#                 Local changes will be overwritten
#
puppet_lock_file=/var/lib/puppet/state/agent_catalog_run.lock
my_primary=MYPRIMARY-DB
#my_primary="<%= my_primary %>"

# Clean up after yourself on exit
trap '_exit_trap' 0 1 2 3 6 15

# Function to execute upon termination   
_exit_trap()
{
    trap 0 1 2 3 6 15
    if [ -f "$puppet_lock_file" ] 
    then
        find $puppet_lock_file -delete
    fi
    exit 
}

rebase_pgsql() {
echo "`/bin/date +"%d-%m-%y %T"` crond: Rebasing Postgres Database" >> /var/log/messages
[ -f /usr/bin/systemctl ] && POSTGS=$(/usr/bin/systemctl  | awk '/postgres/ {print $1}' | sed 's/\.service//g' ) && /usr/bin/systemctl stop $POSTGS >/dev/null 2>&1 || POSTGS=$(/sbin/chkconfig --list | awk '/postgres/ {print $1}') && /sbin/service $POSTGS stop >/dev/null 2>&1
service puppet stop >/dev/null 2>&1
[ -d /var/lib/pgsql/9.4/data ] && find /var/lib/pgsql/9.4/data -mindepth 1 -delete || [ -d /var/lib/pgsql/9.2/data ] && find /var/lib/pgsql/9.2/data -mindepth 1 -delete
find /var/pgsql/primary-wal-archive -mindepth 1 -delete
if [ -f /usr/pgsql-9.4 ]
then
 sudo -u postgres /usr/pgsql-9.4/bin/pg_basebackup  --pgdata=/var/lib/pgsql/9.4/data/ --host=$my_primary --username=postgres --xlog-method=stream --progress --no-password >/dev/null 2>&1
elif [ -f /usr/pgsql-9.2 ]
then
 /usr/pgsql-9.2/bin/pg_basebackup --pgdata=/var/lib/pgsql/9.2/data/ --host=$my_primary --username=postgres --verbose --xlog-method=stream --progress --no-password >/dev/null 2>&1
fi 
while [ -f /var/lib/puppet/state/agent_catalog_run.lock ]
do
 sleep 30
done
puppet agent -tv >/dev/null 2>&1
service puppet start 
}

check_wal_file_status() {
log_check=`tail -10 /var/log/messages | grep postgres | egrep -i 'FATAL|ERROR|REMOVED'`
if [ $? -eq 0 ]
then
  rebase_pgsql
fi
}

check_postgres_status () {
#Getting the version of postgres and checking its status
postgres_get_version=`[ -f /usr/bin/systemctl ] && /usr/bin/systemctl  | awk '/postgres/ {print $1}' | sed 's/\.service//g'|| /sbin/chkconfig --list | awk '/postgres/ {print $1}'`
status=`[ -f /usr/bin/systemctl ] && systemctl status $postgres_get_version|grep running || service $postgres_get_version status|grep running`
if [ $? -eq 0 ]; then
  check_wal_file_status
else
   rebase_pgsql
fi
}


check_number_of_stale_wal_files() {
 count=`pminfo -F lockfiles.stale.files |grep primary-wal-archive|wc -l`
 if [ $count > 50 ]
 then
   check_postgres_status
 fi
}

check_number_of_stale_wal_files
