# Demo data

The EEG signals in `2epochs/EPs-synth` are synthetic signals projected through
the `zm09` forward model. Large `synthBS` test matrices and the redundant
`X.mat` sensor-data copy were removed from the public demo; they are not used by
the Extended EMSICA or PAC workflows provided here.

Before public distribution, confirm that the original consent and institutional
data-governance terms permit redistribution of the anatomy-derived surfaces and
lead-field files. The release should contain no raw MRI volume or direct
identifier.

The three `zm09.fdt` signal files are each approximately 176 MiB and exceed
GitHub's ordinary per-file size limit. Track binary demo data with Git LFS, or
deposit the dataset in a versioned scientific archive and retain checksums plus
a download script here. The complete compact repository is approximately
597 MiB.
