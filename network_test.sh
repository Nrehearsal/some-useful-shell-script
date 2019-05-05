#!/bin/bash

target_list=
host=
username=
password=

#automatically execute ssh-copy-id
ssh_copy_id() {
echo 'set timeout 5
spawn ssh-copy-id -i '$HOME'/.ssh/id_rsa.pub '$username'@'$host'
expect {
	#first connect, no public key in ~/.ssh/known_hosts
	"(yes/no)?" {
		send "yes\r"
		puts "new client"
		expect "*password:" {
			send "'$password'\r"
			puts "password send"
			expect "please try again" {
				puts "password is incorrect"
				exit 4
			}
		}
	}
	#already has public key in ~/.ssh/known_hosts
	"*password:" {
		send "'$password'\r"
		puts "old client"
		puts "password send"
		expect "please try again" {
			puts "password is incorrect"
			exit 4
		}

	}
	"All keys were skipped because they already exist on the remote system"
	{
		puts "ssh key already on remote"
		exit 0
	}
	"Resource temporarily unavailable" {
		puts "connected failed\r"
		exit 4
	}
	"Connection timed out" {
		puts "connected timeout"
		exit 4
	}
	timeout {
		puts "expect timeout"
		exit 4
	}
	eof
}' | expect
}

           
main (){
	echo "run env: [$host:$username:$password]"

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

	if  !(test -s $target_list)
	then
		echo "$target_list does not exist or it is empty"
		exit -1
	fi

		
	#ssh-copy-id $host
	ssh_copy_id
	if [ $? -ne 0 ]
	then
		echo "[error]ssh_copy_id to [$host] failed."
		exit -1
	else
		echo "[success]ssh key deploy on [$host] successed."
	fi

	echo "------------------------------------------"
	echo "[log]start to test connectivity on [$host]"

	for target in `cat $target_list`
	do
		target="${target/:/ }"
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
}

usage() 
{
	echo "Usage: $0 -t[test target file] -h[host for check] -u[username] -p[password]" 
	exit -1
}


#start from here
[ $# -eq 0 ] && usage

while getopts :t:h:u:p: OPTION
do
	case $OPTION in
		t)
			target_list=$OPTARG
			;;
		h)
			host=$OPTARG
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
