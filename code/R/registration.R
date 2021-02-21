library(neurobase)
library(ANTsR)
library(extrantsr)

t1_n4 = readnii("/t1_n4.nii.gz")
t1_n4_brain = readnii("/out/t1_n4_brain.nii.gz")
flair_n4 = readnii("/flair_n4.nii.gz")

# register FLAIR to T1
flair_n4_reg2t1n4 = registration(filename = flair_n4, template.file = t1_n4,
              typeofTransform = "Rigid", interpolator = "Linear") # register n4 t1 to n4 flair
save(flair_n4_reg2t1n4,file="/out/flair_n4_reg2t1n4.RData")

flair_n4_reg = antsApplyTransforms(fixed = oro2ants(t1_n4), moving = oro2ants(flair_n4),
            transformlist = flair_n4_reg2t1n4$fwdtransforms, interpolator = "welchWindowedSinc")
antsImageWrite(flair_n4_reg, "/out/flair_n4_reg.nii.gz") # write out registered t1 image

# get brain mask
brainmask = t1_n4_brain > 0
# apply brain mask to registered flair
flair_n4_reg_brain = flair_n4_reg * brainmask
antsImageWrite(flair_n4_reg_brain, "/out/flair_n4_reg_brain.nii.gz")
