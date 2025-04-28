# Make SIFS
## def files
I've included a load of def files that can be build and run and fit within the main scripts ecosystem.

## make sifs
Most systems won't like building locally, unless it is set-up to use no-root.
in which case remote login to somewhere like sylabs.io and run
```
singularity build --remote fastp-v0.23.1.sif fastp-v0.23.1.def
```
