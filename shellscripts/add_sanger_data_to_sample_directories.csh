#!/bin/csh
umask 002
set project_root = /usr/local/projects/VHTNGS
set sample_data_root = ${project_root}/sample_data_new

foreach bc_rec ( `cat $1 | tr ',' ':' | tr -d '\r' | tr -d ' ' | sort -u` )
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 1`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 2`
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 3`

  echo "INFO: consolidating Sanger data for [${db_name}/${col_name}/${bac_id}]"

  set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}
  set sample_data_sanger = ${sample_data}/sanger
  set sample_mapping_dir = ${sample_data}/mapping
  set final_fasta_reads = ${sample_mapping_dir}/${db_name}_${col_name}_${bac_id}_final.fasta
  set sample_data_merged_sanger = ${sample_data}/merged_sanger
  set sample_data_merged_sanger_file = ${sample_data_merged_sanger}/${db_name}_${col_name}_${bac_id}.fasta

  if ( -d ${sample_data_sanger} ) then
  else
    mkdir -p ${sample_data_sanger}
  endif
  if ( -d ${sample_data_merged_sanger} ) then
  else
    mkdir -p ${sample_data_merged_sanger}
  endif

  if ( -e ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta ) then
    if ( `cat ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta | wc -l` > 0 ) then
    else
      echo "WARNING: No Sanger fasta file exists for [${db_name}/${col_name}/${bac_id}]"
      touch ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta
      touch ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.untrimmed
      touch ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.trimpoints
    endif
  else
    echo "WARNING: No Sanger fasta file exists for [${db_name}/${col_name}/${bac_id}]"
    touch ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta
    touch ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.untrimmed
    touch ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.trimpoints
  endif

  cat ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta | gawk '{if(length($0)>0){print;}}' > ${sample_data_merged_sanger_file}
  cat ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.untrimmed | gawk '{if(length($0)>0){print;}}' > ${sample_data_merged_sanger_file}.untrimmed
  if ( -e ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.trimPoints ) then
    if ( `cat ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.trimPoints | wc -l` > 0 ) then
      cp ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.trimPoints ${sample_data_merged_sanger_file}.trimpoints
    endif
  endif
  if ( -e ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.trimpoints ) then
    if ( `cat ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.trimpoints | wc -l` > 0 ) then
      cp ${sample_data_sanger}/${db_name}_${col_name}_${bac_id}_final.fasta.trimpoints ${sample_data_merged_sanger_file}.trimpoints
    endif
  endif

end

exit








































end
exit
