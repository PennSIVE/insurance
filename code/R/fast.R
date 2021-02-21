t1_n4_brain = neurobase::readnii("/t1_n4_brain.nii.gz")
tissue_seg = fslr::fast(t1_n4_brain, opts="--nobias")
neurobase::writenii(tissue_seg, "/out/t1_fast.nii.gz")
