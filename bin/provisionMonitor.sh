#!/bin/bash
CUR_DIR=$(cd `dirname $0`;pwd)
TODAY=$(date +"%Y%m%d")
LOG_FILE="/data/app/analysis/logs/monitor_${TODAY}.log"
if [ ! -f $LOG_FILE ]; then
	echo "0";exit
fi


#处理类型->BusinessThreadRate,Deadlock,Resources,ThreadPool,CsfApi,JVMHeapRate
DEAL_TYPE=""
#统计时间范围，默认最近35分钟
TIME_RANGE=35
TIME_PATTERN="^[1-9][0-9].*$"

case $# in 
0)
	echo "0";exit
	;;
1|2)
	case $1 in 
	"BusinessThreadRate"|"Deadlock"|"Resources"|"ThreadPool"|"CsfApi"|"JVMHeapRate")
		DEAL_TYPE=$1
		;;
	*)
		echo -e "0";exit
        ;;
	esac
	if [[ $# -eq 2 && $2 =~ $TIME_PATTERN ]]; then
		TIME_RANGE=$2
	else
		echo -e "0";exit
	fi
	;;
*)
echo "0"
esac

KEYWORD="${DEAL_TYPE} Tests Warning"
WARN_TIME=`grep "$KEYWORD" $LOG_FILE | awk -F',' '{print $1}'`
if [[ -n $WARN_TIME ]]; then
	WARN_TIMESTAMP=`date -d "$WARN_TIME" +%s`
	NOW_TIMESTAMP=`date +%s`
	if [[ $(($NOW_TIMESTAMP-$WARN_TIMESTAMP)) -le $(($TIME_RANGE*60)) ]]; then
		echo "1";exit	
	fi	
fi
echo "0"

