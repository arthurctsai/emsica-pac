# Demo data

`demodata/zm09` is immutable packaged input. It retains the original numbered
workflow lineage:

- `2epochs/EPs-synth`: synthetic ground truth and its PAC cache;
- `3ica/ICs-synth-infomax`: Infomax ICA + sLORETA baseline and PAC cache;
- `5lfm/source_plot_geometry.mat`: compact reduced meshes for source plots;
- `6emsica/B0-synth-infomax`: cached EMSICA initializer;

New training runs belong under `outputs/zm09/6emsica/`. The omitted topology,
index, duplicate `zm09-all`, and forward-model cache files are not required by
the packaged cached-B0 workflow.
