#!/bin/bash
baseline_execv=./bin/csmli_mac
test_execv=./mLisp
#make clean
make $test_execv
echo 'baseline test' > ./base.dat
echo 'baseline test' > ./test.dat
for file in ./test_data/[0-9]* ./test_data/b[1-2]*; do
    echo $file
    $baseline_execv $file 1>>./base.dat
    $test_execv < $file 2>/dev/null 1>>./test.dat
done
diff base.dat test.dat
