#!/bin/bash

# Complete this script to deploy external-service and counter-service in two separate containers
# You will be using the conductor tool that you completed in task 3.

# Creating link to the tool within this directory
ln -s ../task3/conductor.sh conductor.sh
ln -s ../task3/setup.sh setup.sh

# use the above scripts to accomplish the following actions -

# Logical actions to do:
# 1. Build images for the containers
sudo ./conductor.sh build cs csfile
sudo ./conductor.sh build es esfile

# 2. Run two containers say es-cont and cs-cont which should run in background. Tip: to keep the container running
#    in background you should use a init program that will not interact with the terminal and will not
#    exit. e.g. sleep infinity, tail -f /dev/null
sudo ./conductor.sh run es es-cont -- sleep infinity &
sudo ./conductor.sh run cs cs-cont -- sleep infinity &
sleep 1

# 3. Configure network such that:
#    3.a: es-cont is connected to the internet and es-cont has its port 8080 forwarded to port 3000 of the host
sudo ./conductor.sh addnetwork --internet --expose 8080-3000 es-cont


#    3.b: cs-cont is connected to the internet and does not have any port exposed
sudo ./conductor.sh addnetwork --internet cs-cont


#    3.c: peer network is setup between es-cont and cs-cont
sudo ./conductor.sh peer cs-cont es-cont


# 5. Get ip address of cs-cont. You should use script to get the ip address. 
#    You can use ip interface configuration within the host to get ip address of cs-cont or you can 
#    exec any command within cs-cont to get it's ip address
cspid=$(ps -ef | grep "unshare" | grep cs-cont/merged | grep -v grep | awk '{print $2}')
csIP=$(sudo nsenter -n -t $cspid ip addr show | grep -w inet | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1)



# 6. Within cs-cont launch the counter service using exec [path to counter-service directory within cs-cont]/run.sh
sudo ./conductor.sh exec cs-cont "./counter-service/counter-service 8080 1" &


# 7. Within es-cont launch the external service using exec [path to external-service directory within es-cont]/run.sh
sudo ./conductor.sh exec es-cont "python3 external-service/app.py http://$csIP:8080/"


# 8. Within your host system open/curl the url: http://localhost:3000 to verify output of the service
# 9. On any system which can ping the host system open/curl the url: `http://<host-ip>:3000` to verify
#    output of the service
