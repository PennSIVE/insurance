#!/bin/bash

cd $(dirname $0)/.. # this script is in ./code
export DSLOCKFILE=$PWD/.git/datalad_lock
touch $DSLOCKFILE
for sub in $(ls nifti | grep sub | grep -Eo "[0-9]+"); do
    qsub -V -cwd -b y -l h_vmem=20G -o logs/$sub -e logs/$sub ./code/process_subject.sh $sub
done


