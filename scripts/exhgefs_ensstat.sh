#!/bin/sh
#################################################################################
# Script: exhgefs_ensstat.sh
# Abstract: this script produces ens mean, spread and probabilistic forecasts for
#           AIGEFS and HYBRID ens (AIGEFS + GEFS ) if HYBRID=YES
# Author: Bo Cui ---- Oct. 2025
# History: 
#         2025-09-20  Bo Cui - First implementation of this new script
#         2025-10-09  Russell Manser - modify to process individual lead times
#################################################################################
set -x

pgm=hgefs_ensstat        

#####################################
#  calculate ensemble mean and spread
#####################################

hourlist="000 006 012 018 024 030 036 042 048 054 060 066 072 \
          078 084 090 096 102 108 114 120 126 132 138 144 150 \
          156 162 168 174 180 186 192 198 204 210 216 222 228 \
          234 240"

memberlist_gefs="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 \
                 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20 \
                 p21 p22 p23 p24 p25 p26 p27 p28 p29 p30"

memberlist_aigefs="000 001 002 003 004 005 006 007 008 009 010 \
                   011 012 013 014 015 016 017 018 019 020 \
                   021 022 023 024 025 026 027 028 029 030"

ensstatlist="avg spr"

######################################################
# start mean and spread calculation for each lead time
######################################################

for prod in pres sfc; do

  for nfhrs in $hourlist; do

    if [ -s namin_avgspr_${prod}_${nfhrs} ]; then
     rm namin_avgspr_${prod}_${nfhrs}
    fi

    echo " &namens" >>namin_avgspr_${prod}_${nfhrs}

    ifile=0
    aigefs_count=0
    gefs_count=0

#######################
# AIGEFS ensemble input
#######################

    for mem in $memberlist_aigefs; do
      file=$COMINaigefs/mem${mem}/model/atmos/grib2/aigefs.t${cyc}z.${prod}.f${nfhrs}.grib2
      if [ -s $file ]; then
        (( ifile = ifile + 1 ))
        (( aigefs_count = aigefs_count + 1 ))
        iskip=0
        echo " cfipg($ifile)='${file}'," >>namin_avgspr_${prod}_${nfhrs}
        echo " iskip($ifile)=${iskip}," >>namin_avgspr_${prod}_${nfhrs}
      else
        msg="File does not exist or has size zero: ${file}"
        export err=1; err_chk "$msg"
      fi

    done

    if [ $aigefs_count -le 1 ]; then
      msg="Fewer than 1 AIGEFS files available for fcst hr $nfhrs"
      export err=1; err_chk "$msg"
    else
      echo "Found ${aigefs_count} AIGEFS files for ${prod} and hour ${nfhrs}"
    fi

#########################################
# GEFS ensemble input for hybrid products
#########################################

    for mem in $memberlist_gefs; do
      if [ "${prod}" = "pres" ]; then 
        file=$COMINgefs/pgrb2p25/ge${mem}.t${cyc}z.pgrb2.0p25.f${nfhrs}            
      elif [ "${prod}" = "sfc" ]; then 
        file=$COMINgefs/pgrb2sp25/ge${mem}.t${cyc}z.pgrb2s.0p25.f${nfhrs}            
      fi
      if [ -s $file ]; then
        (( ifile = ifile + 1 ))
        (( gefs_count = gefs_count + 1 ))
        iskip=0
        echo " cfipg($ifile)='${file}'," >>namin_avgspr_${prod}_${nfhrs}
        echo " iskip($ifile)=${iskip}," >>namin_avgspr_${prod}_${nfhrs}
      else
        msg="File does not exist or has size zero: ${file}"
        export err=1; err_chk "$msg"
      fi
    done

    if [ $gefs_count -le 1 ]; then
      msg="Fewer than 1 GEFS/AIGEFS files available for fcst hr $nfhrs"
      export err=1; err_chk "$msg"
    else
      echo "Found ${gefs_count} GEFS files for ${prod} and hour ${nfhrs}"
    fi

    echo " nfiles=${ifile}," >>namin_avgspr_${prod}_${nfhrs}
    echo " cfopg1='hgefs.t${cyc}z.${prod}.avg.f${nfhrs}.grib2'," >>namin_avgspr_${prod}_${nfhrs}
    echo " cfopg2='hgefs.t${cyc}z.${prod}.spr.f${nfhrs}.grib2'," >>namin_avgspr_${prod}_${nfhrs}
    echo " /" >>namin_avgspr_${prod}_${nfhrs}

  done

  if [ -s poescript_avgspr_${prod} ]; then
    rm poescript_avgspr_${prod}
  fi

  for nfhrs in $hourlist; do
    if [ -s namin_avgspr_${prod}_${nfhrs} ]; then
      echo "$EXEChgefs/${pgm} <namin_avgspr_${prod}_${nfhrs} > $pgmout.${nfhrs}_avgspr_${prod}" >> poescript_avgspr_${prod}
    fi
  done

  ls $DATA

  chmod +x poescript_avgspr_${prod}
  $APRUN poescript_avgspr_${prod}
  export err=$?; err_chk "Failed while running one or more instances of $pgm"

  if [ "$SENDCOM" = "YES" ]; then
    for nfhrs in $hourlist; do
      for ensstat in $ensstatlist; do
        file=hgefs.t${cyc}z.${prod}.${ensstat}.f$nfhrs.grib2
        if [ -s $file ]; then
          cpfs $file $COMOUT/$file

          $WGRIB2 -s $file > $file.idx
          export err=$?; err_chk "$job failed while creating $file.idx"
          cpfs $file.idx $COMOUT/$file.idx

          if [ "$SENDDBN" = "YES" ]; then
            $DBNROOT/bin/dbn_alert MODEL HGEFS_ENSSTAT_GB2 $job $COMOUT/$file
            $DBNROOT/bin/dbn_alert MODEL HGEFS_ENSSTAT_GB2_IDX $job $COMOUT/$file.idx
          fi
        else
          export err=1; err_chk "$file missing after running $pgm"
        fi
      done
    done
  fi

done

set +x
echo " "
echo "Leaving sub script exhgefs_ensstat.sh"
echo " "
set -x

