#!/bin/csh
umask 002
set project_root = /usr/local/projects/VHTNGS
set sample_data_root = ${project_root}/sample_data_new

set username = `whoami`
set timestamp = `date +"%0Y%0m%0d%0H%0M%0S"`
set collection_list = `cat $1 | tr ',' ':' | tr -d '\r' | tr -d ' ' | cut -d ':' -f 2 | sort -u  | tr '\n' '_' | sed -e 's/_$//'`

set target_dir = /usr/local/scratch/VIRAL/${username}/${timestamp}_${collection_list}_nextgen_data
mkdir -p ${target_dir}

foreach bc_rec ( `cat $1 | tr ',' ':' | tr -d '\r' | tr -d ' ' | sort -u` )
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 1`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 2`
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 3`

  set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}
  set sample_mapping_dir = ${sample_data}/mapping
  set copied_files = 0

  if ( -d ${sample_mapping_dir} ) then
    set file_cnt = `ls -1 ${sample_mapping_dir}/*_final.fastq | wc -l`
    if ( ${file_cnt} > 0 ) then
      echo "INFO: copying Illumina/Solexa nextgen data for [${db_name}/${col_name}/${bac_id}] to [${target_dir}]"
      cp ${sample_mapping_dir}/*_final.fastq ${target_dir}/.
      set copied_files = 1
    endif

    set file_cnt = `ls -1 ${sample_mapping_dir}/*final.*.sff | wc -l`
    if ( ${file_cnt} > 0 ) then
      echo "INFO: copying Roche/454 nextgen data for [${db_name}/${col_name}/${bac_id}] to [${target_dir}]"
      cp ${sample_mapping_dir}/*_final.*.sff ${target_dir}/.
      set copied_files = 1
    endif

    if ( ${copied_files} < 1 ) then
      echo "ERROR:  no nextgen sequence files found in directory [${sample_mapping_dir}]"
    endif
    
  else
    echo "ERROR: Directory [${sample_mapping_dir}] does not exist"
  endif
end

echo "INFO: tar'ing and compressing data into [${target_dir:h}/${target_dir:t}.tgz]"

pushd ${target_dir:h} >& /dev/null
  tar -cvzf ${target_dir:t}.tgz ${target_dir:t}
popd >& /dev/null

echo "INFO: user [${username}] should now ftp [${target_dir:h}/${target_dir:t}.tgz] onto the ftp site"
exit








































end
exit
