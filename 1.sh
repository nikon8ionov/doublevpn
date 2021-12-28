#!/bin/bash

apt update

###################
rm -R /root/doublevpn &> /dev/null
rm -R /root/1.sh &> /dev/null
rm -R /var/lib/openvpn &> /dev/null
###################


# Detect OS
# $os_version variables aren't always in use, but are kept here for convenience
if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"
elif [[ -e /etc/debian_version ]]; then
	os="debian"
	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
	group_name="nogroup"
else
	echo "This installer seems to be running on an unsupported distribution.
Supported distros are Ubuntu, Debian."
	exit
fi


# Install ansible #
echo "Installing Ansible..."
if [[ "$os" == "ubuntu" ]]; then
  apt update
  apt install software-properties-common -y
  add-apt-repository --yes --update ppa:ansible/ansible
  apt install ansible -y
elif [[ "$os" == "debian" ]]; then
  echo "Adding Ansible PPA"
  UBUNTU_VERSION=$(dpkg --status tzdata|grep Provides|cut -f2 -d'-')
  echo "deb http://ftp.debian.org/debian $UBUNTU_VERSION-backports main" | tee /etc/apt/sources.list.d/$UBUNTU_VERSION-backports.list
fi


apt-get install git curl sshpass python-apt -y
git clone https://github.com/nikon8ionov/doublevpn.git && cd /root/doublevpn/


# run Ansible playbook
ansible-playbook gen_conf.yml
echo "Please wait..."
ansible-playbook main.yml

CNF=$(cat  /root/doublevpn/wg-client.conf);
MYIP=$(curl -4 https://icanhazip.com/);


# docker
curl -fsSL https://get.docker.com/ | sh
systemctl start docker
systemctl enable docker

mkdir -p /var/lib/openvpn/mongodb

docker rm -f openvpn &> /dev/null
docker run \
    --name openvpn \
    --privileged \
    --detach \
    --privileged \
    --restart=always \
    --net=host \
    -v /var/lib/openvpn/mongodb:/var/lib/mongodb\
    -v /var/lib/openvpn:/var/lib/pritunl \
      jippi/pritunl

echo " If you want to use wireguard, copy this text"
echo "#####################################################################################################################"
echo "$CNF"
echo "#####################################################################################################################"
echo "If you want to use OpenVPN"
echo "open in web browser    :  https://$MYIP"
echo "Enter login/password   :  pritunl/pritunl"

rm -R /root/doublevpn &> /dev/null
rm -R /root/1.sh &> /dev/null
