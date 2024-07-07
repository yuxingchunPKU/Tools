# !/bin/bash

# 对于两介质流体的数据处理 
# 并行程序
# 输入参数1 2 3  4 分别是起始 终止 步长 和 进程数
# 输入程序：
#   1. 水平集函数
#	lsX_Y.dx  X是0或1；表示当前步和上一步的水平集函数 Y 是进程号 从0到进程数-1
#   2. 各相守恒量 守恒量分别是 E rho rho_u rho_v （能量 密度 和动量）
#	守恒量_X_Y.dx X是0或1；表示第0相或第1相 Y 是进程号 从0到进程数-1
#
# 输出在各步目录下 包括行号 和 节点 网格 和 函数值 数据，后者后缀是txt
# 输出程序：
#	1. RawNumber_Y 各个进程的行号
#	2. 守恒量_X_Y.txt
#   3. node_Y.txt mesh_Y.txt 网格和节点信息

# 程序的思路如下 
# 1. dx程序的文字中特有的单词 object 通过grep -n 搜索得到行号；
# 2. dx 格式文件的数据如下 1. 非结构网格顶点的坐标 2.网格的信息 3.顶点的值或者是面上的值;
# 3. 创建两个临时文件，用来存放grep的结果，然后通过cut -f 分词,获取单纯的行号，存放在RawNumber文件下;
# 4. 通过sed 读取RawNumber内容 分解记作 raw0 raw1 raw1;
# 5. 选择水平集函数 分割前两部分 获得 node.txt 和 mesh.txt 文件；
# 6. 获取 水平集函数 和各相守恒量的值： 1. 通过wc 读出文件的行数 2. 通过数学运算 获得 raw2+1 到 总行数-7 并分别命名保存。
# 7. 对核心多做一次循环

start=${1};
end=${2};
stepsize=${3};
process=${4};
# start:stepsize:end
for((i=${start};i<${end}+1;i=i+${stepsize}))
do
    for((j=0;j<${process};j=j+1))
    do
            # 3. 创建两个临时文件，用来存放grep的结果，然后通过cut -f 分词,获取单纯的行号，存放在RawNumber文件下;
            mktemp -q $i/testfile1.XXXX
            mktemp -q $i/testfile2.XXXX
            grep -rn object $i/ls0_${j}.dx > $i/testfile1.XXXX
            cut -d":" -f1 $i/testfile1.XXXX > $i/testfile2.XXXX
            # 用完删掉
            mv $i/testfile2.XXXX $i/RawNumber_${j}
            rm -f $i/tes*
            # 4. 通过sed 读取RawNumber内容 分解记作 raw0 raw1 raw1;
            raw0=`sed -n '1,1p' $i/RawNumber_${j}`
            raw1=`sed -n '2,2p' $i/RawNumber_${j}`
            raw2=`sed -n '3,3p' $i/RawNumber_${j}`
            # 5. 选择水平集函数 分割前两部分 获得 node.txt 和 mesh.txt 文件；
            # 这里空格必不可少 expr后面的空格
            sed -n "`expr ${raw0} + 1`,`expr ${raw1} - 1`p" $i/ls0_${j}.dx >$i/node_${j}.txt
            sed -n "`expr ${raw1} + 1`,`expr ${raw2} - 4`p" $i/ls0_${j}.dx >$i/mesh_${j}.txt
            
            # 6. 获取 水平集函数 和各相守恒量的值： 1. 通过wc 读出文件的行数 2. 通过数学运算 获得 raw2+1 到 总行数-7 并分别命名保存。
            # 各相流体守恒量
            wc -l $i/E_0_${j}.dx > $i/tempfile
            lastlineNum=`cut -d" " -f1 $i/tempfile`
            for((k=0;k<2;k=k+1))
            do
                sed -n "`expr ${raw2} + 1`,`expr ${lastlineNum} - 7`p" $i/E_${k}_${j}.dx >$i/E_${k}_${j}.txt
                sed -n "`expr ${raw2} + 1`,`expr ${lastlineNum} - 7`p" $i/rho_${k}_${j}.dx >$i/rho_${k}_${j}.txt
                sed -n "`expr ${raw2} + 1`,`expr ${lastlineNum} - 7`p" $i/rho_u_${k}_${j}.dx >$i/rho_u_${k}_${j}.txt
                sed -n "`expr ${raw2} + 1`,`expr ${lastlineNum} - 7`p" $i/rho_v_${k}_${j}.dx >$i/rho_v_${k}_${j}.txt
            done
            # 水平集函数需要单独处理 对tempfile 重载了
            wc -l $i/ls0_${j}.dx > $i/tempfile
            lastlineNum=`cut -d" " -f1 $i/tempfile`

            sed -n "`expr ${raw2} + 1`,`expr ${lastlineNum} - 7`p" $i/ls0_${j}.dx >$i/ls0_${j}.txt
            sed -n "`expr ${raw2} + 1`,`expr ${lastlineNum} - 7`p" $i/ls1_${j}.dx >$i/ls1_${j}.txt
            # 用完删除
            rm -f $i/tempfile
    done
done
