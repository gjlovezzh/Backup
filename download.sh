#嘎嘎嘎嘎嘎
#【功能】
#自动遍历下载monk-coder的js文件
#会自动把新增文件拷贝到own/monkcoder_dust目录
#会按照MD5比对后更新，不会每次全部覆盖
#E大V4会自动按照文件加入到定时任务里
#目前不会删除过期脚本，自己手动删吧
#由于monk-coder是转链的谷歌盘,连接不稳定，网络原因有时候会下载错误或者连接异常，我已尽可能的排错了，错误文件将不会替换到更新目录内！
#【使用说明】
#1.把download.sh复制到容器内的/jd/config下面
#2.给download.sh运行权限，执行指令：chmod 644 download.sh
#3.config.sh Own库地方加入如下配置,当然是不能更新的，目的是让V4脚本脚本自动添加删除定时任务
#  OwnRepoUrl1="git@monk_github:monkcoder/dust.git" 
#  OwnRepoBranch1=""
#  OwnRepoPath1=""
#  AutoAddOwnCron="true"
#  AutoDelOwnCron="true"
#4.以后都设置好后先手动执行一次download.sh，如果没问题的话就会自动运行jup添加定时任务
#  容器外面用这条运行脚本 docker exec -it jd bash /jd/config/download.sh
#  容器内用这条运行脚本 bash $JD_DIR/config/download.sh
#5.没必要加入diy脚本里面，容器定时列表加入如下定时任务，库更新频率不会很高，建议几个小时执行一次，减少服务器压力
#  35 0-23/8 * * * bash $JD_DIR/config/download.sh

#!/usr/bin/env bash
downpath=download
monkpath=monkcoder_dust


function monkcoder()
{
	#创建download文件夹
	if [[ ! -d $downpath ]]; then
	mkdir $downpath
	fi
	#创建monk_coder文件夹
	if [[ ! -d $monkpath ]]; then
	mkdir $monkpath
	fi
	
	default_root_id="$(curl -s https://share.r2ray.com/dust/ | grep -oE "default_root_id[^,]*" | cut -d\' -f2)"
	folders="$(curl -sX POST "https://share.r2ray.com/dust/?rootId=${default_root_id}" | grep -oP "name.*?\.folder" | cut -d, -f1 | cut -d\" -f3 | grep -v "pics" | tr "\n" " ")"
	test -z "$folders" && return 0 || rm -rf $downpath/*
	for folder in $folders; do
	    jsnames="$(curl -sX POST "https://share.r2ray.com/dust/${folder}/?rootId=${default_root_id}" | grep -oP "name.*?\.js\"" | grep -oE "[^\"]*\.js\"" | cut -d\" -f1 | tr "\n" " ")"
	    for jsname in $jsnames; do 
	        curl -s --remote-name "https://share.r2ray.com/dust/${folder}/${jsname}" 
             mv $jsname $downpath/
             #获取下载文件大小，空文件内容是null大小是4
	        FileSize=$(stat --format=%s $downpath/$jsname)
	        #echo -e "FileSize:"$FileSize
             if [[ $FileSize != "4" ]]; then
               #连接错误后会把错误提示页面下载成Js文件，捕获错误页面内容并排除
               grep "What happened?" $downpath/$jsname >> /dev/null
		     if [ $? -ne 0 ]; then
		        #echo -e "已下载["$folder"]目录中的["$jsname"]文件."
		        #sleep 1 #等待1s下一个文件
		        #判断是否新增脚本
			   if [ ! -f "$monkpath/$jsname" ];then
			     cp $downpath/$jsname $monkpath/
				echo -e "新增加文件"$jsname
			   else
			     md5download=$(md5sum $downpath/$jsname|cut -d ' ' -f1)
			     md5monkcoder=$(md5sum $monkpath/$jsname|cut -d ' ' -f1)
			     #echo -e "md5download_"$jsname":"$md5download
			     #echo -e "md5monkcode_"$jsname":"$md5monkcoder
			     #判断已存在的脚本是否更新了内容
		          if [[ $md5download != $md5monkcoder ]]; then
		             yes|cp -rf $downpath/$jsname $monkpath/
		             echo -e "更新文件"$jsname
		          fi
			   fi
		     else
		       echo -e $jsname"下载地址错误,页面404！！！"
		     fi 
             else
                echo -e $jsname"文件下载为null,不进行文件替换！！！"
             fi
	    done
	done
	#echo -e "全部下载完成, 脚本下载目录:"$downpath", 脚本更新目录:"$monkpath
}

function main()
{
    monkcoder
}

main
