
flair_orig = neurobase::readnii("/flair.nii.gz")
flair_n4 = extrantsr::bias_correct(file = flair_orig, correction = "N4")
neurobase::writenii(flair_n4, "/out/flair_n4.nii.gz")
