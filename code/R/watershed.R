# hack to ensure freesurfer env sourced correctly
system("ln -s bash /bin/sh.bash && mv /bin/sh.bash /bin/sh") # for some reason it tries to call /bin/sh on a /bin/bash script; replace sh with bash

t1_n4 = neurobase::readnii("/t1_n4.nii.gz")
watershed = freesurfer::mri_watershed(t1_n4)
neurobase::writenii(watershed, "/out/t1_watershed.nii.gz")
