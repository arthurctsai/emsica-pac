# Extended EMSICA-PAC demonstration

This repository contains a demonstration implementation of the Extended
EMSICA-PAC workflow described in the accompanying manuscript. It includes the
`zm09` synthetic dataset, its Infomax ICA + sLORETA initialization, MATLAB code
for Extended EMSICA, broadband phase-amplitude coupling (PAC), and scripts that
regenerate the source-recovery and PAC figures.

![Representative source recovery](reference/source_recovery_zm09.png)

![Representative PAC recovery](reference/pac_recovery_zm09.png)

## Requirements

- MATLAB R2024b (the tested release; recent releases may also work)
- EEGLAB 2020 or newer
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- Parallel Computing Toolbox (for PAC computation; GPU acceleration is optional)
- Sufficient RAM for the 23,363-vertex source model; a GPU is optional

Add EEGLAB to the MATLAB path before starting, or set `EEGLAB_ROOT` to its
installation directory.

## Quick reproduction

From the repository root:

```matlab
setup_emsica_pac;
demo_run_all;
```

This uses the included validated Extended EMSICA result and writes figures to
`outputs/`. Source maps are reproduced from the validated rendered strips; PAC
maps are rendered directly from the included comodulogram tensors.

## Rerun Extended EMSICA

```matlab
setup_emsica_pac;
demo_run_all('train', 100);
```

The rerun starts from the included Infomax-derived B0 initializer and writes to
`demodata/zm09/6emsica/ICs-synth-infomax-extended-demo-full/`. Existing truth,
Infomax, B0, and reference result folders are not overwritten.

For a short installation test:

```matlab
verify_demo('smoke')
```

## Data layout

- `2epochs/EPs-synth/`: injected synthetic ground truth
- `3ica/ICs-synth-infomax/`: Infomax ICA + sLORETA baseline
- `6emsica/B0-synth-infomax/`: cached EMSICA initializer
- `6emsica/ICs-synth-infomax-extended-reference-full/`: compact validated result
- `5lfm/`: reduced dipole geometry needed for EMSICA result assembly

The compact repository is approximately 597 MiB. Its three 176 MiB `.fdt`
signal files require Git LFS or an external data archive when publishing on
GitHub. See `docs/data_description.md`.

## Main entry points

- `demo_run_emsica.m`: Extended EMSICA decomposition
- `demo_generate_figures.m`: source-recovery and broadband-PAC figures
- `demo_plot_pac_maps.m`: memory-efficient rendering of cached PAC tensors
- `demo_run_all.m`: combined workflow
- `tests/verify_demo.m`: reproducibility checks

The portable wrappers are new for this demonstration. Algorithm code under
`code/legacy/` is retained close to the manuscript-analysis implementation for
traceability.
