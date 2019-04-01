#!/bin/bash
#set apt source to chinese provider;


release_name=

function get_release_name(){
	release_name=`lsb_release -cs`
}


#backup origin sources.list
function backup(){
	apt-get clean all && rm -fr /var/cache/apt/*
	rm -fr /etc/apt/sources.list.bak
	cp /etc/apt/sources.list /etc/apt/sources.list.bak
	rm -fr /etc/apt/sources.list
	touch /etc/apt/sources.list
}

function restore(){
	apt-get clean all && rm -fr /var/cache/apt/*
	rm -fr /etc/apt/sources.list
	cp /etc/apt/sources.list.bak /etc/apt/sources.list
}



function set_aliyun(){
	cat > /etc/apt/sources.list << EOF
deb http://mirrors.aliyun.com/ubuntu/ $release_name main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $release_name main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $release_name-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $release_name-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $release_name-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $release_name-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $release_name-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $release_name-backports main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $release_name-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $release_name-proposed main restricted universe multiverse
EOF
}

echo "[log]please run as root, or run with sudo"
echo "=============================================="
echo "=============================================="
read -s -n1 -p "[log]press any key to continue"
echo "\n"
echo "=============================================="
echo "=============================================="

get_release_name
echo "[log]ubuntu release version name: $release_name"
echo "=============================================="
echo "[log]start backup sources.list"
backup
if [ $? -ne 0 ]
then
	echo "[error]backup sources.list failed!"
	exit -1
fi
echo "[log]backup sources.list to sources.list.bak success!"
echo "=============================================="

echo "[log]start to set apt sources to provider aliyun"
set_aliyun
if [ $? -ne 0 ]
then
	echo "[error]set apt sources to aliyun failed!, restore origin apt sources"
	restore
	exit -1
fi
echo "[log]set apt sources to aliyun success!"
echo "=============================================="
echo "[log]run apt-get update"
echo "=============================================="
apt-get update
