#!/bin/bash 

host=
username=
password=

usage() 
{
	echo "Usage: $0 -h[mysql server address] -u[username] -p[password]" 
	exit -1
}

[ $# -eq 0 ] && usage

while getopts :h:u:p: OPTION
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
		?)
			usage
			;;
	esac
done


#获取非系统默认的数据库列表
sql="SELECT DISTINCT table_schema FROM information_schema.TABLES WHERE table_schema != 'information_schema' && table_schema != 'mysql' && table_schema != 'performance_schema' && table_schema != 'sys';"

rm -fr dbname.log
rm -fr change.log

mysql -h$host -u$username -p$password -NBe "$sql" >> dbname.log

for db in `cat dbname.log`
do
#创建存储过程的sql语句，通过查询information_schema表获取指定数据库的表名
`mysql -h$host -u$username -p$password -D $db >> change.log << EOF
DELIMITER $$
DROP PROCEDURE IF EXISTS lowercase $$
CREATE PROCEDURE lowercase(IN dbname VARCHAR(50)) 
BEGIN	
	DECLARE done BOOL DEFAULT FALSE;
	DECLARE oldname varchar(200);
	DECLARE cur CURSOR FOR SELECT table_name FROM information_schema.TABLES where table_schema = dbname;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
	OPEN cur;

	REPEAT

	FETCH cur INTO oldname;
	SET @newname = LOWER(oldname);
	-- if table name is already upercase, then do nothing
	SET @isuppercase = @newname <> BINARY oldname;
	IF NOT done && @isuppercase THEN
	SELECT dbname as dbname, oldname as old_table_name, @newname as new_table_name;
	SET @SQL = CONCAT('RENAME TABLE ', oldname, ' TO ', @newname);
	PREPARE stmt FROM @SQL;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
	END IF;

	UNTIL done END REPEAT;
	CLOSE cur;
END $$

DELIMITER ;
CALL lowercase('$db');
EOF`
done

echo "--------------------------------------------"
echo "--------------------------------------------"
echo "--------------------------------------------"

count=0
cat change.log | while read -a row;
do
	count=$[$count + 1]
	if [ $[$count%2] != 0 ]
	then
		continue
	fi
	name=${row[0]}
	oldname=${row[1]}
	newname=${row[2]}
	echo RENAME TABLE [$oldname] to [$newname] from DATABASE [$name]
	echo "--------------------------------------------"
done

rm -fr dbname.log
rm -fr change.log
