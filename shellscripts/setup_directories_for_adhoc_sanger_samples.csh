#!/bin/csh
umask 002
set project_root = /usr/local/projects/VHTNGS
set sample_data_root = ${project_root}/sample_data_new

foreach bc_rec ( `cat $1 | tr ',' ':' | tr -d '\r' | tr -d ' ' | sort -u` )
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 1`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 2`
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 3`

  echo "INFO: creating directory structure for [${db_name}/${col_name}/${bac_id}]"

  set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}
  set sample_data_sanger = ${sample_data}/sanger
  set sample_data_merged_sanger = ${sample_data}/merged_sanger
  set sample_chromat_dir = ${sample_data}/mapping/chromat_dir
  set seg_best_ref_dir = ${sample_data}/reference_fasta

  if ( -d ${sample_data_sanger} ) then
  else
    mkdir -p ${sample_data_sanger}
  endif
  if ( -d ${sample_data_merged_sanger} ) then
  else
    mkdir -p ${sample_data_merged_sanger}
  endif
  if ( -d ${sample_chromat_dir} ) then
  else
    mkdir -p ${sample_chromat_dir}
  endif
  if ( -d ${seg_best_ref_dir} ) then
  else
    mkdir -p ${seg_best_ref_dir}
  endif

end

exit








































end
exit
