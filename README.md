# nifi-GPSLoger-with-SSL
Creates a NIFI https server, which ingests data from GPSLogger for Android application over SSL and writes to a PostgreSQL database.

## GPS Logger for Android
Get it here: https://gpslogger.app/

## Nifi
Get it here: https://nifi.apache.org/download.html and after installation, import the template.

## Create self-signed certificat
sudo ./keytool -genkey -alias [server-alias] -keyalg RSA \
   -keypass [yourpassword] -storepass [yourpassword] -keystore keystore.jks \
   -ext "SAN=IP:192.168.100.254" \
   -dname "CN=192.168.100.254"

The URLs provide above must matach the URLs you are using, so you have to replace it.
   
after hitting enter you will then need to provide additional user information for the certificate. Important is also that you provide the SAME entry which you have under -dname in the first name/last name question which appears immedeatly after running this command.

Copy the keystore.jks file to a folder where nifi can read it, and update the SSLcontext service with your path and your credentials. That shold be id.

Happy logging!
