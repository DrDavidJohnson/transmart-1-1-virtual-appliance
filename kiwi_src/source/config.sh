#!/bin/bash
#================
# FILE          : config.sh
#----------------
# PROJECT       : OpenSuSE KIWI Image System
# COPYRIGHT     : (c) 2006 SUSE LINUX Products GmbH. All rights reserved
#               :
# AUTHOR        : Marcus Schaefer <ms@suse.de>
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : configuration script for SUSE based
#               : operating systems
#               :
#               :
# STATUS        : BETA
#----------------
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$name]..."

#======================================
# SuSEconfig
#--------------------------------------
echo "** Running suseConfig..."
suseConfig

echo "** Running ldconfig..."
/sbin/ldconfig

#======================================
# Setup default runlevel
#--------------------------------------
baseSetRunlevel 3

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
suseImportBuildKey


sed --in-place -e 's/# solver.onlyRequires.*/solver.onlyRequires = true/' /etc/zypp/zypp.conf

# Enable sshd
chkconfig sshd on

#======================================
# Sysconfig Update
#--------------------------------------
echo '** Update sysconfig entries...'
baseUpdateSysConfig /etc/sysconfig/keyboard KEYTABLE us.map.gz
baseUpdateSysConfig /etc/sysconfig/network/config FIREWALL no
baseUpdateSysConfig /etc/init.d/suse_studio_firstboot NETWORKMANAGER no
baseUpdateSysConfig /etc/sysconfig/SuSEfirewall2 FW_SERVICES_EXT_TCP 22\ 80\ 443
baseUpdateSysConfig /etc/sysconfig/console CONSOLE_FONT lat9w-16.psfu


#======================================
# Setting up overlay files 
#--------------------------------------
echo '** Setting up overlay files...'
xargs -L 256 chown nobody:nobody < /image/archive-manifest-XmRekcpT.txt
mkdir -p /tmp/r-packages/
mv /studio/overlay-tmp/files//tmp/r-packages//r-packages.zip /tmp/r-packages//r-packages.zip
chown nobody:nobody /tmp/r-packages//r-packages.zip
chmod 644 /tmp/r-packages//r-packages.zip
xargs -L 256 chown nobody:nobody < /image/archive-manifest-ZknchARg.txt
mkdir -p /tmp/db-dump/
mv /studio/overlay-tmp/files//tmp/db-dump//transmart.sql.zip /tmp/db-dump//transmart.sql.zip
chown nobody:nobody /tmp/db-dump//transmart.sql.zip
chmod 644 /tmp/db-dump//transmart.sql.zip
mkdir -p /srv/tomcat/webapps/
mv /studio/overlay-tmp/files//srv/tomcat/webapps//transmart.war /srv/tomcat/webapps//transmart.war
chown nobody:nobody /srv/tomcat/webapps//transmart.war
chmod 644 /srv/tomcat/webapps//transmart.war
mkdir -p /usr/share/tomcat/.grails/transmartConfig/
mv /studio/overlay-tmp/files//usr/share/tomcat/.grails/transmartConfig//Config.groovy /usr/share/tomcat/.grails/transmartConfig//Config.groovy
chown nobody:nobody /usr/share/tomcat/.grails/transmartConfig//Config.groovy
chmod 644 /usr/share/tomcat/.grails/transmartConfig//Config.groovy
mkdir -p /usr/share/tomcat/.grails/transmartConfig/
mv /studio/overlay-tmp/files//usr/share/tomcat/.grails/transmartConfig//DataSource.groovy /usr/share/tomcat/.grails/transmartConfig//DataSource.groovy
chown nobody:nobody /usr/share/tomcat/.grails/transmartConfig//DataSource.groovy
chmod 644 /usr/share/tomcat/.grails/transmartConfig//DataSource.groovy
mkdir -p /tmp/
mv /studio/overlay-tmp/files//tmp//install-r-packages.r /tmp//install-r-packages.r
chown nobody:nobody /tmp//install-r-packages.r
chmod 644 /tmp//install-r-packages.r
mkdir -p /usr/share/tomcat/.grails/transmartConfig/
mv /studio/overlay-tmp/files//usr/share/tomcat/.grails/transmartConfig//RModulesConfig.groovy /usr/share/tomcat/.grails/transmartConfig//RModulesConfig.groovy
chown nobody:nobody /usr/share/tomcat/.grails/transmartConfig//RModulesConfig.groovy
chmod 644 /usr/share/tomcat/.grails/transmartConfig//RModulesConfig.groovy
mkdir -p /etc/init.d/
mv /studio/overlay-tmp/files//etc/init.d//transmart-components /etc/init.d//transmart-components
chown root:root /etc/init.d//transmart-components
chmod 755 /etc/init.d//transmart-components
mkdir -p /etc/apache2/vhosts.d/
mv /studio/overlay-tmp/files//etc/apache2/vhosts.d//transmart-proxy.conf /etc/apache2/vhosts.d//transmart-proxy.conf
chown nobody:nobody /etc/apache2/vhosts.d//transmart-proxy.conf
chmod 644 /etc/apache2/vhosts.d//transmart-proxy.conf
chown root:root /studio/build-custom
chmod 755 /studio/build-custom
# run custom build_script after build
/studio/build-custom
chown root:root /studio/suse-studio-custom
chmod 755 /studio/suse-studio-custom
test -d /studio || mkdir /studio
cp /image/.profile /studio/profile
cp /image/config.xml /studio/config.xml
rm -rf /studio/overlay-tmp
true#======================================
# Configure PostgreSQL database
#--------------------------------------

DATADIR=~postgres/data

# Handy wrapper to call pg_ctl with the correct user.
pg_ctl () {
  CMD="/usr/bin/pg_ctl $@"
  su - postgres -c "$CMD"
}

# Helper function to execute the given sql file.
execute_sql_file() {
  su postgres -c "psql -q < $1 2>&1"
}

# Initialize PostgreSQL
echo "## Initializing PostgreSQL databases and tables..."
install -d -o postgres -g postgres -m 700 ${DATADIR} && su - postgres -c \
  "/usr/bin/initdb --locale=$LANG --auth='ident' $DATADIR &> initlog"

# Start PostgreSQL without networking
echo "## Starting PostgreSQL..."
pg_ctl start -s -w -D $DATADIR

# Load PostgreSQL data dump, if it exists
pgsql_dump=/tmp/pgsql_dump.sql
if [ -f "$pgsql_dump" ]; then
  echo "## Loading PostgreSQL data dump..."
  execute_sql_file "$pgsql_dump"
else
  echo "## No PostgreSQL data dump found, skipping"
fi

# Load PostgreSQL users and permissions, if setup file exists
pgsql_perms=/tmp/pgsql_config.sql
if [ -f "$pgsql_perms" ]; then
  echo "## Loading PostgreSQL users and perms..."
  execute_sql_file "$pgsql_perms"

  # update config file to allow md5 login
  sed -i "s/^\(host .*\) ident/\1 md5/" /var/lib/pgsql/data/pg_hba.conf

else
  echo "## No PostgreSQL user/perms config found, skipping"
fi

# Auto-start PostgreSQL
echo "## Configuring PostgreSQL to auto-start on boot..."
chkconfig postgresql on

# Stop PostgreSQL service (for uncontained builds)
echo "## Stopping PostgreSQL..."
pg_ctl stop -s -D $DATADIR -m fast

# Clean up temp files (for uncontained builds)
rm -f "$pgsql_perms" "$pgsql_dump"

echo "## PostgreSQL configuration complete"

#======================================
# SSL Certificates Configuration
#--------------------------------------
echo '** Rehashing SSL Certificates...'
c_rehash
