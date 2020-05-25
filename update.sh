#!/bin/sh
rm /etc/nginx/nginx.conf
wget --no-check-certificate https://raw.githubusercontent.com/Sumiza/Small-VPS-LEMP-Install/master/nginx.conf -O /etc/nginx/nginx.conf
sed -i '/listen = 127.0.0.1:9000/c\listen = /var/run/php-fpm/php-fpm.sock' /etc/php-fpm.d/www.conf
sed -i '/listen.owner = /c\listen.owner = nginx' /etc/php-fpm.d/www.conf
sed -i '/listen.group = /c\listen.group = nginx' /etc/php-fpm.d/www.conf
sed -i '/user = apache/c\user = nginx' /etc/php-fpm.d/www.conf
sed -i '/group = apache/c\group = nginx' /etc/php-fpm.d/www.conf
sed -i '/pm = /c\pm = ondemand' /etc/php-fpm.d/www.conf
sed -i '/pm.max_children = /c\pm.max_children = 1' /etc/php-fpm.d/www.conf
sed -i '/pm.start_servers = /c\;pm.start_servers = 2' /etc/php-fpm.d/www.conf
sed -i '/pm.min_spare_servers = /c\;pm.min_spare_servers = 1' /etc/php-fpm.d/www.conf
sed -i '/pm.max_spare_servers = /c\;pm.max_spare_servers = 3' /etc/php-fpm.d/www.conf
sed -i '/pm.process_idle_timeout = /c\pm.process_idle_timeout = 10s' /etc/php-fpm.d/www.conf
sed -i '/pm.max_requests = /c\pm.max_requests = 0' /etc/php-fpm.d/www.conf
rm /etc/my.cnf
wget --no-check-certificate https://raw.githubusercontent.com/Sumiza/Small-VPS-LEMP-Install/master/my.conf -O /etc/my.cnf
echo "What is the fully qualified domain name (MyTestDomain.com) dont put the www."
read -r DOMAINNAMEFQDN
mkdir /usr/share/nginx/html/"$DOMAINNAMEFQDN"
chmod 755 /usr/share/nginx/html/"$DOMAINNAMEFQDN"
chown -R nginx:nginx /usr/share/nginx/html/"$DOMAINNAMEFQDN"
wget --no-check-certificate https://raw.githubusercontent.com/Sumiza/Small-VPS-LEMP-Install/master/BlankNginx.conf -O /etc/nginx/conf.d/"$DOMAINNAMEFQDN".conf
sed -i "s/WEBSITENAME/$DOMAINNAMEFQDN/g" /etc/nginx/conf.d/"$DOMAINNAMEFQDN".conf
systemctl restart nginx && systemctl restart mariadb
echo "Want to set up letsencrypt now? (y/n) only say yes if you have your dns set up already or it will fail" 
read -r RSP
if [ "$RSP" = "y" ]; then
	certbot --nginx --register-unsafely-without-email
fi
/usr/bin/mysql_secure_installation
echo "Want to set up a MYSQL Database now? (y/n)" 
read -r RSP
if [ "$RSP" = "y" ]; then
echo "Logging into mysql"
echo "MYSQL Password: " 
read -r rootpasswd
echo "Database name you would like to create, something like (domainname) no special charecters"
read -r DBNAME
echo "Name of user for this database"
read -r DBUSER
echo "Password for user $DBNAME"
read -r DBPASS
mysql -uroot -p"$rootpasswd" -e "create database $DBNAME;"
mysql -uroot -p"$rootpasswd" -e "grant all on $DBNAME.* to '$DBUSER' identified by '$DBPASS';"
fi
rm install.sh
echo "DONE DONE DONE DONE make sure to note down this information:
MYSQL Database : $DBNAME
MYSQL User : $DBUSER
MYSQL Password: $DBPASS
-----------------------------------
Hit enter to reboot"
read -r RSP
reboot