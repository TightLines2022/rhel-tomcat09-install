#!/bin/bash
#This script is used to install Tomcat 10 on a new installation of RHEL 9.

subscription-manager register
subscription-manager auto-attach
subscription-manager attach

sudo dnf update -y

sudo dnf install java -y

sudo dnf -y install wget

wget https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.1/bin/apache-tomcat-10.1.1.tar.gz

tar -xvf apache-tomcat-10*.tar.gz

sudo mv apache-tomcat-10.1.1 /usr/local/tomcat

sudo groupadd tomcat

sudo useradd -d /usr/local/tomcat -r -s /bin/false -g tomcat tomcat

sudo chown -R tomcat:tomcat /usr/local/tomcat/

echo "export CATALINA_HOME="/usr/local/tomcat"" >> ~/.bashrc

source ~/.bashrc

mv cluster-config /usr/local/tomcat/conf

cd /usr/local/tomcat/conf

# Add manager username and password

sed -i '/tomcat-users>/i<role rolename="manager-gui"/>\n<role rolename="admin-gui"/>\n<user username="admin" password="Password" roles="manager-gui,admin-gui"/>' tomcat-users.xml

# Add Cluster configuration and server name to server.xml Requires Cluster configuration script in seperate file. In this case >cluster-config<

sed -i '/<Engine name="Catalina" defaultHost="localhost">/r cluster-config' server.xml
sed -i 's/Engine name="Catalina" defaultHost="localhost"/& jvmRoute="tomcat2"/' server.xml

#Next two commands all users access to the Manager App and Host Manager. Omit if this access is not required or desired.

sed -i 's/:0:0:1/&|.*/' /usr/local/tomcat/webapps/manager/META-INF/context.xml

sed -i 's/:0:0:1/&|.*/' /usr/local/tomcat/webapps/host-manager/META-INF/context.xml


sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent

sudo firewall-cmd --reload

/usr/local/tomcat/bin/startup.sh