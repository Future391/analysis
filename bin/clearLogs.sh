#!/bin/bash
[[ ! -d $1 || -z $2 ]] && echo "目录不存在或前缀为空!" && exit

logDir=$1
prefix=$2
cd $logDir

today=`date +"%Y%m%d"`
curMonth=`date +"%Y%m"`
lastDay=`date -d "1 days ago" +"%Y%m%d"`
month=`date -d "1 days ago" +"%Y%m"`
lastMonth=`date -d "1 month ago" +"%Y%m"`
last3Month=`date -d "3 month ago" +"%Y%m"`

lastDayLog=$logDir/${prefix}_${lastDay}.log

[[ ! -f $month ]] && mkdir -p $logDir/$month
[[ -f $lastDayLog ]] && mv $lastDayLog $logDir/$month
[[ -d $logDir/$lastMonth ]] && tar zcvf $logDir/${lastMonth}.tgz -C $logDir $lastMonth && rm -r $logDir/$lastMonth
[[ -f $logDir/${last3Month}.tgz ]] && rm $logDir/${last3Month}.tgz
