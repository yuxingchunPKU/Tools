# !/bin/bash

# 该脚本是搜集指定步的时间信息
# 输入参数 1 2 3 分别是开始步 终止步 和 步长
start=${1};
end=${2};
stepsize=${3};

touch Time
blankstr="\n"
for((i=$start;i<$end+1;i=i+$stepsize))
do
    sed -n "1,1p" $i/current_time >>Time
    echo -e >> Time
    # sed -n "1,1p"  blank>>Time   
done