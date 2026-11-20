### Mixed layer temperature analysis for historical variability in Eastern Boundary Upwelling Regions (EBUS)
- California
- Canary
- Benguela
- Peru

**multiply_masks.sh**
1. multiply remapped output data with EBUS masks (Canary, California, Peru, Benguela)
2. remove superfluous latitudinal and longitudinal bands which have only NaN values to remove data size

**Mixed_layer_depth_OHC_budget_with_interpolated_data_reduced.ipynb**
1. select only data above the mixed layer
2. verify budget closure by calculating the residual between dMLT/dt (mixed layer temperature tendency) and the sum of the right-hand-side variables that include
- advection (in all three directions), diffusion (lateral + vertical), radiation (solar + non-solar)
3. write all these files into net .netcdf files with metadata
3. create time series of these budget terms with associated linear trends over 1950-2018 including significance statements
