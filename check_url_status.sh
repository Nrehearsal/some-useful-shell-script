#!/bin/bash

url1=""
url2=""
url3=""

checkurl() {
	#`curl -s --max-time 3 $1 >> /dev/null`
	status_code=`curl --write-out \%\{http_code\} -silent --max-time 3 $1 --output /dev/null`
	#连接建立异常
	if [ $? -ne 0 ]
	then
		echo "[超时异常]$1"
		#TODO error handler
		echo "-------------------------------------------------"
		return
	fi

	#http响应异常
	if [[ "$status_code" -ne 200 ]]
	then
		echo "[服务返回异常]status_code: $status_code"
		echo "[服务返回异常]url: $1"
		#TODO error handler
		echo "-------------------------------------------------"
		return
	fi

	echo "[正常]status_code: $status_code"
	echo "[正常]url: $1"
	echo "-------------------------------------------------"
}

main() {
	while :
	do
		echo "[开始]"
		echo "*******************************************"
		#i最大等于url的个数
		for(( i=1; i<=3; i++))
		do
			url=`eval echo '$'url$i`
			checkurl $url
		done

		echo "[结束]"
		echo "*******************************************"
		echo ""

		#per 5 seconds
		sleep 5
	done
}

main
