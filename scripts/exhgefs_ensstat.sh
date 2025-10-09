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

memberlist_gefs="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 \
                 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20 \
                 p21 p22 p23 p24 p25 p26 p27 p28 p29 p30"

memberlist_aigefs="000 001 002 003 004 005 006 007 008 009 010 \
                   011 012 013 014 015 016 017 018 019 020 \
                   021 022 023 024 025 026 027 028 029 030"

ensstatlist="avg spr"

outmodel=aigefs

if [ "$IFHYBRID" = "YES" ]; then
  outmodel=hgefs  
fi

######################################################
# start mean and spread calculation for each lead time
######################################################

for prod in pres sfc; do

    if [ -s namin_avgspr_${prod}_${nfhrs} ]; then
     rm namin_avgspr_${prod}_${nfhrs}
    fi

    echo " &namens" >>namin_avgspr_${prod}_${nfhrs}

    ifile=0

#######################
# AIGEFS ensemble input
#######################

    for mem in $memberlist_aigefs; do
      file=$COMINaigefs/mem${mem}/model/atmos/grib2/aigefs.t${cyc}z.${prod}.f${nfhrs}.grib2
      if [ -s $file ]; then
        (( ifile = ifile + 1 ))
        iskip=0
        echo " cfipg($ifile)='${file}'," >>namin_avgspr_${prod}_${nfhrs}
        echo " iskip($ifile)=${iskip}," >>namin_avgspr_${prod}_${nfhrs}
      fi
    done

    if [ $ifile -le 1 ]; then
      msg="Fewer than 1 AIGEFS files available for fcst hr $nfhrs"
      export err=1; err_chk "$msg"
    fi

#########################################
# GEFS ensemble input for hybrid products
#########################################

    if [ "$IFHYBRID" = "YES" ]; then
      for mem in $memberlist_gefs; do
        if [ "${prod}" = "pres" ]; then 
          file=$COMINgefs/pgrb2p25/ge${mem}.t${cyc}z.pgrb2.0p25.f${nfhrs}            
        elif [ "${prod}" = "sfc" ]; then 
          file=$COMINgefs/pgrb2sp25/ge${mem}.t${cyc}z.pgrb2s.0p25.f${nfhrs}            
        fi
        if [ -s $file ]; then
          (( ifile = ifile + 1 ))
          iskip=0
          echo " cfipg($ifile)='${file}'," >>namin_avgspr_${prod}_${nfhrs}
          echo " iskip($ifile)=${iskip}," >>namin_avgspr_${prod}_${nfhrs}
        fi
      done
    fi

    if [ $ifile -le 1 ]; then
      msg="Fewer than 1 GEFS/AIGEFS files available for fcst hr $nfhrs"
      export err=1; err_chk "$msg"
    fi

    ls $DATA

    echo " nfiles=${ifile}," >>namin_avgspr_${prod}_${nfhrs}
    echo " cfopg1='${outmodel}.t${cyc}z.${prod}.avg.f${nfhrs}.grib2'," >>namin_avgspr_${prod}_${nfhrs}
    echo " cfopg2='${outmodel}.t${cyc}z.${prod}.spr.f${nfhrs}.grib2'," >>namin_avgspr_${prod}_${nfhrs}
    echo " /" >>namin_avgspr_${prod}_${nfhrs}

    $EXEChgefs/${pgm} <namin_avgspr_${prod}_${nfhrs} > $pgmout.${nfhrs}_avgspr_${prod}
    export err=$?; err_chk "$job failed while running ${pgm}"

  ls $DATA

  if [ "$SENDCOM" = "YES" ]; then
      for ensstat in $ensstatlist; do
        file=${outmodel}.t${cyc}z.${prod}.${ensstat}.f$nfhrs.grib2
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
          export err=1; err_chk "$file missing"
        fi
      done
  fi

done

set +x
echo " "
echo "Leaving sub script exhgefs_ensstat.sh"
echo " "
set -x

