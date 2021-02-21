t1_n4 = neurobase::readnii("/t1_n4.nii.gz")
timgs = malf.templates::mass_images(n_templates = 5) # you can adjust this
t1_n4_brain = extrantsr::malf(t1_n4,
      template.images = timgs$images,
      template.structs = timgs$masks,
      keep_images = FALSE)
neurobase::writenii(t1_n4_brain, "/out/t1_malf.nii.gz")
