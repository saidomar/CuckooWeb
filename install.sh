#!/bin/bash

# Variables

if [ "$(whoami)" != "root" ];then
	echo YOU HAVE TO BE ROOT TO RUN THIS SCRIPT
	exit 1;
fi

# Variables

echo -n 'Enter the path of cuckoo directory (e.g. /root/cuckoo):'
read CUCKOO_ROOT
if [ ! -e $CUCKOO_ROOT/cuckoo.py ];then
	echo $CUCKOO_ROOT is a wrong path
	exit 2;
fi

echo -n 'Enter MySQL cuckoo username:'
read MYSQL_USER
echo -n 'Enter MySQL cuckoo password:'
read MYSQL_PASS
echo -n 'Enter MySQL cuckoo database:'
read MYSQL_DB
res=$(mysql -u $MYSQL_USER --password=$MYSQL_PASS $MYSQL_DB -e exit 2>&1)

if [ -n "$res" ];then
        echo Please check credentials
        exit 2;
fi

APACHE_ROOT=/var/www/cuckoo_web

DIR=$(pwd)

# Dependencies

apt-get update 1>/dev/null 2>&1
apt-get -y install autoconf nano git wget automake libtool re2c flex bison \
		   apache2 php5 php5-mysql php5-dev 1>/dev/null 2>&1

# ssdeep php libraries

wget http://pecl.php.net/get/ssdeep-1.0.2.tgz
tar xzf ssdeep-1.0.2.tgz
cd ssdeep-1.0.2
phpize5 1>/dev/null 2>&1
./configure 1>/dev/null 2>&1
make 1>/dev/null 2>&1
res=$(make install 1>/dev/null 2>&1)
if [ -n "$res" ];then
	echo ERROR: Installing ssdeep libraries.
	exit 3
fi
cd .. && rm -r ssdeep-1.0.2 && rm ssdeep-1.0.2.tgz

echo
echo
echo FILE /etc/php5/apache2/php.ini
echo Copy following lines at the section \"Dynamic extensions\"
echo
echo extension=ssdeep.so
echo extension=mysql.so
echo
echo Press ENTER to continue
read

nano /etc/php5/apache2/php.ini

/etc/init.d/apache2 restart 1>/dev/null 2>&1

git clone https://github.com/spectoor/CuckooWeb 1>/dev/null 2>&1
if [ ! -d CuckooWeb ];then
	echo ERROR: Downloading CuckooWeb repo.
	exit 3
fi
cd CuckooWeb
cp -R cuckoo_web $APACHE_ROOT
ln -s $CUCKOO_ROOT/storage/analyses analyses
sed -i "s/mysql_user/$MYSQL_USER/g" $APACHE_ROOT/index.php
sed -i "s/mysql_user/$MYSQL_USER/g" $APACHE_ROOT/submit.php
sed -i "s/mysql_pass/$MYSQL_PASS/g" $APACHE_ROOT/index.php
sed -i "s/mysql_pass/$MYSQL_PASS/g" $APACHE_ROOT/submit.php
sed -i "s/database_name/$MYSQL_DB/g" $APACHE_ROOT/index.php
sed -i "s/database_name/$MYSQL_DB/g" $APACHE_ROOT/submit.php
chown -R www-data $APACHE_ROOT
cd .. && rm -r CuckooWeb

cd $DIR
exit 0
