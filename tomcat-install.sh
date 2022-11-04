#This script is used to install Tomcat 10 on a new installation of RHEL 9.

sudo dnf update

sudo dnf install java

sudo dnf -y install wget

wget https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.1/bin/apache-tomcat-10.0.23.tar.gz

tar -xvf apache-tomcat-10*.tar.gz

sudo mv apache-tomcat-10.1.1 /usr/local/tomcat

sudo groupadd tomcat

sudo useradd -d /usr/local/tomcat -r -s /bin/false -g tomcat tomcat

sudo chown -R tomcat:tomcat /usr/local/tomcat/

echo "export CATALINA_HOME="/usr/local/tomcat"" >> ~/.bashrc

source ~/.bashrc

sed -i "\$i <role rolename="manager-gui"/>\n<role rolename="admin-gui"/>\n<user username="admin" password="Starfire69!" roles="manager-gui,admin-gui"/>" tomcat-users.xml

sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent

sudo firewall-cmd --reload
