#!/bin/sh

if [ ! -d "/run/mysqld" ]; then
  mkdir -p /run/mysqld
  chown -R mysql:mysql /run/mysqld
fi

if [ -d /var/lib/mysql/mysql ]; then
  echo "[i] MySQL directory already present, skipping creation"
else
  echo "[i] MySQL data directory not found, creating initial DBs"

  chown -R mysql:mysql /var/lib/mysql

  mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql > /dev/null

  MYSQL_DATABASE=${MYSQL_DATABASE:-""}
  MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

  tfile=`mktemp`
  if [ ! -f "$tfile" ]; then
      return 1
  fi

  cat << EOF > $tfile
CREATE DATABASE IF NOT EXISTS \`mysql\` CHARACTER SET utf8 COLLATE utf8_general_ci;
USE mysql;
FLUSH PRIVILEGES;
CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
FLUSH PRIVILEGES;
EOF

  if [ "$MYSQL_DATABASE" != "" ]; then
    echo "[i] Creating database: $MYSQL_DATABASE"
    echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile
  fi

  /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 < $tfile
  rm -f $tfile
fi

exec /usr/bin/mysqld --user=mysql --console

