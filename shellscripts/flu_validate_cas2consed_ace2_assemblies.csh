#!/bin/csh
setenv RUBYLIB /usr/local/devel/DAS/users/tstockwe/Ruby/Tools/Bio
setenv PATH /usr/local/packages/clc-ngs-cell:/usr/local/packages/clc-bfx-cell:${PATH}
use emboss50
umask 002

set project_root = /usr/local/projects/VHTNGS
set sample_data_root = ${project_root}/sample_data_new

foreach bc_rec ( `cat $1 | tr ',' ':' | tr -d '\r' | tr -d ' ' | sort -u` )
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 1`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 2`
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 3`

  set flu_a = 0

  switch ($db_name)
    case synflu:
      set flu_a = 1
    breaksw
    case synfluenza:
      set flu_a = 1
    breaksw
    case barda:
      set flu_a = 1
    breaksw
    case giv:
      set flu_a = 1
    breaksw
    case giv3:
      set flu_a = 1
    breaksw
    case piv:
      set flu_a = 1
    breaksw
    case swiv:
      set flu_a = 1
    breaksw
    case rtv:
      set flu_a = 0
    breaksw
    case gcv:
      set flu_a = 0
    breaksw
    case veev:
      set flu_a = 0
    breaksw
    case hadv:
      set flu_a = 0
    breaksw
    case mpv:
      set flu_a = 0
    breaksw
    case norv:
      set flu_a = 0
    breaksw
    case vzv:
      set flu_a = 0
    breaksw
  endsw

  if ( ${flu_a} > 0 ) then
    set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}
    set sample_mapping_dir = ${sample_data}/mapping
    set ace2_fasta = ${sample_mapping_dir}/consed_with_sanger/${db_name}_${col_name}_${bac_id}.ace.2.consensus.fasta
    set ace2_fluvalidator = ${ace2_fasta}.fluValidator
    set need_validator = 0
    if ( -e ${ace2_fasta} && -e ${ace2_fluvalidator} ) then
      set ace2_fasta_time = `stat --format="%Z" ${ace2_fasta}`
      set ace2_fluvalidator_time = `stat --format="%Z" ${ace2_fluvalidator}`
      if ( ${ace2_fasta_time} < ${ace2_fluvalidator_time} ) then
        set need_validator = 0
        echo "INFO: fluValidator up-to-date for [${db_name}_${col_name}_${bac_id}].  If you want to re-run fluValidator, then delete file [${ace2_fluvalidator}]"
      else
        set need_validator = 1
      endif
    else
      set need_validator = 1
    endif
    if ( ${need_validator} > 0 ) then
      if ( -e ${ace2_fluvalidator} ) then
        rm ${ace2_fluvalidator}
      endif
      if ( -e ${ace2_fluvalidator} ) then
        echo "ERROR: [${db_name}_${col_name}_${bac_id}] has an unremovable fluValidator file [${ace2_fluvalidator}]"
      else
        if ( -e ${ace2_fasta} ) then
          if ( -z ${ace2_fasta} ) then
            echo "ERROR: [${db_name}_${col_name}_${bac_id}] has an empty ace.2.consensus.fasta file [${ace2_fasta}]"
          else
            pushd ${ace2_fasta:h} >& /dev/null
              echo "INFO: running fluValidator for [${db_name}_${col_name}_${bac_id}]"
              set i = 3
              while ( (${i} > 0) && (! -e ${ace2_fluvalidator} || -z ${ace2_fluvalidator}) ) 
                @ i = ${i} - 1
                /usr/local/devel/DAS/software/ElviraStaging/bin/fluValidator \
                  --fasta ${ace2_fasta:t} > \
                  ${ace2_fluvalidator}
                sleep 1
              end
              if (! -e ${ace2_fluvalidator} || -z ${ace2_fluvalidator}) then
                echo "ERROR: fluValidator unsuccessful after 3 tries for [${db_name}_${col_name}_${bac_id}]"
              else
                echo "INFO: fluValidator successful for [${db_name}_${col_name}_${bac_id}], built [${ace2_fluvalidator}]"
              endif
            popd >& /dev/null
          endif
        else
          echo "ERROR: [${db_name}_${col_name}_${bac_id}] is missing file [${ace2_fasta}] - Please re-run cas2consed on sample [${db_name},${col_name},${bac_id}]"
        endif
      endif
    endif
  else
      echo "ERROR: [${db_name}_${col_name}_${bac_id}] is not from a registered flu database [${db_name}]"
  endif
end

exit








































end
exit
