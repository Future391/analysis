#!/bin/bash
dir="/data/app/analysis/analysis"
[[ $# -eq 0 ]] && exit
today=`date +%Y%m%d`
echo "today: $today"
oldTime=`date -d "2 months ago" +"%Y%m%d"`
for dir in $*
do
	[[ ! -d $dir ]] && echo -e "目录[$dir]不存在!" && continue
	oldFile="$dir/${oldTime}.tgz"
	for file in $(ls $dir)
	do
		[[ -d $dir/$file && $file != "$today" ]] && {
			echo "dir: $file"
			tar zcvf ${dir}/${file}.tgz -C $dir $file
			rm -r $dir/$file
		}
	done
	[[ -f $oldFile ]] && rm $oldFile
done
