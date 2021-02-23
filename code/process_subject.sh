#!/bin/bash

# fail whenever something is fishy, use -x to get verbose logfiles
set -e -u -x

cd $(dirname $0)/..
ds_path=$PWD
sub=$1
# $TMPDIR is a more performant local filesystem
wrkDir=$TMPDIR/$JOB_ID
mkdir -p $wrkDir
cd $wrkDir
# get the output/input datasets
# flock makes sure that this does not interfere with another job
# finishing at the same time, and pushing its results back
# we clone from the location that we want to push the results too
flock $DSLOCKFILE datalad clone $ds_path ds
# all following actions are performed in the context of the superdataset
cd ds
# obtain datasets
datalad get -r nifti/sub-${sub}
datalad get -r nifti/derivatives/sub-${sub}
datalad get -r mimosa_models
datalad get -r simg
# let git-annex know that we do not want to remember any of these clones
# (we could have used an --ephemeral clone, but that might deposite data
# of failed jobs at the origin location, if the job runs on a shared
# filesystem -- let's stay self-contained)
git submodule foreach --recursive git annex dead here

# checkout new branches
# this enables us to store the results of this job, and push them back
# without interference from other jobs
git -C nifti/derivatives/sub-${sub} checkout -b "sub-${sub}"

export SINGULARITYENV_CORES=1
export SINGULARITYENV_ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
export SINGULARITYENV_OMP_NUM_THREADS=1
export SINGULARITYENV_OMP_THREAD_LIMIT=1
export SINGULARITYENV_MKL_NUM_THREADS=1
export SINGULARITYENV_OPENBLAS_NUM_THREADS=1
export SINGULARITYENV_TMPDIR=$TMPDIR
for t1 in $(find nifti/sub-$sub -name '*T1w.nii.gz'); do
    ses=$(echo "${t1}" | grep -Eo "ses-[0-9]+" | head -n1)
    run=$(echo "${t1}" | grep -Eo "run-[0-9]{3}" | head -n1)
    outdir=$PWD/nifti/derivatives/sub-$sub/$ses/$run
    mkdir -p $outdir
    image_label=$(basename $t1 .nii.gz)
    # N4 bias correction
    n4_t1=${outdir}/t1_n4.nii.gz
    if [ ! -e $n4_t1 ]; then
        datalad run -i $t1 -i simg/neuror_4.0.sif -o $outdir \
            singularity run --cleanenv -B $t1:/t1.nii.gz:ro -B $PWD/code:/code -B $outdir:/out -B $TMPDIR simg/neuror_4.0.sif Rscript /code/R/n4_t1.R
    fi

    # MASS skull stripping
    stripped=${outdir}/t1_n4_brain.nii.gz
    if [ ! -e $stripped ]; then
        datalad run -i $n4_t1 -i simg/neuror_4.0.sif -o $outdir \
            singularity run --cleanenv -B $TMPDIR simg/mass_latest.sif -in $n4_t1 -dest $outdir -ref /opt/mass-1.1.1/data/Templates/WithCerebellum -NOQ -mem 20
    fi

    # FAST tissue class segmentation
    fast=${outdir}/t1_fast.nii.gz
    if [ ! -e $fast ]; then
        datalad run -i $stripped -i simg/neuror_4.0.sif -o $outdir \
            singularity run --cleanenv -B ${stripped}:/t1_n4_brain.nii.gz:ro -B $PWD/code:/code -B $outdir:/out -B $TMPDIR simg/neuror_4.0.sif Rscript /code/R/fast.R
    fi

    # JLF thalamus segmentation
    jlf=$outdir/${image_label}_jlf/thalamus/jlf_thalamus.nii.gz
    if [ ! -e $jlf ]; then
        mkdir -p ${outdir}/${image_label}_jlf/{oasis_to_t1,oasis_thalamus_to_t1,thalamus} # make dir for tmp files
        for i in $(seq 1 10); do
            SINGULARITYENV_INDEX=$i singularity run --cleanenv -B $TMPDIR \
            -B ${stripped}:/N4_T1_strip.nii.gz:ro \
            -B ${outdir}/${image_label}_jlf:/out \
            simg/jlf_latest.sif --out /out --type preprocessing --atlas thalamus
        done
        
         singularity run --cleanenv -B $TMPDIR -B ${stripped}:/N4_T1_strip.nii.gz:ro -B ${outdir}/${image_label}_jlf:/out \
            simg/jlf_latest.sif --out /out --type processing --atlas thalamus
        # running each array job through datalad run is a bit much... just save end results
        rm -rf ${outdir}/${image_label}_jlf/{oasis_to_t1,oasis_thalamus_to_t1}
        datalad save -r -m "ran JLF"
    fi
done

for flair in $(find nifti/sub-$sub -name '*acq-lowres_run-*_FLAIR.nii.gz'); do
    ses=$(echo "${flair}" | grep -Eo "ses-[0-9]+" | head -n1)
    run=$(echo "${flair}" | grep -Eo "run-[0-9]{3}" | head -n1)
    outdir=nifti/derivatives/sub-$sub/$ses/$run
    mkdir -p $outdir
    image_label=$(basename $flair .nii.gz)
    n4_t1=${outdir}/t1_n4.nii.gz
    if [ -e $n4_t1 ]; then
        # N4 bias correction
        n4_flair=${outdir}/flair_n4.nii.gz
        if [ ! -e $n4_flair ]; then
            datalad run -i $flair -i simg/neuror_4.0.sif -o $outdir \
            singularity run --cleanenv -B $flair:/flair.nii.gz:ro -B $PWD/code:/code -B $outdir:/out -B $TMPDIR simg/neuror_4.0.sif Rscript /code/R/n4_flair.R
        fi

        # ANTS registration
        registered_flair=${outdir}/flair_n4_reg_brain.nii.gz
        if [ ! -e $registered_flair ]; then
            datalad run -i $n4_flair -i $n4_t1 -i simg/neuror_4.0.sif -o $outdir \
            singularity run --cleanenv -B $n4_flair:/flair_n4.nii.gz:ro -B $n4_t1:/t1_n4.nii.gz:ro -B $PWD/code:/code -B $outdir:/out -B $TMPDIR simg/neuror_4.0.sif Rscript /code/R/registration.R
        fi

        # WhiteStripe
        norm_flair=${outdir}/flair_n4_brain_ws.nii.gz
        if [ ! -e $norm_flair ]; then
            datalad run -i $registered_flair -i ${outdir}/t1_n4_brain.nii.gz -i simg/neuror_4.0.sif -o $outdir \
            singularity run --cleanenv -B $registered_flair:/flair_n4_reg_brain.nii.gz:ro -B ${outdir}/t1_n4_brain.nii.gz:/t1_n4_brain.nii.gz:ro -B $PWD/code:/code -B $outdir:/out -B $TMPDIR simg/neuror_4.0.sif Rscript /code/R/whitestripe.R
        fi

        # MIMOSA
        if [ ! -e $outdir/mimosa_binary_mask_0.25.nii.gz ]; then
            datalad run -i $norm_flair -i ${outdir}/t1_n4_reg_brain_ws.nii.gz -i simg/neuror_4.0.sif -o $outdir \
            singularity run --cleanenv -B $norm_flair:/flair_n4_brain_ws.nii.gz:ro -B ${outdir}/t1_n4_reg_brain_ws.nii.gz:/t1_n4_reg_brain_ws.nii.gz:ro -B $PWD/code:/code -B $outdir:/out -B $PWD/mimosa_models/melissa_mimosa_model.RData:/mimosa_model.RData -B $TMPDIR simg/neuror_4.0.sif Rscript /code/R/mimosa.R
        fi
    fi
done

# selectively push outputs only
# ignore root dataset, despite recorded changes, needs coordinated
# merge at receiving end
flock $DSLOCKFILE datalad push -r -d nifti/derivatives/sub-${sub} --to origin

cd ../..
chmod -R 777 $wrkDir
rm -rf $wrkDir



