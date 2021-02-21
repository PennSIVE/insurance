library(extrantsr)

t1_n4_brain = readnii("/t1_n4_brain.nii.gz")
rt1 = robust_window(t1_n4_brain)
		mask = t1_n4_brain > 0
		tissue_seg = otropos(a=rt1,x=mask)

writenii(rt1, "/out/t1_otropos.nii.gz")
