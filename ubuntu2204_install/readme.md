Some helper files for the installation of nifi and postgres on ubuntu 22.04
includes ssl for both installations and single user authentication for nifi.

USE AT YOUR OWN RISK! even when using the scripts you should now what you are doing,
in other words this is only for experienced users. Also note that the the security features 
included in the scripts are very basic, so for production enviroyments you may want to adjust
them.

Steps for installation (assuming you start on a fresh Ubuntu system)

1. As root create user with *adduser* this will be your systemuser in the installation of NIFI
2. Ad user to sudo group with usermod -aG sudo [systemuser]
3. switch to this [systemuser]
4. got to the [systemuser] homdir
5. make the scripts executable with sudo chmod +x /install...
6. run the scripts and provide the prompts 
