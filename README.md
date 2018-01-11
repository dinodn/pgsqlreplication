# pgsqlreplication
Tool to monitor postgres replication using PCP framework and bash scripting

This was written to integrate along with puppet module on pgsql servers that use PCP monitoring framework to measure number of stale wal files pending on system to get restored on the database.

Script will be added to Cron job, to run once in every hour, check the status of wal files, if its broken, rebase db, else sleep back.

If puppet, in node definiion of the slave host, define something like this:
  class {'base::postgres-replication':
    my_primary         => 'primary-db.localhost',  (replace with primary host)
    }

