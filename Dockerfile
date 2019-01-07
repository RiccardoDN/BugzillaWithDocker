FROM ubuntu:18.04

MAINTAINER Riccardo Di Natale

# Update and install modules for bugzilla, Apache2
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -q -y tzdata git nano apache2 \
	mysql-server libappconfig-perl libdate-calc-perl libtemplate-perl \
	libmime-tools-perl build-essential libdatetime-timezone-perl libdatetime-perl \
	libemail-sender-perl libemail-mime-perl libdbi-perl libdbd-mysql-perl \
	libcgi-pm-perl libmath-random-isaac-perl libmath-random-isaac-xs-perl \
	libapache2-mod-perl2 libapache2-mod-perl2-dev libchart-perl libxml-perl \
	libxml-twig-perl perlmagick libgd-graph-perl libtemplate-plugin-gd-perl \
	libsoap-lite-perl libhtml-scrubber-perl libjson-rpc-perl \
	libdaemon-generic-perl libtheschwartz-perl libtest-taint-perl \
	libauthen-radius-perl libfile-slurp-perl libencode-detect-perl \
	libmodule-build-perl libnet-ldap-perl libauthen-sasl-perl perl-doc \
	libfile-mimeinfo-perl libhtml-formattext-withlinks-perl libgd-dev \
	libmysqlclient-dev lynx-common graphviz python-sphinx

WORKDIR /var/www/html

# Download bugzilla from git
RUN git clone --branch release-5.0-stable https://github.com/bugzilla/bugzilla bugzilla

# MYSQL CONFIGURATION
RUN service mysql start &&\
	DEBIAN_FRONTEND=noninteractive mysql -u root -p -e "GRANT ALL PRIVILEGES ON bugs.* TO bugs@localhost IDENTIFIED BY '<MYPASSWORD>'" &&\
	DEBIAN_FRONTEND=noninteractive mysql -u root -p -e "GRANT ALL PRIVILEGES ON bugs.* TO bugs IDENTIFIED BY '<MYPASSWORD>'"
# notes: to access mysql from outside bind-address parameter on line 44 was commented
COPY mysqld.cnf /etc/mysql/mysql.conf.d/mysql.cnf
COPY mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf

# APACHE CONFIGURATION
COPY bugzilla.conf /etc/apache2/sites-available
COPY apache2.conf /etc/apache2
RUN a2ensite bugzilla && a2enmod cgi headers expires && service apache2 restart


# BUGZILLA CHECK SETUP
COPY checksetup.pl bugzilla
# generates localconfig file and changes $webservergroup to www-data and add password ('mysqladminion') to $db_pass parameter
RUN perl bugzilla/checksetup.pl && \
	sed -i -e "s/'apache'/'www-data'/g" bugzilla/localconfig && sed -i -e "s/db_pass = ''/db_pass = 'mysqladminion'/g" bugzilla/localconfig
COPY checksetup_answers.txt bugzilla
RUN service mysql restart && perl /var/www/html/bugzilla/checksetup.pl /var/www/html/bugzilla/checksetup_answers.txt


## COMMANDS THAT HAVE TO BE RUN FROM CLI:
## changing privileges in order to stop/start mysql from terminal (kubernetes)
# chown -R mysql /var/lib/mysql && chgrp -R mysql /var/lib/mysql
# service mysql start
# service apache2 start
## launch test file (you have to be in the bugzilla folder), all tests should pass (ignore warnings)
# perl /var/www/html/bugzilla/testserver.pl http://localhost/bugzilla	


EXPOSE 3306
EXPOSE 80


CMD tail -f /dev/null
