#! /bin/bash
starttime=`date +'%Y-%m-%d %H:%M:%S'`
#一般只修改KD,KERNEL值就可以了，其他几乎可不动。
export KD=instantnoodle_defconfig
#export KD=vendor/xxxxx_defconfig
export KERNEL=Image.gz

echo "           "
echo "           "
echo "你设置的内核配置文件为$KD,并打印在kernel-defconfig.log"
echo "           "
echo "           "



#一些解释，必看。
#可在终端中直接指定KD，export KD=xxxxx_defconfig 或export KD=vendor/xxxxx_defconfig然后直接运行此脚本即可编译内核，而不必每次都来修改KD值，特别是想要用多个编译器编译时，省掉些麻烦。当然来直接修改也可以。

#手机的内核配置文件(内核配置文件KERNEL_DEFCONFIG简称KD），一般在内核源码目录下的arch/arm64/configs或arch/arm64/configs/vendor下，一般为机型代号，高通骁龙处理器代号啥的，比如mi5 的为gemini_defconfig,一加8系列为kona_pref_defconfig,按实际情况修改
#KD可取的值(内核配置文件KERNEL_DEFCONFIG简称KD） xxxxx_defconfig, vendor/xxxxx_defconfig

#export KD=xxxxx_defconfig
#export KD=vendor/xxxxx_defconfig


#内核产品的格式类型通常为Image或 Image.gz-dtb，Image.gz等，默认Image
#export KERNEL=Image


echo "           "
echo "设置编译环境中....."
echo "           "
#env 设置编译环境

export ARCH=arm64
export SUBARCH=arm64
export PATH="/root/Toolchain/clang+llvm-19.1.5-aarch64-linux-gnu/bin:/root/Toolchain/electron-binutils-2.40/bin:$PATH"

args="-j4 \
ARCH=arm64 \
SUBARCH=arm64 \
O=out \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
CLANG_TRIPLE=aarch64-linux-gnu- "


args2="-j6 LD=ld.lld AR=llvm-ar NM=llvm-nm STRIP=llvm-strip OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf ARCH=arm64 SUBARCH=arm64 O=out"

echo "           "
echo "编译环境清理中....."
echo "           "
#clean，环境清理
#make clean && make mrproper
rm kernel.log kernel-defconfig.log && rm -rf out 
mkdir -p out

#基本配置信息
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "-------------------打印编译器信息--------------------"
clang -v

aarch64-linux-gnu-ld -v
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"



echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> ./kernel-defconfig.log 
echo "时间_`date +'%Y-%m-%d %H:%M:%S'`----内核配置为_$KD----编译器环境变量配置为_$PATH" >> ./kernel-defconfig.log
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> ./kernel-defconfig.log

echo "           "
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "开始构建内核.....时间为_`date +'%Y-%m-%d %H:%M:%S'`----内核配置为_$KD----编译器配置为_$PATH"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "           "
#build 构建内核
#内核将在 out/arch/arm64/boot下生成通常为Image,Image.gz.dtb,Image.gz等
make CC="ccache clang" ${args2} ${KD}
make CC="ccache clang" ${args2} 2>&1 | tee kernel.log


#预先清理一下/root/Toolchain/AnyKernel3/可能遗留的文件，防止打包混乱。
rm -rf /root/Toolchain/AnyKernel3/*.zip /root/Toolchain/AnyKernel3/Image /root/Toolchain/AnyKernel3/dtb /root/Toolchain/AnyKernel3/Image.gz /root/Toolchain/AnyKernel3/dtbo.img 


# 打包内核，用AnyKernel3进行打包,最终内核成品在 /mnt目录下,名称为 kernel+日期的zip包，可通过twrp或ex内核管理器刷入，验证。
if [ -f ./out/arch/${ARCH}/boot/${KERNEL} ]
	then
		cp -rf ./out/arch/${ARCH}/boot/${KERNEL} /root/Toolchain/AnyKernel3
		cp -rf ./out/arch/${ARCH}/boot/dtbo.img /root/Toolchain/AnyKernel3
		cp -rf ./out/arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb  /root/Toolchain/AnyKernel3/dtb
		cd /root/Toolchain/AnyKernel3 ;
		zip -r Kernel-op8-ksu_lxc-h2OS-R-`date '+%Y%m%d%H%M'`.zip  . ;
		mv *.zip /mnt ;
		rm ${KERNEL} ;
		echo "           "
		echo "           "
		echo "build kernel success, the kernel products is /mnt"
		echo "构建内核成功，内核产品在/mnt目录下，名称为 kernel+日期形式的zip包，可通过twrp或ex内核管理器刷入，验证"
		echo "           "
		echo "           "
	else
	        echo "           "
	        echo "           "
	        echo "build kernel failed ,please check the kernel.log"
		echo "构建内核失败，请检查kernel.log"
	fi


#耗时统计
echo "           "
echo "--------------------------------"
endtime=`date +'%Y-%m-%d %H:%M:%S'`
start_seconds=$(date --date=" $starttime" +%s);
end_seconds=$(date --date="$endtime" +%s);
echo Start: $starttime.
echo End: $endtime.
echo "Build Time: "$((end_seconds-start_seconds))"s."
echo "--------------------------------"
