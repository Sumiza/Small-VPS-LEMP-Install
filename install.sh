#!/bin/sh
clear
echo "Please select which install:
1. Initial install
2. Adding another website
3. Apply letsencrypt to already installed site
4. Set up new MYSQL Database"
read -r RSP1
if [ "$RSP1" = "1" ]; then
        echo "Install Settings:"
        echo "1. Low memory VPS (tested 128mb ram)"
        echo "2. Default php-fmp and mariadb settings"
        read -r RSP2
        echo "Pick a password to secure MYSQL:"
        read -r -s RSPMYSQLROOTPASS
fi
if [ "$RSP1" = "1" ] || [ "$RSP1" = "2" ]; then
        echo "What is the fully qualified domain name (mytestdomain.com) dont put the www.:"
        read -r DOMAINNAMEFQDN
        echo "Do you want wordpress installed (y/n)?"
        read -r RSPWP
        
fi
if [ "$RSP1" = "1" ] || [ "$RSP1" = "2" ] || [ "$RSP1" = "4" ]; then
        echo "Want to set up a MYSQL Database now? (y/n)" 
        read -r RSPMYSQL
        if [ "$RSPMYSQLROOTPASS" = "" ]; then
                echo "MYSQL Password: " 
                read -s -r rootpasswd
        else
                rootpasswd=$RSPMYSQLROOTPASS
        fi
        echo "Database name you would like to create, something like (domainname) no special charecters:"
        read -r DBNAME
        echo "Name of user for $DBNAME:"
        read -r DBUSER
        echo "Password for user $DBUSER:"
        read -r DBPASS
fi
if [ "$RSP1" = "1" ] || [ "$RSP1" = "2" ] || [ "$RSP1" = "3" ]; then
        echo "Want to set up letsencrypt now? (y/n) only put y if you have your dns set up already or it will fail, this can be run at a later time." 
        read -r RSPLETSENCRYPT
fi
clear
echo "The install and setup will take a few minutes,"
sleep 5
#------------------ Questions DONE

if [ "$RSP1" = "1" ]; then
        #---- yum can crash if these are all combined
        yum update -y
        yum install -y epel-release
        yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
        yum -y install yum-utils
        yum-config-manager --enable remi-php74
        yum update -y
        yum install -y nginx
        yum install -y htop
        yum install -y cronie
        yum install -y certbot
        yum install -y python2-certbot-nginx
        yum install -y mariadb-server
        yum install -y php
        yum install -y php-common
        yum install -y php-mysql
        yum install -y php-gd
        yum install -y php-xml
        yum install -y php-mbstring
        yum install -y php-mcrypt
        yum install -y php-xmlrpc
        yum install -y unzip
        yum install -y php-fpm
        yum install -y php-pecl-zip
        yum install -y logrotate
        systemctl enable crond
        systemctl enable php-fpm
        systemctl enable mariadb
        systemctl enable nginx
        rm /etc/nginx/nginx.conf
        wget https://raw.githubusercontent.com/Sumiza/Small-VPS-LEMP-Install/master/nginx.conf -O /etc/nginx/nginx.conf
        sed -i '/listen = 127.0.0.1:9000/c\listen = /var/run/php-fpm/php-fpm.sock' /etc/php-fpm.d/www.conf
        sed -i '/listen.owner = /c\listen.owner = nginx' /etc/php-fpm.d/www.conf
        sed -i '/listen.group = /c\listen.group = nginx' /etc/php-fpm.d/www.conf
        sed -i '/user = apache/c\user = nginx' /etc/php-fpm.d/www.conf
        sed -i '/group = apache/c\group = nginx' /etc/php-fpm.d/www.conf
        #------Standard install
        
                if [ "$RSP2" = "1" ]; then
                sed -i '/pm = /c\pm = ondemand' /etc/php-fpm.d/www.conf
                sed -i '/pm.max_children = /c\pm.max_children = 1' /etc/php-fpm.d/www.conf
                sed -i '/pm.process_idle_timeout = /c\pm.process_idle_timeout = 10s' /etc/php-fpm.d/www.conf
                sed -i '/pm.max_requests = /c\pm.max_requests = 0' /etc/php-fpm.d/www.conf
                rm /etc/my.cnf
                wget https://raw.githubusercontent.com/Sumiza/Small-VPS-LEMP-Install/master/my.conf -O /etc/my.cnf
                fi
                #------ Low memory settings
        
        systemctl restart mariadb
        /usr/bin/mysql_secure_installation
        mysql -e "SET PASSWORD FOR root@localhost = PASSWORD('$RSPMYSQLROOTPASS');FLUSH PRIVILEGES;" 
        printf "$RSPMYSQLROOTPASS \n n\n Y\n Y\n Y\n Y\n Y\n" | mysql_secure_installation
fi
#----- Initial install done -----------

if [ "$RSP1" = "1" ] || [ "$RSP1" = "2" ]; then
        mkdir /usr/share/nginx/html/"$DOMAINNAMEFQDN"
        chmod 755 /usr/share/nginx/html/"$DOMAINNAMEFQDN"
        chown -R nginx:nginx /usr/share/nginx/html/"$DOMAINNAMEFQDN"
        cp /usr/share/nginx/html/index.html /usr/share/nginx/html/"$DOMAINNAMEFQDN"/index.html
        wget https://raw.githubusercontent.com/Sumiza/Small-VPS-LEMP-Install/master/BlankNginx.conf -O /etc/nginx/conf.d/"$DOMAINNAMEFQDN".conf
        sed -i "s/WEBSITENAME/$DOMAINNAMEFQDN/g" /etc/nginx/conf.d/"$DOMAINNAMEFQDN".conf
        systemctl restart nginx
        #------ files for website installed
        
        if [ "$RSPWP" = "y" ]; then
                wget http://wordpress.org/latest.tar.gz -O /usr/share/nginx/html/"$DOMAINNAMEFQDN"/latest.tar.gz
                tar -xzvf /usr/share/nginx/html/"$DOMAINNAMEFQDN"/latest.tar.gz -C /usr/share/nginx/html/"$DOMAINNAMEFQDN"/
                rm /usr/share/nginx/html/"$DOMAINNAMEFQDN"/latest.tar.gz
                mv /usr/share/nginx/html/"$DOMAINNAMEFQDN"/wordpress/* /usr/share/nginx/html/"$DOMAINNAMEFQDN"/
                rmdir /usr/share/nginx/html/"$DOMAINNAMEFQDN"/wordpress/
                chown -R nginx:nginx /usr/share/nginx/html/"$DOMAINNAMEFQDN"/
                find /usr/share/nginx/html/"$DOMAINNAMEFQDN"/ -type d -exec chmod 775 {} \;
                find /usr/share/nginx/html/"$DOMAINNAMEFQDN"/ -type f -exec chmod 664 {} \;
        fi
        #------ Wordpress installed
fi

if [ "$RSP1" = "1" ] || [ "$RSP1" = "2" ] || [ "$RSP1" = "4" ]; then

        if [ "$RSPMYSQL" = "y" ]; then
                mysql -uroot -p"$rootpasswd" -e "create database $DBNAME;"
                mysql -uroot -p"$rootpasswd" -e "grant all on $DBNAME.* to '$DBUSER' identified by '$DBPASS';"
        fi
fi
#----- Database setup done

if [ "$RSP1" = "1" ] || [ "$RSP1" = "2" ] || [ "$RSP1" = "3" ]; then
        if [ "$RSPLETSENCRYPT" = "y" ]; then
        clear
                echo "Do you want to provide your email to letsencrypt (y/n)"
                read -r RSP
                if [ "$RSP" = "y" ]; then
                        certbot --nginx
                else
                        certbot --nginx --register-unsafely-without-email
                fi
        	(crontab -l | grep '/usr/bin/certbot renew') || (crontab -l ; echo "0 3 */10 * * /usr/bin/certbot renew >/dev/null 2>&1") | crontab
        	echo "Adding cron job so that letsencrypt will auto renew"
        	systemctl restart nginx
        fi
fi
#-------- letsencrypt installed

if ! [ "$DBNAME" = "" ]; then
        echo "make sure to note down this information:"
        echo "----------------------------------"
        echo "MYSQL Database : $DBNAME"
        echo "MYSQL User : $DBUSER"
        echo "MYSQL Password: $DBPASS"
        echo "-----------------------------------"
fi
echo "----------DONE ENJOY-------------"
if [ "$RSP1" = "1" ]; then
        echo "Hit enter to reboot after initial install"
        read -r RSP
        reboot
fi
