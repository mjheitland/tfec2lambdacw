#!/bin/bash
yum install httpd -y
echo "Host ${host_name}: ${message} " >> /var/www/html/index.html
service httpd start
chkconfig httpd on
