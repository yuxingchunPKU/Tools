# !/bin/bash

start=0;
end=0;
stepsize=1;

touch Time
blankstr="\n"
for((i=$start;i<$end+1;i=i+$stepsize))
do
    sed -n "1,1p" $i/current_time >>Time
    echo -e >> Time
    # sed -n "1,1p"  blank>>Time   
done