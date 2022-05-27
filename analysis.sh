#!/bin/bash
#version: v1.3
#Author: Pengxb
#Mail: future391@126.com
#Date: 2020/04/02

#============= 公共参数 start===============#
exampleStr="格式: sh $0 [参数]
参数说明：
    -f,--conf_file           配置文件路径,内容格式为key=value
    -v,--variable            脚本运行时变量,参数为[key=value]键值对,会覆盖配置文件中的变量
    -h,--help                显示帮助信息
例如:\nsh $0 -f /data/app/analysis/conf/monitor.conf
sh $0 -v LOG_LEVEL=DEBUG -v isSendMail=1\n"
warnExampleStr="请输入正确参数!\n\n$exampleStr\n"

curDir=$(cd `dirname $0`;pwd)
logDir=$curDir/logs

configFile=
#存储变量值
declare -A varMap
#存储传入的参数
declare -A paramMap
#时间设置
nowTime=`date +%Y%m%d%H%M%S`
todayY_M_D=`date +%Y-%m-%d`
todayYMD=`date +%Y%m%d`
month=`date +%Y-%m`
timestamp=`date +%s`
#============= 公共参数 end===============#

#============= 自定义参数 start ===============#
JAVA_HOME="/opt/jdk1.7.0_80/bin"
#打印日志级别
LOG_LEVEL="DEBUG"
projectName="analysis"
#进程ID
processId=""
heapInfo=""
#GC信息
gcutilFile=""
OGThreshold=0.8
PGThreshold=0.8
#Top监控信息
topInfo=""
#进程中CPU占用高的线程信息
topNCpuUsageThread=""
cpuUsageThreshold=0.8
openFilsThreshold=0.5
#进程启动时间
lstart=""
#进程运行时间
etime=""

#--------stack dump业务线程告警设置
#业务线程标识
businessClass="com.ai"
#堵塞线程告警阈值
threadThreshold="0.7"
#线程stack告警(1告警，0不告警)
threadStackWarnFlag=0
#stack分析结果文件名称
stackAnalysisName="stackAnalysis"
#不同stack组分隔标识
separateTag="HELLOWORLD"

#---------线程池监控设置-----------
#进程标识
processCode="pa-xxx-center"
#XXX日志目录
appLogDir="/data/app/logs"
#是否监控线程池(1是,0否)
threadPoolDebugEnable=1
#关键字
threadPoolKV="请求中没有标识，非csf客户端接入"

#---------XXX接口测试设置----------
#XXX接口访问地址
csfUrl="localhost:9601/sa-xxx/crmTest/comframTest"
#请求方法类型
csfMethod=POST
#XXX接口名
csfApi="xxx_IOrderReceiveApiCSV_orderStateQuery"
#XXX接口入参
csfParam='{"service":"tesorderStateQuery","orderlineid":"2015082405317378"}'
#是否测试接口(1测试,0不测试)
csfApiDebugEnable=1
#XXX Api测试结果(1异常,0正常)
apiDebugWarnFlag=0

#资源类名称,用于检测资源是否被释放。多个时用逗号(,)隔开
resourceClassName="HttpURLConnection,JDBC4Connection"
resourceInsNum="500"

#----------邮件设置----------
warnFlag=0
#邮件发送命令(mail|sendmail)
mailType="sendmail"
#邮件命令路径
mailCommand=/usr/sbin/sendmail
#是否发送邮件(1发送,0不发送)
isSendMail=1
#是否根据阈值告警发送邮件(1是,0否, 仅在isSendMail=1情况下生效,即配置发送邮件前提下，监控指标超过阈值时告警)
isSendMailByThreshold=1
#是否发送附件(1发送,0不发送)
isSendAttachment=1
contentType="html"
#压缩附件名称
compressAttachmentName="jstack.dump.tgz"
#邮件主题
subject="xxx服务监控"
#发件人(这里使用别名代替)
from="MonitorCenter@xxx.com"
#收件人
to="pengxb@xxx.com"
#抄送
cc="zhangpc5@xxx.com,hefl@xxx.com,liangfs@xxx.com,yangpei3@xxx.com,shenym5@xxx.com,panzg@xxx.com,kuigc@xxx.com,zhuxc@xxx.com,mazj5@xxx.com,lurl@xxx.com,lihao16@xxx.com"
#公邮,暂不支持
common="cmisupport2b@xxx.com,cmioperationsupport@xxx.com"
#备注信息
errorMsg="<span style=\"color: red;\">异常<\/span>"
normalMsg="<span style=\"color: green;\">正常<\/span>"
#============= 自定义参数 end ===============#

#============ 存储变量 start ============#
varMap["projectName"]=$projectName
varMap["JAVA_HOME"]=$JAVA_HOME
varMap["LOG_LEVEL"]=$LOG_LEVEL
varMap["businessClass"]=$businessClass
varMap["threadThreshold"]=$threadThreshold
varMap["stackAnalysisName"]=$stackAnalysisName
varMap["processCode"]=$processCode
varMap["centerCode"]=$centerCode
varMap["appLogDir"]=$appLogDir
varMap["threadPoolKV"]=$threadPoolKV
varMap["threadPoolDebugEnable"]=$threadPoolDebugEnable
varMap["csfUrl"]=$csfUrl
varMap["csfApi"]=$csfApi
varMap["csfParam"]=$csfParam
varMap["csfMethod"]=$csfMethod
varMap["resourceClassName"]=$resourceClassName
varMap["mailType"]=$mailType
varMap["mailCommand"]=$mailCommand
varMap["isSendMail"]=$isSendMail
varMap["isSendMailByThreshold"]=$isSendMailByThreshold
varMap["isSendAttachment"]=$isSendAttachment
varMap["contentType"]=$contentType
varMap["compressAttachmentName"]=$compressAttachmentName
varMap["subject"]=$subject
varMap["from"]=$from
varMap["to"]=$to
varMap["cc"]=$cc
varMap["mailModel"]=$mailModel
varMap["csfApiDebugEnable"]=$csfApiDebugEnable
varMap["OGThreshold"]=$OGThreshold
varMap["PGThreshold"]=$PGThreshold
varMap["processId"]=$processId
varMap["cpuUsageThreshold"]=$cpuUsageThreshold
varMap["openFilsThreshold"]=$openFilsThreshold
varMap["resourceInsNum"]=$resourceInsNum
varMap["timerHour"]=$timerHour
#============ 存储变量 end ============#

#打印日志信息
function printLogTime()
{
	[[ -n $1 ]] && {
		LOG_LEVEL=`echo $1 | tr a-z A-Z`
		[[ $LOG_LEVEL != "DEBUG" && $LOG_LEVEL != "INFO" && $LOG_LEVEL != "WARN" && $LOG_LEVEL != "ERROR" ]] && LOG_LEVEL="DEBUG"
	}
	#纳秒
	local millis=`date +%N`
	echo "$(date +"%Y-%m-%d %H:%M:%S"),${millis:0:3} $LOG_LEVEL"
}

#获取默认值
function getDefaultValue(){
	local defaultValue=$1
	local var=$2
	[[ -z $var ]] && var=$defaultValue
	echo $var
}

#刷新变量值
function refreshVariable(){
	echo -e "`printLogTime` 刷新变量值 variable->[before,after]"
	local sucCnt=0
	local failCnt=0
	local keys=${!varMap[*]}
	[[ $# -gt 0 ]] && keys=$*
	for key in $keys
	do
		local oldValue=${varMap[$key]}
		local newValue=${paramMap[$key]}
		#更新变量值
		varMap[$key]=$newValue
		#更新变量值
		read $key <<EOF
		$newValue
#!!!这里的EOF必须保证左边没有字符存在,否则会报错
EOF
		echo -e "$key->[$oldValue,$newValue]"
		sucCnt=$(($sucCnt+1))
	done
	echo -e "`printLogTime` 刷新完成,共${sucCnt}个受影响"
}

#发送邮件
function sendEmail()
{
	local subject=$1
	local from=$2
	local to=$3
	local cc=$4
	local attachment=$5
	local mailContentFile=$6 
	echo -e "`printLogTime` 开始发送邮件..."
	echo -e "`printLogTime` 主题: $subject"
	echo -e "`printLogTime` 发件人: $from"
	echo -e "`printLogTime` 收件人: $to"
	echo -e "`printLogTime` 抄送: $cc"
	mailType=${mailType:-"sendmail"}
	if [[ $mailType == "mail" ]]; then
		#mail方式
		$mailCommand -s $subject -S "from=$from" $attachment $cc $to < $mailContentFile
	elif [[ $mailType == "sendmail" ]]; then
		#sendmail方式
		#注：以下邮件模板中的空行切勿删除
		boundaryId=`uuidgen`
#附件前缀
		attachFilePrefix="--$boundaryId
Content-Type: application/octet-stream
Content-Transfer-Encoding: base64
Content-Disposition: attachment;filename="
echo -e "attachment: $attachment"
#`for file in $attachment; do echo -e "$attachFilePrefix\"$(basename $file)\"\n\n$(base64 $file)\n";done`
#`cat ./conf/monitor.template`
echo -e \
"From: $from
To: $to
Cc: $cc
Subject: $subject
MIME-Version: 1.0
Content-Type: multipart/mixed;boundary=\"$boundaryId\"

--$boundaryId
Content-Type: text/html; charset=utf-8
Content-Disposition: inline
Content-Transfer-Encoding: quoted-printable

`cat $mailContentFile`

`for file in $attachment; do echo -e "$attachFilePrefix\"$(basename $file)\"\n\n$(base64 $file)\n";done`

--$boundaryId
" | $mailCommand -t 
	fi
	echo -e "`printLogTime` 邮件发送完成"
}

#参数校验
case $# in 
0)
	echo -e "$warnExampleStr";exit
	;;
1)
	case $1 in
	"-h"|"--help")
		echo -e "$exampleStr";exit
		;;
	*)
		echo -e "$warnExampleStr";exit
		;;
	esac
	;;
*)
	idx=0
	for var in $*
	do
		inParamArr[$idx]=$var
		let idx++
	done
	for((i=1;i<=$#;i=i+2))
	do
		let startPos=$i-1
		curVar=${inParamArr[$startPos]}
		next=${inParamArr[$i]}
		case $next in
		""|"-v"|"-variable"|"-h"|"--help"|"-f"|"--conf_file")
			echo -e "$warnExampleStr";exit
			;;
		*)
			case $curVar in
			"-v"|"--variable")
				key=`echo $next | awk -F'=' '{print $1}'`
				value=`echo $next | awk -F'=' '{print $2}'`
				paramMap["$key"]=$value
				;;
			"-f"|"--conf_file")
				configFile=$next
				if [[ -f $configFile ]]; then
					#检查文件格式
					[[ `awk '{if($0 !~ /^#.*/ && $0 !~ /^$/ && $0 !~ /^[a-z|A-Z|_].*=.*/) {print $0}}' $configFile | wc -l` -gt 0 ]] && {
						echo -e "配置文件[$configFile]参数格式不正确！"
						awk '{if($0 !~ /^#.*/ && $0 !~ /^[a-z|A-Z|_].*=.*/) {print "行"NR":\t" $0}}' $configFile
						exit
					}
				else
					echo -e "配置文件[$configFile]不存在！";exit
				fi
				;;
			*)
				;;
			esac
			;;
		esac
	done
esac

#加载配置文件参数
[[ -n $configFile && -f $configFile ]] && {
	#过滤注释和空行
	pattern1="^#.*|^$"
	while read line
	do
	[[ ! $line =~ $pattern1 ]] && {
		key=`echo "$line" | awk -F'=' '{print $1}'`
		value=`echo "$line" | awk -F'=' '{print $2}'`
		cmdParamFlag=0
		for cmdParamKey in ${!paramMap[*]}
		do
			[[ $key = $cmdParamKey ]] && cmdParamFlag=1 && echo -e "Command Key: $key"
		done
		#命令行参数优先
		[[ $cmdParamFlag = "0" ]] && [[ -z ${paramMap["$key"]} ]] && paramMap["$key"]=$value
	}
	done < $configFile
}

#刷新所有变量
refreshVariable

stackAnalysisShellPath=$curDir/bin/handleStack.sh
#服务文件检查
test ! -f $stackAnalysisShellPath && echo -e "`printLogTime ERROR` 服务文件[handleStack.sh]缺失，请检查是否存在！" && exit

#分析结果目录
targetDir="$curDir/logs/$projectName/$todayYMD"
test ! -d $targetDir && mkdir -p $targetDir

#html模板实例
mailModel=$curDir/$mailModel
mailModelFile=$targetDir/$mailModel_${nowTime}.html
cp $mailModel $mailModelFile

#刷新html模板实例阈值
pattern2=".*Num$"
pattern3=".*Threshold$"
keys=${!varMap[*]}
for key in $keys
do
	value=${varMap[$key]}
	[[ $key =~ $pattern2 ]] && sed -i "s/$key/$value/g" $mailModelFile
	[[ $key =~ $pattern3 ]] && {
		tmpThreshold=`echo "scale=0; ($value*100)/1" | bc`"%"
		sed -i "s/$key/$tmpThreshold/g" $mailModelFile
	}
done

#主机名
host=`hostname -f | awk -F'.' '{print $1}'`
echo "`printLogTime` hostname: $host"
echo "current shell processId: $$"

#=====================进程信息处理====================#
#检查进程
processWarnMsg=""
[[ -z $processId ]] && {
	ps -ef | grep "$processCode"
	procCnt=`ps -ef | grep "$processCode" | grep -v grep | awk '{if($8 ~ /.*java$/ && $2!="'$$'") print $2}' | wc -l`
	processIds=`ps -ef | grep "$processCode" | grep -v grep | awk '{if($8 ~ /.*java$/ && $2!="'$$'") print $2}'`
	case $procCnt in 
	    0)
			processWarnMsg="服务进程不存在";;
		1)
			processId=$processIds;;
		*)
			processWarnMsg="服务存在多个进程[$processIds]";;
	esac	
} || {
	procCnt=`ps -ef | grep $processId | grep -v grep | wc -l`
	test $procCnt -eq 0 && processWarnMsg="服务进程不存在"
}

sed -i -e "s/host/$host/g" -e "s/centerCode/$centerCode/g" -e "s/processCode/$processCode/g" -e "s/processExistRes/$procCnt/g" -e "s/processId/$processId/g" $mailModelFile
[[ -n $processWarnMsg ]] && {
	sed -i "s/processExistFlag/$errorMsg/g" $mailModelFile
	#依次将未用的变量置空
	cat $mailModelFile | grep -E ".*Res$|.*Flag$|lstart|etime" | grep -Eo "[a-z|A-Z|_|0-9]+$" | awk '{print $1}' | while read line
	do
		sed -i "s/$line//g" $mailModelFile
	done
	warnFlag=1
	sendEmail "$subject" "$from" "$to" "$cc" "" "$mailModelFile"
	exit
} || {
	sed -i "s/processExistFlag/$normalMsg/g" $mailModelFile
}

echo "`printLogTime` processId: $processId"

#进程启动时间
lstart=`ps -eo pid,lstart | grep "${processId}.*" | grep -v grep | awk -F' ' '{print $2,$3,$4,$5,$6}'`
test -n "$lstart" && lstart=`date -d "$lstart" +"%Y-%m-%d %H:%M:%S"`
sed -i "s/lstart/$lstart/g" $mailModelFile

#进程运行时间
etime=`ps -eo pid,etime | grep "${processId}.*" | grep -v grep | awk -F' ' '{print $2}'`
test -n "$etime" && etime=`echo $etime | sed 's/-/d /g'`
sed -i "s/etime/$etime/g" $mailModelFile

#进程CPU占用
cpuUsageRes=0.0
for((i=0;i<10;i++))
do
	curCpuUsage=`top -bn1 -p $processId | tail -1 | awk '{print $9}'`
	test `echo "$curCpuUsage>$cpuUsageRes" | bc` -eq 1 && cpuUsageRes=$curCpuUsage
	sleep 0.05
done
cpuUsageFlag=$normalMsg
test `echo "$cpuUsageRes>($cpuUsageThreshold*100)" | bc` -eq 1 && cpuUsageFlag=$errorMsg && warnFlag=1
sed -i -e "s/cpuUsageRes/${cpuUsageRes}%/g" -e "s/cpuUsageFlag/$cpuUsageFlag/g" $mailModelFile

#进程打开文件数
lsofFile="$targetDir/lsof_$nowTime.dump"
/usr/sbin/lsof -p $processId > $lsofFile
openFilsCnt=`wc -l $lsofFile | awk '{print $1}'`
openFilsLimit=`ulimit -a | grep "open files " | awk '{print $4}'`
openFilesRes="$openFilsCnt\/$openFilsLimit"
openFilesFlag=$normalMsg
[[ $openFilsLimit != "unlimited" && `echo "($openFilsCnt/$openFilsLimit)>$openFilsThreshold" | bc` -ne 0 ]] && openFilesFlag=$errorMsg && warnFlag=1
sed -i -e "s/openFilesRes/$openFilesRes/g" -e "s/openFilesFlag/$openFilesFlag/g" $mailModelFile

#进程端口监听信息
netstatFile="$targetDir/netstat_$nowTime.dump"
netstat -apn | grep $processId > $netstatFile

echo "`printLogTime` 获取Top Monitor信息"
topInfo=`top -bn 1 -p $processId`

#CPU占用Top10
echo "`printLogTime` 获取CPU占用前10线程信息"
topNCpuUsageThread=`ps -mp $processId -o THREAD,tid,time | sort -rk2 | head -11 | awk -F' ' '{if($8 ~ /[0-9]+/) {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%x\t%s\n",$1,$2,$3,$4,$5,$6,$7,$8,$8,$9} else if($8 == "TID") {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\tTID-Hex\t"$9} else{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$8"\t"$9}}'`

#======================JVM相关信息=======================#
#stackF文件
stackFile="$targetDir/jstackF_$nowTime.dump"
#stackL文件
jstackLFile="$targetDir/jstackL_$nowTime.dump"
#堆dump
heapFile="$targetDir/jmapHeap_$nowTime.dump"
#类实例文件
histoFile="$targetDir/histo_$nowTime.dump"
echo "`printLogTime` 获取jstack -F信息"
$JAVA_HOME/jstack -F $processId > $stackFile
echo "`printLogTime` 获取jstack -l信息"
$JAVA_HOME/jstack -l $processId > $jstackLFile
echo "`printLogTime` 获取JVM heap信息"
$JAVA_HOME/jmap -heap $processId > $heapFile
echo "`printLogTime` 获取JVM类实例信息"
$JAVA_HOME/jmap -histo $processId > $histoFile
echo "`printLogTime` 获取JVM GC信息"
gcutilFile=`$JAVA_HOME/jstat -gcutil $processId`	
echo -e "`printLogTime` 进程[$processId]信息已导出，dump文件[\n$stackFile\n$jstackLFile\n$heapFile\n$histoFile\n$lsofFile\n$netstatFile\n]"

#================================= Stack Dump文件分析 start ===================================#
#分离IN_NATIVE、BLOCKED线程，便于分析
tmpFile=$targetDir/jstackF_$nowTime.tmp
cat $stackFile | sed '/^Thread .*state.*/i\'${separateTag}'' | grep -v "^$" | sed 's/@bci.*//g' > $tmpFile
echo "${separateTag}" >> $tmpFile

totalCount=`cat $tmpFile | grep -E -o "^Thread.*state.*" | awk -F':' '{print $2}' | sort | uniq -c`

blockNum=`cat $tmpFile | grep -E -o "^Thread.*BLOCKED.*" | wc -l`
inNativeNum=`cat $tmpFile | grep -E -o "^Thread.*IN_NATIVE.*" | wc -l`
totalCountInfo="
线程状态 \t数量
BLOCKED  \t$blockNum
IN_NATIVE\t$inNativeNum
"
#BLOCKED
blockFile="$targetDir/blockStack_$nowTime.dump"
blockAnalysisFile="$targetDir/blockStackAnalysis_$nowTime.txt"
cat $tmpFile | sed -n '/^Thread .*BLOCKED/,/'${separateTag}'/p' | grep -v "^$" > $blockFile

#IN_NATIVE
inNativeFile="$targetDir/inNativeStack_$nowTime.dump"
inNativeAnalysisFile="$targetDir/inNativeAnalysisStack_$nowTime.txt"
cat $tmpFile | sed -n '/^Thread .*IN_NATIVE/,/'${separateTag}'/p' | grep -v "^$" > $inNativeFile

#邮件中线程分组统计结果取Top10
topN=10
#邮件内容
mailContentFile=$targetDir/mailStackAnalysis_$nowTime.txt
topNBlockFile=$targetDir/topNBlockFile_$nowTime.txt
topNInNativeFile=$targetDir/topNInNativeFile_$nowTime.txt
blockCompressFile=$targetDir/blockCompressFile_$nowTime.txt
inNativeCompressFile=$targetDir/inNativeCompressFile_$nowTime.txt

#执行分析脚本，输出分析结果
#businessBlock=`sh $stackAnalysisShellPath $blockFile $blockAnalysisFile $topN $topNBlockFile $blockCompressFile`
#businessInNative=`sh $stackAnalysisShellPath $inNativeFile $inNativeAnalysisFile $topN $topNInNativeFile $inNativeCompressFile`
businessBlock=`sh $stackAnalysisShellPath $blockFile $blockAnalysisFile $topN $topNBlockFile $blockCompressFile`
businessInNative=`sh $stackAnalysisShellPath $inNativeFile $inNativeAnalysisFile $topN $topNInNativeFile $inNativeCompressFile`

echo -e "`printLogTime` blockCompressFile: $blockCompressFile"
echo -e "`printLogTime` inNativeCompressFile: $inNativeCompressFile"
#echo "`printLogTime` businessBlock: $businessBlock, businessInNative: $businessInNative"

maxBusinessBlock=`cat $blockCompressFile | grep "$businessClass" | grep -Eo "threadNo\[[0-9]+\]" | grep -Eo "[0-9]+" | awk 'BEGIN{max=0} {if($1>max) max=$1; fi} END{print max}'`
businessBlockNum=`cat $blockCompressFile | grep "$businessClass" | grep -Eo "threadNo\[[0-9]+\]" | grep -Eo "[0-9]+" | awk '{sum+=$1} END{print sum}'`
maxBusinessInNative=`cat $inNativeCompressFile | grep "$businessClass" | grep -Eo "threadNo\[[0-9]+\]" | grep -Eo "[0-9]+" | awk 'BEGIN{max=0} {if($1>max) max=$1; fi} END{print max}'`
businessInNativeNum=`cat $inNativeCompressFile | grep "$businessClass" | grep -Eo "threadNo\[[0-9]+\]" | grep -Eo "[0-9]+" | awk '{sum+=$1} END{print sum}'`

echo -e "`printLogTime` before[maxBusinessBlock:$maxBusinessBlock,businessBlockNum:$businessBlockNum,maxBusinessInNative:$maxBusinessInNative,businessInNativeNum:$businessInNativeNum]"
maxBusinessBlock=${maxBusinessBlock:-0}
businessBlockNum=${businessBlockNum:-0}
maxBusinessInNative=${maxBusinessInNative:-0}
businessInNativeNum=${businessInNativeNum:-0}
echo -e "`printLogTime` after[maxBusinessBlock:$maxBusinessBlock,businessBlockNum:$businessBlockNum,maxBusinessInNative:$maxBusinessInNative,businessInNativeNum:$businessInNativeNum]"

#计算告警阀值,比例
blockLimit=`awk 'BEGIN{printf "%.2f\n",('$businessBlockNum'/'$blockNum')}'`
inNativeLimit=`awk 'BEGIN{printf "%.2f\n",('$businessInNativeNum'/'$inNativeNum')}'`

echo "`printLogTime` blockLimit:$blockLimit,inNativeLimit:$inNativeLimit"
#1告警，0不告警
tmpLimit=$(echo "$blockLimit>$inNativeLimit" | bc)
[[ -n $tmpLimit ]] && {
	test "$tmpLimit" == "1" && tmpLimit=$blockLimit || tmpLimit=$inNativeLimit
	threadStackWarnFlag=$(echo "$tmpLimit>$threadThreshold" | bc)
}

test $threadStackWarnFlag -ne 0 && echo -e "`printLogTime WARN` BusinessThreadRate Tests Warning"

#计算百分比
blockPecent=`awk 'BEGIN{printf "%.2f%%\n",('$businessBlockNum'/'$blockNum')*100}'`
inNativePecent=`awk 'BEGIN{printf "%.2f%%\n",('$businessInNativeNum'/'$inNativeNum')*100}'`
totalCountInfo="${totalCountInfo}\n业务线程信息：
BLOCKED【最大业务线程数：${maxBusinessBlock}】【总业务线程数：${businessBlockNum}，占比：$blockPecent】
IN_NATIVE【最大业务线程数：${maxBusinessInNative}】【总业务线程数：${businessInNativeNum}，占比：$inNativePecent】
"
inNativeRateRes=$inNativePecent
inNativeRateFlag=$normalMsg
blockedRateRes=$blockPecent
blockedRateFlag=$normalMsg
[[ -n $inNativeLimit && `echo "$inNativeLimit>$threadThreshold" | bc` -eq 1 ]] && inNativeRateFlag=$errorMsg && warnFlag=1
[[ -n $blockLimit && `echo "$blockLimit>$threadThreshold" | bc` -eq 1 ]] && blockedRateFlag=$errorMsg && warnFlag=1
sed -i -e "s/inNativeRateRes/$inNativeRateRes/g" -e "s/inNativeRateFlag/$inNativeRateFlag/g" $mailModelFile 
sed -i -e "s/blockedRateRes/$blockedRateRes/g" -e "s/blockedRateFlag/$blockedRateFlag/g" $mailModelFile 

echo -e "`printLogTime` 获取死锁信息"
deadlockInfo=`sed -n '/^Deadlock/,/^Thread/p' $stackFile | grep -v "^Thread.*"`
deadLockRes="正常"
deadLockFlag=$normalMsg
[[ `echo -e "$deadlockInfo" | grep "No deadlocks found" | wc -l` -eq 0 ]] && {
	echo -e "`printLogTime WARN` Deadlock Tests Warning"
	deadLockRes="线程死锁"
	deadLockFlag=$errorMsg
	warnFlag=1
}
sed -i -e "s/deadLockRes/$deadLockRes/g" -e "s/deadLockFlag/$deadLockFlag/g" $mailModelFile

#合并stack信息
stackAnalysisFile=$targetDir/${stackAnalysisName}_$nowTime.txt
echo "${stackAnalysisFile}"
echo "`printLogTime` 导出文件信息："
echo "`printLogTime` BLOCKED分析结果: $blockAnalysisFile"
echo "`printLogTime` IN_NATIVE分析结果: $inNativeAnalysisFile"
echo "`printLogTime` 汇总分析结果: $stackAnalysisFile"
#================================ Stack Dump文件分析 end ==================================#

#================================= 资源类实例统计 start =====================================#
histoInfo=""
[[ -f $histoFile ]] && {
	pattern="(instances)"
	[[ -n $resourceClassName ]] && {
		pattern="${pattern}|`echo $resourceClassName | sed 's/,/)|(/g' | awk '{print "("$1")"}'`"
		echo -e "`printLogTime` pattern: $pattern"
		histoInfo="$histoInfo\n`cat $histoFile | grep -E "$pattern" | awk '{printf "%-15s%-15s%-15s\n",$2,$3,$4}'`"
		instanceNum=`cat $histoFile | grep -E "$pattern" | awk '{if(NR!=1) sum+=$2} END{print sum}'`
		test -z "$instanceNum" && instanceNum=0
		resourceInsFlag=$normalMsg
		[[ $instanceNum -ge $resourceInsNum ]] && {
			resourceInsFlag=$errorMsg
			warnFlag=1
			echo -e "`printLogTime WARN` Resources Tests Warning"
		}
		sed -i "s/resourceInsRes/$instanceNum/g" $mailModelFile	
		sed -i "s/resourceInsFlag/$resourceInsFlag/g" $mailModelFile
	}
} || {
	histoInfo="$histoInfo\n无"
	sed -i "s/resourceInsRes//g" $mailModelFile	
	sed -i "s/resourceInsFlag//g" $mailModelFile
}
#================================= 资源类实例统计 end =====================================#


#================================ 线程池监控 start =================================#
threadPoolInfo=""
threadPoolWarnFlag=0
#XXX历史日志
hisCsfLogFilePrefix="$appLogDir/$month/$processCode-$todayY_M_D"
#XXX当前日志
currentCsfLogFile="$appLogDir/$processCode.log"
echo -e "`printLogTime` 开始检查线程池"
[[ $threadPoolDebugEnable == "1" ]] && {
	[[ ! -f $currentCsfLogFile ]] && {
		threadPoolInfo="$threadPoolInfo\n正常"
	} || {
		logFile=`ls $hisCsfLogFilePrefix* | wc -l`
		[[ $logFile -gt 0 ]] && logFile="$hisCsfLogFilePrefix* $currentCsfLogFile" || logFile="$currentCsfLogFile"
		threadPoolInfoFile=$targetDir/threadPoolInfo.log
		grep -E "$threadPoolKV" $logFile > $threadPoolInfoFile
		errorNum=`cat $threadPoolInfoFile | wc -l`
		startTime=`cat $threadPoolInfoFile | head -1 | awk -F' ERROR| DEBUG' '{print $1}' | grep -o -E "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"`
		endTime=`cat $threadPoolInfoFile | tail -1 | awk -F' ERROR| DEBUG' '{print $1}' | grep -o -E "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"`
		rm $threadPoolInfoFile
	
		[[ $startTime = "" && $endTime = "" ]] && {
			threadPoolInfo="$threadPoolInfo\n当前线程池正常"
			echo -e "`printLogTime` 未检测到异常信息"
		} || {
			[[ $endTime != "" ]] && {
				eventEndTimeStamp=`date -d "$endTime" +%s`
				diff=$(($timestamp-$eventEndTimeStamp))
				#60分钟内未解决，则持续告警
				if [[ $diff -le $((60*60)) ]]; then
			 		threadPoolInfo="$threadPoolInfo\n警告！当前线程池异常！\n\n受影响请求数：$errorNum\n影响范围：[$startTime ~ $endTime]"
					warnFlag=1
					threadPoolWarnFlag=1
					echo -e "`printLogTime WARN` ThreadPool Tests Warning"
					#输出最近24小时情况
				elif [[ $diff -ge $((60*60)) && $diff -le $((24*60*60)) ]]; then
			 		threadPoolInfo="$threadPoolInfo\n当前线程池正常\n\n过去24小时情况：\n线程池满,受影响请求数：$errorNum\n影响范围：[$startTime ~ $endTime]"
				else
					threadPoolInfo="$threadPoolInfo\n当前线程池正常"
				fi
			}
		}
	}
	test "$threadPoolWarnFlag" -eq 1 && threadPoolRes="线程池满" || threadPoolRes="正常"
	test "$threadPoolWarnFlag" -eq 1 && threadPoolFlag=$errorMsg || threadPoolFlag=$normalMsg
}
sed -i -e "s/threadPoolRes/$threadPoolRes/g" -e "s/threadPoolFlag/$threadPoolFlag/g" $mailModelFile
echo -e "`printLogTime` 线程池检查完毕"
#================================== 线程池监控 end =================================#


#================================== XXX接口测试 start ==================================#
#默认连续调用5次，目前访问ctrl接口会被nginx拦截并可能分流到另外1台服务器上
redoCnt=5
startPos=1
csfApiDebugResult=""
csfApiDebugRes=""
csfApiDebugFlag=""
[[ $csfApiDebugEnable == "1" ]] && {
	echo "`printLogTime` 开始测试接口[$csfApi]"
	while [ $startPos -le $redoCnt ];
	do
		echo -e "`printLogTime` 第${startPos}次调用"
		response=`echo $csfParam | curl -X $csfMethod -H 'Content-type:application/json' $csfUrl -d @-`
		#接口调用超时情况
		timeoutNum=`echo $response | grep "调用超时" | wc -l`
		[[ $timeoutNum -gt 0 ]] && {
			echo "`printLogTime ERROR` 接口[$csfApi] 调用超时"
			errorInfo="接口[$csfApi] 调用超时"	
			csfApiDebugResult="$csfApiDebugResult\n$errorInfo"
			apiDebugWarnFlag="1"
			break
		}
		#线程池满情况，模拟外部调用
		threadPoolErrorNum=`echo $response | grep "服务端请求处理线程池已满" | wc -l`
		[[ $threadPoolErrorNum -gt 0 ]] && {
			echo "`printLogTime ERROR` 接口[$csfApi]请求被拒绝，服务端请求处理线程池已满"
			errorInfo="接口[$csfApi]请求被拒绝，服务端请求处理线程池已满"	
			csfApiDebugResult="$csfApiDebugResult\n$errorInfo"
			apiDebugWarnFlag="1"
			break
		}
		#接口不通情况
		connectRefusedNum=`echo $response | grep "Connection refused" | wc -l`
		[[ $connectRefusedNum -gt 0 ]] && {
			echo "`printLogTime ERROR` 接口[$csfApi] Connection refused" 
			errorInfo="接口[$csfApi] Connection refused"
			csfApiDebugResult="$csfApiDebugResult\n$errorInfo"
			apiDebugWarnFlag="1"
			break
		}
		startPos=$(($startPos+1))
	done
	[[ $apiDebugWarnFlag == 0 ]] && {
		echo -e "`printLogTime` 接口[$csfApi] 测试正常"
		csfApiDebugResult="$csfApiDebugResult\n\n接口[$csfApi] 测试正常"
		csfApiDebugRes="正常"
		csfApiDebugFlag=$normalMsg
	} || {
		echo -e "`printLogTime WARN` CsfApi Tests Warning"
		csfApiDebugRes="$errorInfo"
		csfApiDebugFlag=$errorMsg
		warnFlag=1
	}
	echo "`printLogTime` 接口测试完毕"
}
sed -i -e "s/csfApiDebugRes/$csfApiDebugRes/g" -e "s/csfApiDebugFlag/$csfApiDebugFlag/g" $mailModelFile
#================================= XXX接口测试 end ==================================#

#主机信息
hostInfo="当前主机：`hostname -f | awk -F'.' '{print $1}'`\n\n应用启动时间：$lstart\n应用运行时长：$etime\n"

#主机存储空间
hostSpace=`df -h`

#应用日志占用空间
appLogUsage=`du -a -b --max-depth=1 $appLogDir | sort -nrk1 | awk -F' ' '{if($1>(1024*1024*1024)) {printf "%.2fG\t%s\n",$1/(1024*1024*1024),$2} else{printf "%.2fM\t%s\n",$1/(1024*1024),$2}}'`

#内存使用情况
heapUsage=`free -h`

#========================生成分析报告=========================#
#主机监控信息
hostMonitor="---------------------------主机监控信息---------------------------"
hostMonitor="$hostMonitor\n存储空间:\n$hostSpace\n\n应用日志占用空间:\n$appLogUsage\n\n内存使用情况:\n$heapUsage"

#JVM heap信息
[[ -f $heapFile ]] && {
	heapInfo="---------------------------JVM Heap Usage-----------------------------`cat $heapFile`"
}
#JVM GC信息
[[ $gcutilFile != "" ]] && {
	OG=`echo -e "$gcutilFile" | awk '{if(NR!=1) print $4}'`	
	PG=`echo -e "$gcutilFile" | awk '{if(NR!=1) print $5}'`
	OGRateRes="$OG%"
	PGRateRes="$PG%"
	OGRateFlag=$normalMsg
	PGRateFlag=$normalMsg
	OGFlag=`echo "$OG>($OGThreshold*100)" | bc`
	PGFlag=`echo "$PG>($PGThreshold*100)" | bc`
	sed -i -e "s/OGRateRes/$OGRateRes/g" -e "s/PGRateRes/$PGRateRes/g" $mailModelFile
	[ $OGFlag -eq 1 -o $PGFlag -eq 1 ] && echo -e "`printLogTime WARN` JVMHeapRate Tests Warning"
	test $OGFlag -eq 1 && OGRateFlag=$errorMsg && warnFlag=1
	test $PGFlag -eq 1 && PGRateFlag=$errorMsg && warnFlag=1
	sed -i "s/OGRateFlag/$OGRateFlag/g" $mailModelFile
	sed -i "s/PGRateFlag/$PGRateFlag/g" $mailModelFile
	gcutilFile="---------------------------JVM GC-----------------------------\n$gcutilFile"
}
#Top监控
[[ $topInfo != "" ]] && {
	topInfo="--------------------------top Monitor----------------------------\n$topInfo"
}
#CPU占用前十的线程信息
[[ $topNCpuUsageThread != "" ]] && {
	topNCpuUsageThread="----------------------Top 10 Cpu Usage Thread------------------------\n$topNCpuUsageThread"
}

threadPoolInfo="------------线程池监控结果（异常需告警）------------$threadPoolInfo"
totalCountInfo="------------线程汇总 (任一[总业务线程占比]超过70%需告警)------------$totalCountInfo"
deadlockInfo="------------线程死锁情况（死锁需告警）------------\n$deadlockInfo"
csfApiDebugResult="------------XXX接口调用测试结果(异常需告警)------------$csfApiDebugResult"
histoInfo="------------资源类实例信息（instances较大时资源可能未被释放）------------$histoInfo"

commonInfo="$hostInfo\n$threadPoolInfo\n\n$totalCountInfo\n$deadlockInfo\n\n$csfApiDebugResult\n\n$histoInfo
\n\n\n注：运维人员只需关注以上部分，以下不需要关注
$hostMonitor\n\n$topInfo\n\n$topNCpuUsageThread\n\n$heapInfo\n\n$gcutilFile\n\n"

#分析结果附件
echo -e "$commonInfo-------------------------BLOCKED STACK----------------------------
`cat $blockAnalysisFile`
\n\n-------------------------IN_NATIVE STACK--------------------------
`cat $inNativeAnalysisFile`" >> $stackAnalysisFile

#邮件stack信息取TOPN
echo -e "$commonInfo-------------------------Top${topN} BLOCKED STACK----------------------------
`cat $topNBlockFile`
\n\n-------------------------Top${topN} IN_NATIVE STACK--------------------------
`cat $topNInNativeFile`" >> $mailContentFile

echo "`printLogTime` 邮件内容文件路径: $mailContentFile"


#========================邮件告警 start========================#
#压缩文件包含文件
compressArr=($stackFile $jstackLFile $histoFile $lsofFile $netstatFile)
#邮件附件路径
jstackCompressFile="$targetDir/$compressAttachmentName"
jstackDir="$targetDir/jstackDump"
test -f "$jstackCompressFile" && rm $jstackCompressFile
test -d "$jstackDir" && rm -rf $jstackDir/* || mkdir -p $jstackDir

echo -e "`printLogTime` 压缩文件列表[${compressArr[*]}]"
[[ ${#compressArr[*]} -gt 0 ]] && {
	for file in ${compressArr[*]}
	do
		test -f "$file" && cp $file $jstackDir
	done
}
#压缩stack dump文件
echo -e "`printLogTime` 压缩邮件附件"
tar zcvf $jstackCompressFile -C `dirname $jstackDir` `basename $jstackDir`

#邮件附件
attachment=""
[[ $isSendAttachment == 1 ]] && {
	test "$mailType" == "mail" && attachment="-a $stackAnalysisFile -a $jstackCompressFile" || attachment="$stackAnalysisFile $jstackCompressFile"
	echo -e "`printLogTime` 附件信息[$stackAnalysisFile,$jstackCompressFile]"
}

echo "`printLogTime` 是否发送邮件: $isSendMail,$attachment"
#发送邮件
[[ $isSendMail == "1" ]] && {
	timerHourFlag="0"
	hourStr=`date +"%H%M"`
	for line in `echo -e "${varMap["timerHour"]}" | sed "s/,/\n/g"`	
	do
		[[ $hourStr == "${line}" || $hourStr == "${line}00" || $hourStr == "0${line}00" ]] && timerHourFlag="1"
	done
	[[ $timerHourFlag == "1" || $isSendMailByThreshold == "0" || ( $isSendMailByThreshold == "1" && $warnFlag == "1" ) ]] && {
		sendEmail "$subject" "$from" "$to" "$cc" "$attachment" "$mailModelFile"
	}
}
#========================邮件告警 start========================#


#========================清理临时文件=========================#
echo -e "`printLogTime` 清理临时文件[\n$tmpFile\n$mailContentFile\n$topNBlockFile\n$topNInNativeFile\n$jstackCompressFile\n$jstackDir]"
rm $tmpFile
#rm $mailContentFile
rm $topNBlockFile
rm $topNInNativeFile
rm $jstackCompressFile
rm $jstackDir/*
echo -e "`printLogTime` 文件清理完毕"

#清理当前进程的子进程(防止jps,jmap,jstat等无法退出导致占用大量资源问题)
echo "curProcId: $$"
ps -ef | grep $$ | grep -v grep
childProc=`ps -ef | grep $$ | grep -v grep | awk -vcurProcId=$$ '{if($3==curProcId){print $2}}'`
echo -e "$childProc" | xargs kill
echo -e "kill Java Process..."
$JAVA_HOME/jps | grep -E "JMap|JStack" | awk '{print $1}' | xargs kill
