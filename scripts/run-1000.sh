#!/bin/bash

# Usage:
# for file in data/wmt16*.*-*.csv); do
#   qsub script/run-1000.sh $file ts
# done

#$ -S /bin/bash -V -cwd
#$ -j y -o log
#$ -l h_rt=0:10:00
#$ -t 1:1000

. ~/.bashrc
basedir=/export/projects/mpost/wmt16/eval/wmt16

export PYTHONPATH=.:$PYTHONPATH:$basedir/wmt-trueskill/src/trueskill

set -u

file=$1
model=$2
lang=$(echo $file | cut -d. -f2)

date=$(date +%m%d)

dir=results/$date/$lang/$model/$SGE_TASK_ID
[[ ! -d "$dir" ]] && mkdir -p "$dir"

if [[ $model = "ts" ]]; then
    cat $file | $basedir/scripts/sample-with-replacement | $basedir/wmt-trueskill/src/infer_TS.py -n 2 -d 0 -s 2 $dir/wmt16
elif [[ $model = "ew" ]]; then
    cat $file | $basedir//wmt-trueskill/src/infer_EW.py -p 1.0 -s 2 $dir/wmt16
elif [[ $model = "hm" ]]; then
    echo "not implemented"
#    cat data/wmt15.$lang.csv | ./wmt-trueskill/src/infer_HM.py -p 1.0 -s 2 t $dir/wmt15
fi
