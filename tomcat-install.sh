#!/bin/bash
: '
This script is used to install Tomcat 10 on a new installation of RHEL 9. 
It utilized accompaning files (cluster-config & context-resource-config) to add the 
necessary configurations to utilize session replication and JNDI connections.
 '

#Credentials - to be configured as desired before running script.

echo -n "Enter username :"
read -r username

echo -n "Enter password :"
read -r password

echo -n "Enter server name :"
read -r server_name

username=\"${username}\"
password=\"${password}\"
server_name=\"${server_name}\"
#ip_address=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
home_dir=$(pwd)
#Verify RHEL Subscription

subscription-manager register
subscription-manager auto-attach
subscription-manager attach

#Buildout of Tomcat Server

sudo dnf update -y
sudo dnf install java -y
sudo dnf -y install wget

wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.69/bin/apache-tomcat-9.0.69.tar.gz

tar -xvf apache-tomcat-9*.tar.gz

sudo mv apache-tomcat-9.0.69 /usr/local/tomcat

sudo groupadd tomcat

sudo useradd -d /usr/local/tomcat -r -s /bin/false -g tomcat tomcat

sudo chown -R tomcat:tomcat /usr/local/tomcat/

echo "export CATALINA_HOME="/usr/local/tomcat"" >> ~/.bashrc

source ~/.bashrc

mv cluster-config /usr/local/tomcat/conf

#Set up JNDI Connector 
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.31.tar.gz
tar -xvf mysql-connector-j-8.0.31.tar.gz
mv mysql-connector-j-8.0.31/mysql* /usr/local/tomcat/lib

cd /usr/local/tomcat/conf

# Add manager username and password

sed -i '/tomcat-users>/i<role rolename="manager-gui"/>\n<role rolename="admin-gui"/>\n<user username=<username> password=<password> roles="manager-gui,admin-gui"/>' tomcat-users.xml

# Add Cluster configuration and server name to server.xml Requires Cluster configuration script in seperate file. In this case >cluster-config<

sed -i '/<Engine name="Catalina" defaultHost="localhost">/r cluster-config' server.xml
sed -i 's/Engine name="Catalina" defaultHost="localhost"/& jvmRoute=<server_name>/' server.xml

#Enter credential variables into config files.

sed -i "s/<username>/$username/" tomcat-users.xml
sed -i "s/<password>/$password/" tomcat-users.xml
sed -i "s/<server_name>/$server_name/" server.xml

#Next two commands allow all users access to the Manager App and Host Manager. Omit if this access is not required or desired.

sed -i 's/:0:0:1/&|.*/' /usr/local/tomcat/webapps/manager/META-INF/context.xml

sed -i 's/:0:0:1/&|.*/' /usr/local/tomcat/webapps/host-manager/META-INF/context.xml

#Open ports on firewall for remote access to server.

sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --add-port=4000-4100/tcp --permanent
sudo firewall-cmd --add-port=45564/udp --permanent
sudo firewall-cmd --reload

hostnamectl set-hostname $server_name

#Add DB Resources to Tomcat context.xml from the context-resource-config file
mv $home_dir/context-resource-config /usr/local/tomcat/conf/
awk 'FNR==NR{n=n $0 ORS; next} /<\/Context>/{$0=n $0} 1' context-resource-config context.xml > context_temp
mv /usr/local/tomcat/conf/context_temp context.xml

#This line just enables the 'example' web to demostrate the session replication between the loadbalanced TC servers.
sed -i '/<\/web-app>/i<distributable/>' /usr/local/tomcat/webapps/examples/WEB-INF/web.xml

#Push the JNDIDemo folder to the webapps folder to demonstrate the DB Connetions and session rep for this web app.
mv $home_dir/JNDIDemo/ /usr/local/tomcat/webapps/

#Start Tomcat Server

/usr/local/tomcat/bin/startup.sh