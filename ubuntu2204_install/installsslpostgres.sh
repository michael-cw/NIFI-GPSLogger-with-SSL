#!/bin/bash
#
#
#                       PostgreSQL Installation Script
#
# This script will install PostgreSQL with SSL (self signed certificate) 
#
#                          IMPORTANT: USE AT YOUR OWN RISK! 
# 
# The script was developed and tested on Ubuntu 22.04 LTS and for the available PostgreSQL version and worked fine. Feel free to 
# adjust it and port it to other systems as you wish, but always at your own risk. Enjoy! 


# Prompt user for inputs
read -p "Enter PostgreSQL database name: " PG_DBNAME
read -p "Enter PostgreSQL table name for GPSLogger: " PG_TABLE
read -p "Enter PostgreSQL username: " PG_USERNAME
read -s -p "Enter PostgreSQL password: " PG_PASSWORD
echo
# read -s -p "Enter PostgreSQL SSL certificate and key password: " SSL_PASSWORD
echo


# Install PostgreSQL and OpenSSL
echo "Installing PostgreSQL and OpenSSL..."
sudo apt update
sudo apt install -y postgresql postgresql-contrib openssl

# Start PostgreSQL
echo "Starting PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Set up PostgreSQL user and database
echo "Setting up user and database..."
sudo -u postgres psql -c "CREATE USER $PG_USERNAME WITH PASSWORD '$PG_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE $PG_DBNAME WITH OWNER $PG_USERNAME;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $PG_DBNAME TO $PG_USERNAME;"

# Set up table schema
echo "Setting up table schema..."
sudo -u postgres psql $PG_DBNAME << EOF
CREATE TABLE $PG_TABLE (
    lat DOUBLE PRECISION,
    long DOUBLE PRECISION,
    acc DOUBLE PRECISION,
    batt DOUBLE PRECISION,
    time TEXT,
    id TEXT,
    aid TEXT
);
GRANT ALL PRIVILEGES ON TABLE $PG_TABLE TO $PG_USERNAME;
EOF

# Generate SSL certificates
echo "Generating SSL certificates..."
sudo openssl req -new -x509 -days 365 -nodes -text -out /etc/ssl/certs/server.crt -keyout /etc/ssl/private/server.key -subj "/CN=pgserver"
sudo chown postgres:postgres /etc/ssl/private/server.key
sudo chmod 600 /etc/ssl/private/server.key

# Enable secure remote connections and SSL
echo "Configuring secure remote connections..."
echo "hostssl all $PG_USERNAME 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

# Modify PostgreSQL configuration for SSL
sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
echo "ssl = on" | sudo tee -a /etc/postgresql/*/main/postgresql.conf

# Restart PostgreSQL for changes to take effect
echo "Restarting PostgreSQL..."
sudo systemctl restart postgresql

echo "PostgreSQL setup complete!"
