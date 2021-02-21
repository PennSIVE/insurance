
t1_orig = neurobase::readnii("/t1.nii.gz")
t1_n4 = extrantsr::bias_correct(file = t1_orig, correction = "N4")
neurobase::writenii(t1_n4, "/out/t1_n4.nii.gz")
