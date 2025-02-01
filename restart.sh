#!/bin/bash

# Custom action functions for generic action handling
success() {
  echo -en "\\033[60G[\\033[1;32m  OK  \\033[0;39m]\r"
  return 0
}

failure() {
  local rc=$?
  echo -en "\\033[60G[\\033[1;31mFAILED\\033[0;39m]\r"
  [ -x /bin/plymouth ] && /bin/plymouth --details
  return $rc
}

action() {
  local MESSAGE rc

  MESSAGE=$1
  echo -n "$MESSAGE "
  shift
  "$@" && success $"$MESSAGE" || failure $"$MESSAGE"
  rc=$?
  echo
  return $rc
}

# Function to check if a command executed successfully
if_success() {
  local status=$3
  if [ $status -eq 0 ]; then
    action "$1" /bin/true
  else
    action "$2" /bin/false
    exit 1
  fi
}

# Define path variables
Server_Dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
Conf_Dir="$Server_Dir/conf"
Log_Dir="$Server_Dir/logs"

## Stop the Clash service
SuccessMessage="Service stopped successfully!"
FailureMessage="Failed to stop the service!"
# Find and terminate the process
PID_COUNT=$(ps -ef | grep [c]lash-linux-a | wc -l)
PID=$(ps -ef | grep [c]lash-linux-a | awk '{print $2}')
if [ $PID_COUNT -ne 0 ]; then
  kill -9 $PID
  ReturnStatus=$?
fi
if_success "$SuccessMessage" "$FailureMessage" $ReturnStatus

sleep 3

## Determine CPU architecture
if /bin/arch &>/dev/null; then
  CpuArch=$(/bin/arch)
elif /usr/bin/arch &>/dev/null; then
  CpuArch=$(/usr/bin/arch)
elif /bin/uname -m &>/dev/null; then
  CpuArch=$(/bin/uname -m)
else
  echo -e "\033[31m\n[ERROR] Failed to obtain CPU architecture!\033[0m"
  exit 1
fi

## Restart the Clash service
StartSuccess="Service started successfully!"
StartFailure="Failed to start the service!"
if [[ $CpuArch =~ "x86_64" ]]; then
  nohup $Server_Dir/bin/clash-linux-amd64 -d $Conf_Dir &> $Log_Dir/clash.log &
  ReturnStatus=$?
  if_success "$StartSuccess" "$StartFailure" $ReturnStatus
elif [[ $CpuArch =~ "aarch64" || $CpuArch =~ "arm64" ]]; then
  nohup $Server_Dir/bin/clash-linux-arm64 -d $Conf_Dir &> $Log_Dir/clash.log &
  ReturnStatus=$?
  if_success "$StartSuccess" "$StartFailure" $ReturnStatus
elif [[ $CpuArch =~ "armv7" ]]; then
  nohup $Server_Dir/bin/clash-linux-armv7 -d $Conf_Dir &> $Log_Dir/clash.log &
  ReturnStatus=$?
  if_success "$StartSuccess" "$StartFailure" $ReturnStatus
else
  echo -e "\033[31m\n[ERROR] Unsupported CPU Architecture!\033[0m"
  exit 1
fi
