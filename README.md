[TOC]

# Project Introduction

This project uses the open-source project [Clash](https://github.com/Dreamacro/clash) as the core program, combined with scripts to implement a simple proxy function.

The main goal is to solve the problem of slow download speeds for resources such as GitHub on servers.

<br>

# Usage Notes

- It is recommended to run this project as the root user or use `sudo` for elevated privileges.
- If you encounter any issues while using this project, please first check the existing [issues](https://github.com/wanhebin/clash-for-linux/issues).
- Before submitting an issue, please remove any sensitive information (such as subscription URLs) from your submission.
- This project is based on the configurations of [Clash](https://github.com/Dreamacro/clash) and [yacd](https://github.com/haishanh/yacd). For detailed configuration instructions, please refer to the original projects.
- This project does not provide any subscription information. You must prepare your own Clash subscription URL.
- Before running, please manually modify the `.env` file and update the `CLASH_URL` variable; otherwise, the script will not work properly.
- This project has been tested on RHEL-based and Debian-based Linux distributions. Other distributions may require script modifications.
- Supports x86_64/aarch64 platforms.

> **Note**: If you encounter any issues while using this project, please check the [Issues](https://github.com/wanhebin/clash-for-linux/issues) section first for solutions. Due to limited free time, repeated questions that have already been answered or have existing solutions will not be responded to.

<br>

# User Guide

## Download the Project

Download the project:

```bash
$ git clone https://github.com/wanhebin/clash-for-linux.git
```

Enter the project directory and edit the `.env` file to modify the `CLASH_URL` variable.

```bash
$ cd clash-for-linux
$ vim .env
```

> **Note:** The variable `CLASH_SECRET` in the `.env` file is used to set a custom Clash secret. If left empty, the script will automatically generate a random string.

<br>

## Start the Program

Run the `start.sh` script:

- Navigate to the project directory:

```bash
$ cd clash-for-linux
```

- Run the startup script:

```bash
$ sudo bash start.sh

Checking subscription address...
Clash subscription address is accessible!                          [  OK  ]

Downloading Clash configuration file...
Configuration file config.yaml downloaded successfully!            [  OK  ]

Starting Clash service...
Service started successfully!                                      [  OK  ]

Clash Dashboard access address: http://<ip>:9090/ui
Secret: xxxxxxxxxxxxx

Please run the following command to load environment variables: source /etc/profile.d/clash.sh

Please run the following command to enable the system proxy: proxy_on

To temporarily disable the system proxy, run: proxy_off

```

```bash
$ source /etc/profile.d/clash.sh
$ proxy_on
```

- Check service ports:

```bash
$ netstat -tln | grep -E '9090|789.'
tcp        0      0 127.0.0.1:9090          0.0.0.0:*               LISTEN     
tcp6       0      0 :::7890                 :::*                    LISTEN     
tcp6       0      0 :::7891                 :::*                    LISTEN     
tcp6       0      0 :::7892                 :::*                    LISTEN
```

- Check environment variables:

```bash
$ env | grep -E 'http_proxy|https_proxy'
http_proxy=http://127.0.0.1:7890
https_proxy=http://127.0.0.1:7890
```

If all steps complete successfully, the Clash service has been successfully started, and you can now experience high-speed downloads of GitHub resources.

<br>

## Restart the Program

If you need to modify the Clash configuration, update the `conf/config.yaml` file and then restart the service using the `restart.sh` script.

> **Note:**  
> The `restart.sh` script does not update subscription information.

<br>

## Stop the Program

- Navigate to the project directory:

```bash
$ cd clash-for-linux
```

- Stop the service:

```bash
$ sudo bash shutdown.sh

Service stopped successfully. Please run the following command to disable the system proxy: proxy_off

```

```bash
$ proxy_off
```

Then, check the program ports, running processes, and environment variables (`http_proxy|https_proxy`). If they are no longer present, the service has been successfully stopped.

<br>

## Clash Dashboard

- **Access Clash Dashboard**

Open a web browser and enter the address displayed after running `start.sh`, for example:  
`http://192.168.0.1:9090/ui`

- **Login to the Management Interface**

Enter the following in the `API Base URL` field:  
`http://<ip>:9090`  

In the `Secret (optional)` field, enter the Secret displayed after startup.

Click "Add" and select the newly added management interface address. You can now configure Clash through the browser.

- **More Tutorials**

This Clash Dashboard is based on the [yacd](https://github.com/haishanh/yacd) project. For detailed usage instructions, please refer to the yacd documentation.

<br>

# Frequently Asked Questions

1. **Script error due to shell differences:**  
   Some Linux distributions have `/bin/sh` set to `dash` instead of `bash`, which can cause errors (e.g., `-en [ OK ]`). It is recommended to run scripts using `bash xxx.sh`.

2. **Proxy nodes not appearing in the UI:**  
   If you cannot find proxy nodes in the UI, the issue is likely due to the provider encoding the Clash configuration file in Base64, or the file format not conforming to Clash standards.

   This project includes automatic detection and conversion for Clash configuration files. If the issue persists, you may need to manually convert the subscription URL via a self-hosted or third-party platform (not recommended due to potential privacy risks).

3. **`error: unsupported rule type RULE-SET` appears in logs:**  
   This error is explained in the official [WIKI](https://github.com/Dreamacro/clash/wiki/FAQ#error-unsupported-rule-type-rule-set). Please check the documentation for solutions.
