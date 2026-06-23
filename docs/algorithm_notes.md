# Workflow summary

1. Load the synthetic sensor-level data and its known four-source ground truth.
2. Load the Infomax ICA + sLORETA estimate used to initialize the spatial maps.
3. Optimize the Extended EMSICA model with sign adaptation, progressive
   spatiotemporal weighting, and a direct Euclidean update in source-map space.
4. Align the four recovered components directly against spatial ground truth
   in `B.mat` (no generic topology/clustering cache is required).
5. Compute inter-component broadband PAC with the fixed four-source helper in
   `demo_generate_figures.m`.
6. Generate the source-map/time-course and PAC-recovery figures.

Packaged inputs under `demodata/zm09` are read-only. New EEGLAB datasets and
PAC caches are written under `outputs/zm09/<tag>/`.

The default manuscript demonstration uses `myalpha=0.0125`, `mybeta=27.7`, a
100-step progressive weighting schedule, and deterministic MATLAB RNG seed 0.
