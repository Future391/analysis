#!/bin/bash
#v1.1
#author Pengxb 
#Date 2019/08/22 
#注意：目前脚本仅支持jstack -F格式dump信息

dir=$(cd `dirname $0`;pwd)
jstackFile=""
outFile=""
topN=-1
topNFile=""
compressFile=""
if [ $# -ge 2 -a $# -le 5 ]; then
	jstackFile=$1
	[[ ! -f $jstackFile ]] && echo "文件[$jstackFile]不存在!" && exit
	outFile=$2
	[[ $# -eq 4 ]] && {
		topN=$3
		topNFile=$4
	}
	[[ $# -eq 5 ]] && {
		topN=$3
		topNFile=$4
		compressFile=$5
	}
else
	echo "请输入正确参数！"
	exit
fi

#缓存栈信息
buffer=""
threadNo=""
lastThreadNo=""

#pattern
p1="^Thread .*state.*"
p2="^\- .*"

#数组，存储栈信息
arr1=()
arr2=()

#Function
function getIndexByValue()
{
	local result=-1
	local val=$1
	local len=${#arr1[@]}
	for((i=0;i<$len;i++))
	do
		[[ ${arr1[$i]} == "${val}" ]] && result=$i && break
	done
	echo $result
}

#排序
function selfSort()
{
	local len=${#arr2[*]}
	for((i=0;i<$len-1;i++))
	do
		for((j=0;j<$len-$i-1;j++))
			do
			z=$(($j+1))
			a=${arr2[$j]}
			b=${arr2[$z]}
			c=${a//,/}
			d=${b//,/}
			l1=$((${#a}-${#c}))
			l2=$((${#b}-${#d}))
			#echo "==$l1 $l2=="
			if [ $l1 -le $l2 ]; then
				#交换线程ID信息
				tmp=${arr2[$j]}
				arr2[$j]=${arr2[$z]}
				arr2[$z]=$tmp
				#交换线程statck信息
				temp=${arr1[$j]}
				arr1[$j]=${arr1[$z]}
				arr1[$z]=$temp
			fi
		done
	done
}

#Main
while read line
do
	if [[ $line =~ $p1 ]]; then
		threadNo=`echo $line | awk -F':' '{print $1}' | awk -F' ' '{print $2}'`
		if [ "$lastThreadNo" != "" ]; then
			if [ "$buffer" = "" ]; then
				buffer="null"
			fi
			idx=`getIndexByValue "$buffer"`
			#echo -e "buffer: $buffer，\nidx: $idx"
			if [ $idx = "-1" ]; then
				idx=${#arr1[@]}
				#idx=$(($size+1))
				var=""
			else
				var=${arr2[$idx]}
			fi
			if [ "$var" != "" ]; then
				var="$lastThreadNo,$var"
			else
				var="$lastThreadNo"
			fi
			arr1[$idx]="$buffer"
			arr2[$idx]="$var"
			#echo -e "key: $buffer, \nvalue:$var" 
		fi
		lastThreadNo=$threadNo
		buffer=""
	    elif [ "$line" != "HELLOWORLD" ] && [[ "$line" =~ $p2 ]]; then
	    	if [ "buffer" != "" ]; then
	    		buffer="$buffer\n$line"
	    	else
	    		buffer="$line"
	    	fi
	    fi
done < $jstackFile

[[ -n $lastThreadNo ]] && {
	[[ -z $buffer ]] && buffer="null"
	idx=`getIndexByValue "$buffer"`
	[[ $idx = "-1" ]] && {
		idx=${#arr1[@]}
		var=""
	} || {
		var=${arr2[$idx]}
	}
	[[ -n $var ]] && var="$lastThreadNo,$var" || var="$lastThreadNo"
	arr1[$idx]="$buffer"
	arr2[$idx]="$var"
	#echo -e "key: $buffer, \nvalue:$var" 
}
echo -e "stack组数: ${#arr2[*]}\n" >> $outFile
echo -e "stack组数: ${#arr2[*]}\n" >> $topNFile

#排序
selfSort

#记录最大业务线程数
businessNum=0
businessSum=0

[[ ${#arr1[*]} -lt $topN ]] && topN=${#arr1[*]}

for((i=0;i<${#arr1[*]};i++))
do
	threads=${arr2[$i]}
	threadRemove=${threads//,/}
	threadNo=$((${#threads}-${#threadRemove}+1))
	num=`echo "${arr1[$i]}" | grep "com.ai" | wc -l`
	[[ $num -gt 0 ]] && {
		[ $threadNo -gt $businessNum ] && businessNum=$threadNo
		businessSum=$(($businessSum+$threadNo))
	}
	#打印线程分组信息，当存在大量业务线程时阻塞时，需及时告警
	echo -e "序号: $(($i+1)), 线程数: ${threadNo}，线程ID[${arr2[$i]}] \nStack: ${arr1[$i]}\n" >> $outFile
	#取TOPN
	[[ $topN -gt -1 && $i -lt $topN ]] && echo -e "序号: $(($i+1)), 线程数: ${threadNo}，线程ID[${arr2[$i]}] \nStack: ${arr1[$i]}\n" >> $topNFile
	echo "seq[$(($i+1))],threadNo[${threadNo}],threadId[${arr2[$i]}],\nStack: ${arr1[$i]}" | sed 's/\\n/A@A/g' >> $compressFile
done
echo "$businessNum,$businessSum"
