import pydicom
import string
import random
import glob
import os

# dcmdir=/cbica/projects/insurance/ResearchMigration20180924
# for dir in $(cat ~/target_dirs.csv | sort | uniq); do
# qsub -b y -cwd -o ~/sge/\$JOB_ID -e ~/sge/\$JOB_ID singularity exec --cleanenv -B /cbica --pwd $dcmdir/$dir ~/simg/neuropythy_latest.sif python $PWD/symlinks.py
# done


def main():
    alldcm = glob.glob("*.dcm")
    for i in range(len(alldcm)):
        try:
            ds = pydicom.dcmread(alldcm[i])
        except Exception as e:
            print(alldcm[i], "is not a valid dicom;", str(e))
            continue
        fn = os.path.basename(alldcm[i])
        path = "/cbica/projects/insurance/symlinks/" + ds.PatientID + "/" + ds.StudyDate
        os.makedirs(path, exist_ok=True)
        alias = path + '/' + fn
        if os.path.exists(alias):
            print(alias, "exists, renaming to avoid conflict")
            rand = ''.join(random.choices(
                string.ascii_uppercase + string.digits, k=10))
            alias = path + '/' + rand
        os.symlink(os.getcwd() + '/' + alldcm[i], alias)


if __name__ == "__main__":
    main()


