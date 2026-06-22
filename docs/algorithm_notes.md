# Workflow summary

1. Load the synthetic sensor-level data and its known four-source ground truth.
2. Load the Infomax ICA + sLORETA estimate used to initialize the spatial maps.
3. Optimize the Extended EMSICA model with sign adaptation, progressive
   spatiotemporal weighting, and a direct Euclidean update in source-map space.
4. Align recovered components to ground truth for evaluation.
5. Compute inter-component broadband PAC comodulograms.
6. Generate the source-map/time-course and PAC-recovery figures.

The default manuscript demonstration uses `myalpha=0.0125`, `mybeta=27.7`, a
100-step progressive weighting schedule, and deterministic MATLAB RNG seed 0.
