#!/bin/bash
#
#
#                       Apache NIFI 1.23.2 Installation Script
#
# This script will install Apache NIFI with SSL (self signed certificate) and single user authentication
# It also generates a SSL certificate for a HTTPS webserver as it was developed to be used together with
# the GPSlogger app for Android, however i may also be useful for other use cases.
#
#                               Requirements/Settings
#
# - sudo user						- nifi ssl is named nifi-keystore.jks		- keystor pw will be used for trust store
# - nifi is moved to /opt/nifi		- webserver ssl is named keystore_san2.jks    and certificate pw
#
#                          IMPORTANT: USE AT YOUR OWN RISK! 
# 
# The script was developed and tested on Ubuntu 22.04 LTS and for said NIFI version and worked fine. Feel free to 
# adjust it and port it to other systems as you wish, but always at your own risk. Enjoy! 


# Prompt user for inputs
read -p "Enter keystore password: " KEYSTORE_PASSWORD
read -p "Enter server IP: " SERVER
read -p "Enter server port: " PORT
read -p "Enter system user: " SYSUSER
#read -p "Enter truststore password: " TRUSTSTORE_PASSWORD
read -p "Enter NiFi username: " NIFI_USERNAME
read -s -p "Enter NiFi password (min 12 characters, only letters numbers and _!): " NIFI_PASSWORD
echo

# check nifi password length-->exit if false
if [[ $NIFI_PASSWORD =~ ^[a-zA-Z0-9_]{12,}$ ]]
then
   echo
   echo NIFI Password accepted
else
   echo
   echo NIFI Password not accepted!
   echo Operation terminated
   echo Start again!
   exit 0
fi


# Install required packages
echo "Installing required packages..."
sudo apt update
sudo apt install -y openjdk-11-jdk wget unzip


# Download NiFi from the provided link
echo "Downloading NiFi..."
wget https://dlcdn.apache.org/nifi/1.23.2/nifi-1.23.2-bin.zip

# Unzip the downloaded file
echo "Unzipping NiFi..."
unzip nifi-1.23.2-bin.zip

# Move the extracted content to /opt/nifi
echo "Moving NiFi to /opt/nifi..."
sudo mv nifi-1.23.2 /opt/nifi

# Generate keystore and truststore for secure NIFI login
echo "Generating keystore and truststore..."
keytool -genkeypair -alias nifi-key -keyalg RSA -keysize 2048 -validity 365 -keystore /opt/nifi/lib/nifi-keystore.jks -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -dname "CN=nifi-server, OU=NiFi"
keytool -exportcert -alias nifi-key -file /opt/nifi/lib/nifi-cert.pem -keystore /opt/nifi/lib/nifi-keystore.jks -storepass $KEYSTORE_PASSWORD
keytool -importcert -trustcacerts -alias nifi-key -file /opt/nifi/lib/nifi-cert.pem -keystore /opt/nifi/lib/nifi-truststore.jks -storepass $KEYSTORE_PASSWORD -noprompt

# Update NiFi properties for HTTPS and user authentication
echo "Configuring NiFi for HTTPS and user authentication..."

# HTTPS configuration
sudo sed -i "s/nifi.web.http.host=.*/nifi.web.http.host=/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.web.http.port=8080/nifi.web.http.port=/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.web.https.host=.*/nifi.web.https.host=0.0.0.0/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.web.https.port=.*/nifi.web.https.port=$PORT/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.security.keystore=.*/nifi.security.keystore=\/opt\/nifi\/lib\/nifi-keystore.jks/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.security.keystoreType=.*/nifi.security.keystoreType=JKS/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.security.keystorePasswd=.*/nifi.security.keystorePasswd=$KEYSTORE_PASSWORD/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.security.keyPasswd=.*/nifi.security.keyPasswd=$KEYSTORE_PASSWORD/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.security.truststore=.*/nifi.security.truststore=\/opt\/nifi\/lib\/nifi-truststore.jks/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.security.truststoreType=.*/nifi.security.truststoreType=JKS/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.security.truststorePasswd=.*/nifi.security.truststorePasswd=$KEYSTORE_PASSWORD/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.security.allow.anonymous.authentication=.*/nifi.security.allow.anonymous.authentication=false/" /opt/nifi/conf/nifi.properties
sudo sed -i "s/nifi.web.proxy.host=.*/nifi.web.proxy.host=$SERVER:$PORT/" /opt/nifi/conf/nifi.properties


# Create login-identity-providers.xml for file-based authentication
cat <<EOL | sudo tee /opt/nifi/conf/login-identity-providers.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<loginIdentityProviders>
    	<provider>
   	<identifier>single-user-provider</identifier>
   	<class>org.apache.nifi.authentication.single.user.SingleUserLoginIdentityProvider</class>
   	<property name="Username"/>
   	<property name="Password"/>
	</provider>
</loginIdentityProviders>
EOL

## Set JAVA_HOME for NiFi to use Java 11
JAVA_PATH="/usr/lib/jvm/java-11-openjdk-amd64/"
echo "Setting JAVA_HOME to $JAVA_PATH permanently..."
echo "export JAVA_HOME=$JAVA_PATH" | sudo tee -a /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

#set password
/opt/nifi/bin/nifi.sh set-single-user-credentials $NIFI_USERNAME $NIFI_PASSWORD

#create SSL for inbound connection from gpslogger app
sudo keytool -genkey -alias nifi-server-gps -keyalg RSA -keypass $KEYSTORE_PASSWORD -storepass $KEYSTORE_PASSWORD -keystore /opt/nifi/lib/keystore_san2.jks -ext "SAN=IP:$SERVER" -dname "CN=$SERVER"
sudo chown $SYSUSER:$SYSUSER /opt/nifi/lib/keystore_san2.jks

#download PG driver for NIFI
wget -P /opt/nifi/lib https://jdbc.postgresql.org/download/postgresql-42.6.0.jar
#sudo chown $SYSUSER:$SYSUSER /opt/nifi/lib/postgresql-42.6.0.jar

# Start NiFi
echo "Starting NiFi..."
/opt/nifi/bin/nifi.sh start

echo "NiFi setup complete! Access via https://$SERVER:$PORT/nifi"
