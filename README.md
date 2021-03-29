# Insurance study

How does insurance impact health outcomes?

## Processing steps
There are 3 stages to processing as it is not feasible (or useful) to track everything with datalad. Stages 1 and 2 were done on the CUBIC cluster and stage 3 was done on the PMACS cluster.

### Stage 1 (before datalad)
1. Melissa and Taki generated a dataframe (`database_2019-03-04.RData`) of all images and metadata.
2. `code/before_datalad/target_subjects.R` uses this dataframe to get a list of subjects and file paths we're interested in. Specifically, we included a subject if it's in Melissa's `empis_MS.csv` list, it has at least two scans after 2015-04-01 that are at least 1 year apart.
3. `code/before_datalad/symlinks.py` reorganizes target dicoms by PatientID (EMPI) and StudyDate as heudiconv requires.
4. `code/before_datalad/insurance_heuristic.py` used to convert dicoms with heudiconv.

### Stage 2 (datalad tracked)
5. All subjects processed with `./code/process.sh` (which calls `./code/process_subject.sh`, which calls the various scripts in `./code/R`). These results can be reproduced by running `datalad rerun commit` where `commit` is the shasum of the commit created when subject originally processed.

### Stage 3 (after datalad)
6. `code/after_datalad/make_jpegs.sh` creates raster images for every nifti so they can be QC'd in a [web app](https://github.com/PennSIVE/qcbids).
7. `code/after_datalad/make_database.py` creates a sqlite database for the QC app.
8. `code/after_datalad/filter_db.py` was used to filter the db further (for example, at one point we wanted to only look at subjects with two sessions at least 2 years apart rather than 1)

## QC
The qcbids app can be launched by running `./code/after_datalad/launch_app.sh PORT` where PORT is an open port. When running the app on the cluster, make sure to tunnel your HTTP traffic to that port on the cluster. This can be setup by running `ssh -qnNT -L 3330:127.0.0.1:3330 user@takim`.

## Analysis
TODO