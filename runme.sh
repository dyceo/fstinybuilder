ldflags="./imfs/lib"
outputdir=`pwd`/imfs/
everyreset='n'
[ -e imfs ] || mkdir imfs imfs/bin imfs/lib imfs/etc imfs/usr imfs/dev imfs/sys imfs/media 


#根据文件类型自动填充解压参数
rptar(){
	fileinfo=`file $1`
	echo "finfo=${fileinfo}"
	ftype=(`echo ${fileinfo}`)
	echo "ftyp=${ftype[1]}"
	if [ ${ftype[1]} == "gzip" ];then
		tar xzvf $@
	return 0
	fi
	if [ ${ftype[1]} == "bzip" ];then
		tar xjvf $@
	return 0
	fi
	if [ ${ftype[1]} == "XZ" ];then
		tar xJvf $@
	return 0
	fi
	echo "尚未支持的压缩格式"
	return -1
}

#按文件系统的数据格式 组织数据到数据块
fstinypack(){
	echo "-------------尝试将文件夹打包为文件系统--------------------"
	mkfs.jffs2 -d ${outputdir} -l -e 0x10000 -o ../rootfs.jffs2
	echo "-------------打包为文件系统命令正常退出--------------------"
}

#下载 解压 编译主体逻辑
fstinybuilder(){
#获取下载设置文件
i=${#packlist[@]}
((i--))
while [ $i -ge 0 ];do	
	t=(`echo ${packlist[i]}`)
	echo "------------程序名称:${t[0]}---------------"
	if [ ! -e ${t[3]} ];then
	echo "-------------尝试下载----------------------"
		${t[1]} ${t[2]}${t[3]}
		if [ $? -ne 0 ];then
		echo "----${t[0]}下载失败 尝试重新下载----"
		sleep 3
		continue
		fi 
	else
	echo "---------已经下载过了跳过下载步骤-----------"
	fi
	echo "------------------------------------------"
	
	if [ ! -e ${t[0]} ];then
	echo "---------尝试解压${t[3]}到${t[0]}----------"
	cp ${t[3]} sbtar
	rptar ./sbtar 
	rm sbtar
	else
	echo "---------已经解压过了跳过解压步骤-----------"
	fi
	echo "-------------------------------------------"
	
	echo "---------尝试编译${t[0]}--------------------"
	echo "---------进入${t[0]}目录--------------------"
	cd ${t[0]}
	if [ $? -ne 0 ];then
	echo "---------进入${t[0]}失败 编译终止-----------"
	break
	fi
		
	if [ -e ./bootstrap ];then
	echo "---------发现bootstrap文件-----------------"
		if [ ! -e Makefile ];then
			echo "--------初次编译尝试生成configure文件-----"
			./bootstrap
		else
				if [ $everyreset == 'y' ];then
					echo "-----everyreset=y 重新生成configure文件-----"
					./bootstrap			
					else
					echo "----Makefile文件已经存在且everyreset=n跳过----"
				fi	
		fi		 
	else
	echo "------------未发现bootstrap文件跳过-------------"
	fi
	
	if [ -e ./configure ];then
	echo "---------发现configure文件-------------------"
		if [ ! -e Makefile ];then
			echo "--------初次编译尝试生成configure文件-----"
			./configure --host=${hostname} LDFLAGS=-L${ldflags} --prefix=${outputdir} CC=${CROSS_COMPILE}gcc CXX=${CROSS_COMPILE}g++		 	
		else
			if [ $everyreset == 'y' ];then
				echo "-----everyreset=y 重新生成Makefile文件-----"
				./configure --host=${hostname} LDFLAGS=-L${ldflags} --prefix=${outputdir} CC=${CROSS_COMPILE}gcc CXX=${CROSS_COMPILE}g++
			fi
		fi	
	else
	echo "------------未发现configure文件跳过-------------"
	fi
	
	echo "-----------开始编译${t[0]}-------------------"
	make && make install
	
	echo "-----------${t[0]}编译结束-------------------"
	
	
	((i--))
done
fstinypack
}
fstinybuilder


