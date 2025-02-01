#!/bin/bash

# Load system function library (Only for RHEL Linux)
# [ -f /etc/init.d/functions ] && source /etc/init.d/functions

#################### Script Initialization Tasks ####################

# Get the absolute path of the script's working directory
export Server_Dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# Load the .env variable file
source "$Server_Dir/.env"

# Add execute permissions to binary executables, scripts, etc.
chmod +x "$Server_Dir/bin/"*
chmod +x "$Server_Dir/scripts/"*
chmod +x "$Server_Dir/tools/subconverter/subconverter"

#################### Variable Settings ####################

Conf_Dir="$Server_Dir/conf"
Temp_Dir="$Server_Dir/temp"
Log_Dir="$Server_Dir/logs"

# Assign the value of CLASH_URL to URL and ensure CLASH_URL is not empty
URL=${CLASH_URL:?Error: CLASH_URL variable is not set or empty}

# Debug: Print the Clash subscription URL
echo -e "\n[DEBUG] Clash Subscription URL: ${URL}\n"

# Get the CLASH_SECRET value, or generate a random one if not set
Secret=${CLASH_SECRET:-$(openssl rand -hex 32)}

#################### Function Definitions ####################

# Custom action function to provide common action feedback
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
    local STRING rc

    STRING=$1
    echo -n "$STRING "
    shift
    "$@" && success "$STRING" || failure "$STRING"
    rc=$?
    echo
    return $rc
}

# Function to check if a command executed successfully
if_success() {
    local ReturnStatus=$3
    if [ $ReturnStatus -eq 0 ]; then
        action "$1" /bin/true
    else
        action "$2" /bin/false
        exit 1
    fi
}

#################### Parse Command-Line Options ####################

# Use -r flag to force configuration refresh
FORCE_REFRESH=0
while getopts "r" opt; do
    case "$opt" in
        r)
            FORCE_REFRESH=1
            ;;
        *)
            ;;
    esac
done

#################### Task Execution ####################

## Get CPU architecture information
# Source the script to get CPU architecture
source "$Server_Dir/scripts/get_cpu_arch.sh"

# Check if CPU architecture was obtained
if [[ -z "$CpuArch" ]]; then
    echo "Failed to obtain CPU architecture"
    exit 1
fi

## Temporarily unset proxy environment variables
unset http_proxy
unset https_proxy
unset no_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
unset NO_PROXY

## Check if configuration file exists and optionally skip configuration refresh
if [ $FORCE_REFRESH -eq 0 ] && [ -f "$Conf_Dir/config.yaml" ]; then
    echo -e "\n[INFO] Existing configuration file found: $Conf_Dir/config.yaml"
    echo -e "[INFO] Skipping configuration refresh. Use -r option to force update.\n"
else
    echo -e "\n[INFO] No existing configuration file found or refresh forced. Proceeding with configuration update...\n"

    ## Clash Subscription URL Check and Configuration File Download
    
    echo -e '\nChecking subscription address...'
    Text1="Clash subscription address is accessible!"
    Text2="Clash subscription address is not accessible!"
    curl -o /dev/null -L -k -sS --retry 5 -m 10 --connect-timeout 10 -w "%{http_code}" "$URL" | grep -E '^[23][0-9]{2}$' &>/dev/null
    ReturnStatus=$?
    if_success "$Text1" "$Text2" $ReturnStatus

    echo -e '\nDownloading Clash configuration file...'
    Text3="Configuration file config.yaml downloaded successfully!"
    Text4="Failed to download configuration file config.yaml, exiting startup!"

    # Attempt to download using curl
    curl -L -k -sS --retry 5 -m 10 -o "$Temp_Dir/clash.yaml" "$URL"
    ReturnStatus=$?
    if [ $ReturnStatus -ne 0 ]; then
        # Fallback: try using wget for the download
        for i in {1..10}; do
            wget -q --no-check-certificate -O "$Temp_Dir/clash.yaml" "$URL"
            ReturnStatus=$?
            [ $ReturnStatus -eq 0 ] && break
        done
    fi
    if_success "$Text3" "$Text4" $ReturnStatus

    # Rename the downloaded configuration file
    \cp -a "$Temp_Dir/clash.yaml" "$Temp_Dir/clash_config.yaml"

    ## Check if subscription content conforms to the Clash configuration standard and attempt conversion
    ## (Currently not supported on non-x86_64 architectures; this feature will be added later)
    if [[ $CpuArch =~ "x86_64" || $CpuArch =~ "amd64" ]]; then
        echo -e '\nChecking if subscription content conforms to the Clash configuration standard:'
        bash "$Server_Dir/scripts/clash_profile_conversion.sh"
        sleep 3
    fi

    ## Reformat and configure the Clash configuration file
    # Extract the proxy-related configuration
    sed -n '/^proxies:/,$p' "$Temp_Dir/clash_config.yaml" > "$Temp_Dir/proxy.txt"

    # Merge to form the new config.yaml
    cat "$Temp_Dir/templete_config.yaml" > "$Temp_Dir/config.yaml"
    cat "$Temp_Dir/proxy.txt" >> "$Temp_Dir/config.yaml"
    \cp "$Temp_Dir/config.yaml" "$Conf_Dir/"

    # Configure Clash Dashboard settings
    Work_Dir=$(cd "$(dirname "$0")" && pwd)
    Dashboard_Dir="${Work_Dir}/dashboard/public"
    sed -ri "s@^# external-ui:.*@external-ui: ${Dashboard_Dir}@g" "$Conf_Dir/config.yaml"
    sed -r -i '/^secret: /s@(secret: ).*@\1'${Secret}'@g' "$Conf_Dir/config.yaml"
fi

## Start the Clash service
echo -e '\nStarting Clash service...'
Text5="Service started successfully!"
Text6="Service failed to start!"
if [[ $CpuArch =~ "x86_64" || $CpuArch =~ "amd64" ]]; then
    nohup "$Server_Dir/bin/clash-linux-amd64" -d "$Conf_Dir" &> "$Log_Dir/clash.log" &
    ReturnStatus=$?
    if_success "$Text5" "$Text6" $ReturnStatus
elif [[ $CpuArch =~ "aarch64" || $CpuArch =~ "arm64" ]]; then
    nohup "$Server_Dir/bin/clash-linux-arm64" -d "$Conf_Dir" &> "$Log_Dir/clash.log" &
    ReturnStatus=$?
    if_success "$Text5" "$Text6" $ReturnStatus
elif [[ $CpuArch =~ "armv7" ]]; then
    nohup "$Server_Dir/bin/clash-linux-armv7" -d "$Conf_Dir" &> "$Log_Dir/clash.log" &
    ReturnStatus=$?
    if_success "$Text5" "$Text6" $ReturnStatus
else
    echo -e "\033[31m\n[ERROR] Unsupported CPU Architecture!\033[0m"
    exit 1
fi

# Output the Dashboard access address and Secret
echo ''
echo -e "Clash Dashboard access address: http://<ip>:9090/ui"
echo -e "Secret: ${Secret}"
echo ''

# Add environment variables (requires root privileges)
cat > /etc/profile.d/clash.sh <<'EOF'
# Enable system proxy
function proxy_on() {
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    export no_proxy=127.0.0.1,localhost
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export NO_PROXY=127.0.0.1,localhost
    echo -e "\033[32m[√] Proxy enabled\033[0m"
}

# Disable system proxy
function proxy_off(){
    unset http_proxy
    unset https_proxy
    unset no_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset NO_PROXY
    echo -e "\033[31m[×] Proxy disabled\033[0m"
}
EOF

echo -e "Please run the following command to load the environment variables: source /etc/profile.d/clash.sh\n"
echo -e "Please run the following command to enable the system proxy: proxy_on\n"
echo -e "To temporarily disable the system proxy, run: proxy_off\n"

