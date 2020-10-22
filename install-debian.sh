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
        #---- yum can crash if these are all combined
        apt update && upgrade -y
        apt --reinstall -y install bsdutils
        echo exit 101 > /usr/sbin/policy-rc.d
        chmod +x /usr/sbin/policy-rc.d
        apt install -y apt-utils
        apt install -y dialog
        apt install -y nginx
        apt install -y htop
        apt install -y certbot
        apt install -y python3-certbot-nginx
        DEBIAN_FRONTEND=noninteractive apt install -y mariadb-server
        apt install -y php
        apt install -y php-common
        apt install -y php-mysql
        apt install -y php-gd
        apt install -y php-xml
        apt install -y php-mbstring
        apt install -y php-mcrypt
        apt install -y php-xmlrpc
        apt install -y unzip
        apt install -y php-fpm
        apt install -y php-pecl-zip
        apt install -y logrotate
        apt install -y ca-certificates
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
fi
#----- Initial install done -----------

if [ "$RSP1" = "1" ] || [ "$RSP1" = "2" ]; then
        echo "What is the fully qualified domain name (mytestdomain.com) dont put the www.:"
        read -r DOMAINNAMEFQDN
        mkdir /usr/share/nginx/html/"$DOMAINNAMEFQDN"
        chmod 755 /usr/share/nginx/html/"$DOMAINNAMEFQDN"
        chown -R nginx:nginx /usr/share/nginx/html/"$DOMAINNAMEFQDN"
        cp /usr/share/nginx/html/index.html /usr/share/nginx/html/"$DOMAINNAMEFQDN"/index.html
        wget https://raw.githubusercontent.com/Sumiza/Small-VPS-LEMP-Install/master/BlankNginx.conf -O /etc/nginx/conf.d/"$DOMAINNAMEFQDN".conf
        sed -i "s/WEBSITENAME/$DOMAINNAMEFQDN/g" /etc/nginx/conf.d/"$DOMAINNAMEFQDN".conf
        systemctl restart nginx
        #------ files for website installed
        
        echo "Do you want wordpress installed (y/n)?"
        read -r RSP
        if [ "$RSP" = "y" ]; then
                wget http://wordpress.org/latest.tar.gz -O /usr/share/nginx/html/"$DOMAINNAMEFQDN"/latest.tar.gz
                tar -xzvf /usr/share/nginx/html/"$DOMAINNAMEFQDN"/latest.tar.gz -C /usr/share/nginx/html/"$DOMAINNAMEFQDN"/
                rm /usr/share/nginx/html/"$DOMAINNAMEFQDN"/latest.tar.gz
                mv /usr/share/nginx/html/"$DOMAINNAMEFQDN"/wordpress/* /usr/share/nginx/html/"$DOMAINNAMEFQDN"/
                rmdir /usr/share/nginx/html/"$DOMAINNAMEFQDN"/wordpress/
                chown -R nginx:nginx /usr/share/nginx/html/"$DOMAINNAMEFQDN"/
                find /usr/share/nginx/html/"$DOMAINNAMEFQDN"/ -type d -exec chmod 775 {} \;
                find /usr/share/nginx/html/"$DOMAINNAMEFQDN"/ -type f -exec chmod 664 {} \;
                echo "----------------------------------------------"
                echo "If all went well wordpress has been installed with standard premissions"
        fi
        #------ Wordpress installed
fi

if [ "$RSP1" = "1" ] || [ "$RSP1" = "2" ] || [ "$RSP1" = "4" ]; then
        echo "Want to set up a MYSQL Database now? (y/n)" 
        read -r RSP
                if [ "$RSP" = "y" ]; then
                echo "Logging into mysql"
                echo "MYSQL root password: " 
                read -s -r rootpasswd
                echo "Database name you would like to create, something like (domainname) no special charecters:"
                read -r DBNAME
                echo "Name of user for $DBNAME:"
                read -r DBUSER
                echo "Password for user $DBUSER:"
                read -r DBPASS
                mysql -uroot -p"$rootpasswd" -e "create database $DBNAME;"
                mysql -uroot -p"$rootpasswd" -e "grant all on $DBNAME.* to '$DBUSER' identified by '$DBPASS';"
                echo "If no error the database was created successfully" 
        fi
fi
#----- Database setup done

if [ "$RSP1" = "1" ] || [ "$RSP1" = "2" ] || [ "$RSP1" = "3" ]; then
        echo "Want to set up letsencrypt now? (y/n) only put y if you have your dns set up already or it will fail, this can be run at a later time." 
        read -r RSP
        if [ "$RSP" = "y" ]; then
                firewall-cmd --permanent --add-service=https
                firewall-cmd --reload
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
