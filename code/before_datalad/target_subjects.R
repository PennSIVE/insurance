load("~/ResearchMigration20180924/database_2019-03-04.RData")
empis_MS = read.csv("~/empis_MS.csv")$EMPI
all_ids <- sort(unique(database[, "PatientID"]))
for (sid in 1:length(all_ids)) {
	subj = na.omit(unique(database[database[, "PatientID"] == all_ids[sid], c("StudyDate", "dir")]))
	subj = subj[subj[, "StudyDate"] >= 20150401, c("StudyDate", "dir")]
	diff = max(subj$StudyDate) - min(subj$StudyDate)
	if (diff >= 10000) { # min 1yr difference
		if (all_ids[sid] %in% empis_MS) { # in melissas list
			write(paste(all_ids[sid], unique(subj$StudyDate)), file = "~/targets.csv", append = TRUE)
			write(unique(subj$dir), file = "~/target_dirs.csv", append = TRUE)
		}
	}
}

