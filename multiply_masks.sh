#!/bin/bash

set -e # makes bash exit when there is an error
set -u # makes bash stop when I reference an undefined variable

# Initialize Conda
source "$(conda info --base)/etc/profile.d/conda.sh"
# Activate environment
conda activate my_jupyterlab_env


# Load required modules
module load cdo
module load nco

INPUT="/gxfs_work/geomar/smomw447/models/esm-experiments/FOCI2.0_MH009_cmip6hist_ESM_1949CC105_incl-OHC-DIC-budgets/outdata/nemo/remapped/FOCI2.0_MH009_cmip6hist_ESM_1949CC105_incl-OHC-DIC-budgets_1m_19500101_20181231_grid_T_trendcorrected_r360x180.nc"
#INPUT='/gxfs_work/geomar/smomw447/models/esm-experiments/FOCI2.0_MH009_cmip6hist_ESM_1949CC105_incl-OHC-DIC-budgets/outdata/nemo/remapped/FOCI2.0_MH009_cmip6hist_ESM_1949CC105_incl-OHC-DIC-budgets_1m_19500101_20181231_grid_OHC_trendcorrected_r360x180.nc'

MASKS=( "EBUS_masks_can_r360x180.nc" ) #"EBUS_masks_cal_r360x180.nc" "EBUS_masks_per_r360x180.nc" "EBUS_masks_ben_r360x180.nc" )

for MASK in "${MASKS[@]}"; do

    NAME="${MASK#EBUS_masks_}"
    NAME="${NAME%_r360x180.nc}"

    CLEAN_MASK="mask_${NAME}_clean.nc"
    MASKED="masked_${NAME}_grid_T.nc"
    OUTPUT="output_${NAME}_grid_T.nc"
#    MASKED="masked_${NAME}_grid_OHC.nc"  
#    OUTPUT="output_${NAME}_grid_OHC.nc"
    
    echo "-----------------------------------"
    echo "Processing: $MASK"
    echo "Started: $(date)"

    if [[ -f "$CLEAN_MASK" && -f "$MASKED" && -f "$OUTPUT" ]]; then
        echo "CLEAN_MASK and MASKED and OUTPUT already exist."
        echo "Skipping CDO steps..."
    else
        # 1. Create clean mask (only if missing)
        if [[ ! -f "$CLEAN_MASK" ]]; then
            cdo -L -f nc4 -z zip_6 setctomiss,0 "$MASK" "$CLEAN_MASK"
        fi

        # 2. Apply geographical mask (only if missing)
        if [[ ! -f "$MASKED" ]]; then
            cdo -L -f nc4 -z zip_6 ifthen "$CLEAN_MASK" "$INPUT" "$MASKED"
        fi

        # 3. Remove latitude and longitude coordinates containing only NaN
        if [[ ! -f "$OUTPUT" ]]; then
            python3 - "$MASKED" "$OUTPUT" <<'PY'
import sys
import xarray as xr

ds = xr.open_dataset(sys.argv[1])

ds = ds.dropna(dim="lat", how="all")
ds = ds.dropna(dim="lon", how="all")

ds.to_netcdf(sys.argv[2])
ds.close()
PY
        fi
    fi








    # 3. Extract shallow depth boundary
#    ncks -O -v deptht_bnds "$INPUT" depth_bounds_tmp.nc

    # 4. Apply mixed-layer depth criterion
    # Keep data where upper depth boundary <= somxl010
#    ncap2 -O -s '
#        where(deptht_bnds(:,0) > somxl010) {
#            '"$DATA_VAR"' = '"$DATA_VAR"'@_FillValue;
#        }
#    ' "$MASKED" "$OUTPUT"

#    echo "Finished: $OUTPUT"
#    echo "Completed: $(date)"
done





#for MASK in "${MASKS[@]}"; do

#NAME="${MASK#EBUS_masks_}"
#NAME="${NAME%_r360x180.nc}"

#CLEAN_MASK="mask_${NAME}_clean.nc"
#OUTPUT="output_${NAME}_grid_T.nc"
#OUTPUT="output_${NAME}_grid_OHC.nc"

#echo "-----------------------------------"
#echo "Processing: $MASK"
#echo "Started: $(date)"

# 1. Replace zeros in mask with missing values
#cdo -L -f nc4 -z zip_6 setctomiss,0 "$MASK" "$CLEAN_MASK"
# 2. Apply mask and compress output
#cdo -L -f nc4 -z zip_6 ifthen "$CLEAN_MASK" "$INPUT" "$OUTPUT"

# 3. Apply mixed-layer depth criterion using NCO
#ncap2 -O -s '
#where(depth > somxl010) {
#    data_var = data_var@_FillValue;
#}
#' "$MASKED" "$OUTPUT"



# 1. Replace zeros with missing values
#cdo -L setctomiss,0 "$MASK" "$CLEAN_MASK"
# 2. Multiply input dataset with cleaned mask
#cdo -L mul "$INPUT" "$CLEAN_MASK" "$OUTPUT"
# 3. Set masked cells to missing values to reduce size
#cdo ifthen "$CLEAN_MASK" "$INPUT" "$OUTPUT"

#echo "Finished: $OUTPUT"
#echo "Completed: $(date)"

echo "-----------------------------------" echo "All four masks processed successfully!" echo "Finished: $(date)"
