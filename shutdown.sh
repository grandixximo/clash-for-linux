#!/bin/bash

# Stop the Clash service
PID_NUM=`ps -ef | grep [c]lash-linux-a | wc -l`
PID=`ps -ef | grep [c]lash-linux-a | awk '{print $2}'`
if [ $PID_NUM -ne 0 ]; then
	kill -9 $PID
	# ps -ef | grep [c]lash-linux-a | awk '{print $2}' | xargs kill -9
fi

# Clear environment variables
> /etc/profile.d/clash.sh

echo -e "\nService stopped successfully. Please run the following command to disable the system proxy: proxy_off\n"
