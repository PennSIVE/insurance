library(neurobase)
library(fslr)
library(mimosa)

t1 = readnii("/t1_n4_reg_brain_ws.nii.gz")
mimosa = mimosa_data(brain_mask = t1 > min(t1), FLAIR = readnii("/flair_n4_brain_ws.nii.gz"), T1 = t1, gold_standard = NULL, normalize = "no")
mimosa_df = mimosa$mimosa_dataframe
save(mimosa, file = "/out/mimosa.RData")
cand_voxels = mimosa$top_voxels
tissue_mask = mimosa$tissue_mask
# Fit MIMoSA model with training data
load("/mimosa_model.RData")
# Apply model to test image
predictions_WS = predict(mimosa_model, mimosa_df, type = "response")
predictions_nifti_WS = niftiarr(cand_voxels, 0)
predictions_nifti_WS[cand_voxels == 1] = predictions_WS
prob_map_WS = fslsmooth(predictions_nifti_WS, sigma = 1.25, mask = tissue_mask, retimg = TRUE, smooth_mask = TRUE) # probability map
writenii(prob_map_WS, "/out/mimosa_prob_map.nii.gz") # write out probability map
lesion_binary_mask = (prob_map_WS >= .25) # threshold at p-hat = .25 to get binary lesion mask
writenii(lesion_binary_mask, "/out/mimosa_binary_mask_0.25.nii.gz")
