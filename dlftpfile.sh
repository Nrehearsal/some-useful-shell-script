#!/bin/bash

usage() 
{
	echo "Usage: $0 -l[ftp path with directory name] -u[username] -p[password] -d[path of file] -f[filename]" 
	exit -1
}

[ $# -eq 0 ] && usage

host=
username=
password=
directory=
filename=


while getopts :h:u:p:d:f: OPTION
do
	case $OPTION in
		h)
			host=$OPTARG
			;;
		u)
			username=$OPTARG
			;;
		p)
			password=$OPTARG
			;;
		d)
			directory=$OPTARG
			;;
		f)
			filename=$OPTARG
			;;
		?)
			usage
			;;
	esac
done

#check if the file exists or the size is 0
target="`date "+%Y-%m-%d"`-$filename"
echo "target filename $target"

if test -s $target
then 
	echo "$filename exists in local space, and is not empty"
	exit -1
fi

#check if the file exists on the ftp server
checkftpfile() {
rm -fr ftp.log

`ftp -inv $host >> ftp.log << EOF
user $username $password
passive
size $directory/$filename
quit 
EOF`
}

checkftpfile
#230 login failed code
grep -nr "230 " ftp.log >> /dev/null
if [ $? -ne 0 ]
then
	echo "ftp connection failed, please check the username and password for this ftp server"
	exit -1
fi

#213 file not exsits code
grep -nr "213 " ftp.log >> /dev/null
if [ $? -ne 0 ]
then
	echo "$filename not exsits on the server"
	exit -1
fi

#213 0 file is empty
grep -nr "213 0" ftp.log >> /dev/null
if [ $? -eq 0 ]
then
	echo "$filename exsits on server, but the size is 0"
	exit -1
fi

url="ftp://$host/$directory/$filename --ftp-user=$username --ftp-password=$password"
echo "start download $filename from $url"

start_time=`date +%s`

#in quiet mode, with timeout 10s, retry only once
#start download file
`wget $url -O $target -q -T 10 -t 1`
#`wget $url -O $target -T 10 -t 1`

end_time=`date +%s`

if [ $? -ne 0 ]
then 
	rm $target
	echo "$filename download failed"
else
	echo "download $filename from ftp server successfully, cost $((end_time-start_time))s"
fi

rm -fr ftp.log
