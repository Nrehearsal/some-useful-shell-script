#!/bin/bash

target_list=
server_list=
username=
password=

#automatically execute ssh-copy-id
ssh_copy_id() {
echo 'set timeout 3
spawn ssh-copy-id -o connecttimeout=2 -i '$HOME'/.ssh/id_rsa.pub '$1'@'$2'
expect {
	#first connect, no public key in ~/.ssh/known_hosts
	"(yes/no)?" {
		send "yes\r"
		expect "s password:"
			send "'$3'\r"
	}
	#already has public key in ~/.ssh/known_hosts
	"s password:" {
		send "'$3'\r"
	}
	"All keys were skipped because they already exist on the remote system"
	{
	}
	"Resource temporarily unavailable" {
		exit 4
	}
	"Connection timed out" {
		exit 4
	}
	timeout {
		exit 4
	}
}
expect of' | /usr/bin/expect >> /dev/null
}
            
main (){
	`which expect >> /dev/null`
	if [ $? -ne 0 ]
	then
		echo "this script depend on expect, please run apt-get install expect to install it."
		exit -1		
	fi

	#make sure there is a public key in .ssh directory
	if  !(test -s $HOME/.ssh/id_rsa.pub)
	then
		echo "$HOME/.ssh/id_rsa.pub is not exist, please tun ssh-keygen to create it."
		exit -1
	fi

	if  !(test -s $server_list)
	then
		echo "$server_list does not exist or it is empty"
		exit -1
	fi

	if  !(test -s $target_list)
	then
		echo "$server_list does not exist or it is empty"
		exit -1
	fi


	for host in `cat $server_list`
	do
		#ssh-copy-id $host
		ssh_copy_id $username $host $password
		if [ $? -ne 0 ]
		then
			echo "[error]ssh_copy_id to [$host] failed."
			echo "[next]go to next server."
			continue
		else
			echo "[success]copy ssh key to [$host] successed."
		fi

		echo "------------------------------------------"
		echo "[log]start to test connectivity on [$host]"
		for target in `cat $target_list`
		do
			target="${target/":"/" "}"
			cmd='ssh -o connecttimeout=2 '$username'@'$host' nc -z -w 2 '$target''
			#echo cmd=[$cmd]
			`$cmd`
			if [ $? -ne 0 ]
			then
				echo "[error][$host] connect to [$target] failed."
				#echo "------------------------------------------"
			else
				echo "[success][$host] connect to [$target] success."
				#echo "------------------------------------------"
			fi
		done
		echo "------------------------------------------"
		echo "------------------------------------------"
	done
}

usage() 
{
	echo "Usage: $0 -t[test target file] -s[server list file] -u[username for each server] -p[password for server user]" 
	exit -1
}


#start from here
[ $# -eq 0 ] && usage

while getopts :t:s:u:p: OPTION
do
	case $OPTION in
		t)
			target_list=$OPTARG
			;;
		s)
			server_list=$OPTARG
			;;
		u)
			username=$OPTARG
			;;
		p)
			password=$OPTARG
			;;
		?)
			usage
			;;
	esac
done
#start main function
main
