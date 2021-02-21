library(neurobase)
library(WhiteStripe)


t1_n4_reg_brain = readnii("/t1_n4_brain.nii.gz")
flair_n4_brain = readnii("/flair_n4_reg_brain.nii.gz")
# WhiteStripe (intensity normalization)
t1_ind = whitestripe(t1_n4_reg_brain, "T1")
t1_n4_reg_brain_ws = whitestripe_norm(t1_n4_reg_brain, t1_ind$whitestripe.ind)
writenii(t1_n4_reg_brain_ws, "/out/t1_n4_reg_brain_ws.nii.gz") # write out white striped t1
flair_ind = whitestripe(flair_n4_brain, "T2")
flair_n4_brain_ws = whitestripe_norm(flair_n4_brain, flair_ind$whitestripe.ind)
writenii(flair_n4_brain_ws, "/out/flair_n4_brain_ws.nii.gz") # write out white striped flair
