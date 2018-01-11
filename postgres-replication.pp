class base::postgres-replication (
   $my_primary
)  { 
    
    file {'/usr/bin/check_postgres_replication':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 755,
        content => template('base/postgres/check_pgsql_replication.sh')
    }
   
    file {'/etc/cron.d/postgres_replication':
        ensure => present,
        source => 'puppet:///modules/aconex/cron.d_files/check_postgres_replication.cron',
        owner   => root,
        group   => root,
        mode    => 644
    }
}

