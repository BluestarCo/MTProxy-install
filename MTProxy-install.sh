#!/bin/bash
#
# https://github.com/BluestarCo/MTProxy-install
#
# Copyright (c) 2018 BlueStar. Released under the MIT License.


if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi


if [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
	OS=centos
	GROUPNAME=nobody
	RCLOCAL='/etc/rc.d/rc.local'
else
	echo "Looks like you aren't running this installer CentOS"
	exit
fi



echo "Welcome to BluestarCo MTProxy easy install setup."
echo "Okay, that was all I needed. We are ready to set up your MTProxy server now."
read -n1 -r -p "Press any key to continue..."
clear
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
	read -p "IP address: " -e -i $IP IP
	# If $IP is a private IP address, the server must be behind NAT
	if echo "$IP" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
		echo
		echo "This server is behind NAT. What is the public IPv4 address or hostname?"
		read -p "Public IP address / hostname: " -e PUBLICIP
fi
clear
echo "Install Updates..."
yum update -y 
clear
echo "Install Development Tools..."
yum groupinstall "Development Tools" -y
yum install git -y
yum install openssl-devel -y
yum install curl -y
yum install vim-common
yum install screen -y
cd ~/
clear
echo "Downloading MTProxy Source..."
git clone https://github.com/TelegramMessenger/MTProxy.git
cd MTProxy
clear
echo "Building MTProxy Source..."
chmod a+x Makefile
make
cd objs
cd bin
clear
echo "Build Complete , Downloading Configs..."
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
clear
echo "Making Secret Hash..."
secret=$(head -c 16 /dev/urandom | xxd -ps)
clear
echo "Adding Service to auto run list..."
echo -n > /etc/systemd/system/MTProxy.service
echo "[Unit]" >> /etc/systemd/system/MTProxy.service
echo "Description=MTProxy" >> /etc/systemd/system/MTProxy.service
echo "After=network.target" >> /etc/systemd/system/MTProxy.service
echo "" >> /etc/systemd/system/MTProxy.service
echo "[Service]" >> /etc/systemd/system/MTProxy.service
echo "Type=simple" >> /etc/systemd/system/MTProxy.service
echo "WorkingDirectory=/root/MTProxy/objs/bin" >> /etc/systemd/system/MTProxy.service
echo "ExecStart=/root/MTProxy/objs/bin/mtproto-proxy -u nobody -p 8888 -H 443 -S $secret --aes-pwd proxy-secret proxy-multi.conf -M 1" >> /etc/systemd/system/MTProxy.service
echo "Restart=on-failure" >> /etc/systemd/system/MTProxy.service
echo "" >> /etc/systemd/system/MTProxy.service
echo "[Install]" >> /etc/systemd/system/MTProxy.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/MTProxy.service
clear
echo "Restarting services."
systemctl daemon-reload
systemctl restart MTProxy.service
systemctl enable MTProxy.service
echo -n > ~/mtproxy-status
echo "#!/bin/bash" >> ~/mtproxy-status
echo "systemctl status MTProxy.service" >> ~/mtproxy-status
echo -n > ~/mtproxy-remove
echo "#!/bin/bash" >> ~/mtproxy-remove
echo "echo Uninstalling MTProxy from your server..." >> ~/mtproxy-remove
echo "cd ~/" >> ~/mtproxy-remove
echo "rm -rf MTProxy" >> ~/mtproxy-remove
echo "rm -rf MTProxy-link.txt" >> ~/mtproxy-remove
echo "rm -rf mtproxy-status" >> ~/mtproxy-remove
echo "rm -rf /etc/systemd/system/MTProxy.service" >> ~/mtproxy-remove
clear
echo "echo Uninstalling MTProxy Completed..." >> ~/mtproxy-remove
echo "rm -rf ~/mtproxy-remove" >> ~/mtproxy-remove

clear
echo "Services started."
clear 
echo
	echo "Install Finished!"
	echo
	echo "Your MTProxy available at :"
	echo "tg://proxy?server=$IP&port=443&secret=$secret"
	echo "tg://proxy?server=$IP&port=443&secret=$secret" > ~/MTProxy-link.txt
	echo 
    echo "Your MTProxy link writed to file and available at :"
    echo "/root/MTProxy-link.txt"
    echo
    echo
	echo "If you need to Check MTProxy status, it should be active you can run mtproxy-status located at :/root/mtproxy-status"
	echo
	echo "Example : sh mtproxy-status"
	echo
	echo "If you need to Uninstall  MTProxy you can run mtproxy-remove located at :/root/mtproxy-remove"
	echo
	echo "Example : sh mtproxy-remove"
