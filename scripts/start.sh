#!/bin/bash
# Starts up MariaDB within the container.

# Stop on error
set -e


DATA_DIR=/data
MYSQL_LOG=$DATA_DIR/mysql.log
PIWIK_DIR=/var/lib/piwik

if [[ -e /firstrun ]]; then
  source /scripts/first_run.sh
else
  source /scripts/normal_run.sh
fi

# Make sure Piwik config file is symlinked from volume -> www dir
if [[ ! -L "/var/www/html/config" ]]; then
    cp -R /var/www/html/config $PIWIK_DIR
    rm -rf /var/www/html/config
    chmod a+w $PIWIK_DIR/config
    ln -s /var/lib/piwik/config /var/www/html/config
fi

wait_for_mysql_and_run_post_start_action() {
  # Wait for mysql to finish starting up first.
  while [[ ! -e /run/mysqld/mysqld.sock ]] ; do
      inotifywait -q -e create /run/mysqld/ >> /dev/null
  done

  post_start_action
}

pre_start_action

wait_for_mysql_and_run_post_start_action &


echo "Starting Apache..."
service apache2 start

# Start MariaDB
echo "Starting MariaDB..."
exec /usr/bin/mysqld_safe --skip-syslog --log-error=$MYSQL_LOG
