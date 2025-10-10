#!/bin/bash

# =====================================================================
# create_links.sh
# ---------------------------------------------------------------------
# Create soft links for jhgefs_ensstat_fHHH.ecf in 6-hour increments.
# =====================================================================

target=jhgefs_ensstat.ecf
for i in $(seq -w 0 6 240); do
  ln -s $target jhgefs_ensstat_f${i}.ecf
done

