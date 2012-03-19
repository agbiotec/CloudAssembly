#!/bin/csh

set project_root = /usr/local/projects/VHTNGS
set sample_data_root = ${project_root}/sample_data_new

echo "database|collection|bac_id|denovo_subtype|ace_subtype|glk_subtype"

foreach bc_rec ( `cat $1 | tr ',' ':' | tr -d '\r' | tr -d ' ' | sort -u` )
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 3`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 1`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 2`
  set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}


  set input_fasta_file_cnt = `ls -1tr ${sample_data}/mapping/consed_with_sanger/*consensus.fasta | wc -l`
  if ( ${input_fasta_file_cnt} > 0 ) then
    set input_fasta_file = `ls -1tr ${sample_data}/mapping/consed_with_sanger/*consensus.fasta | tail -1`
    set ace_subtype = `/usr/local/devel/DAS/software/ElviraStaging/bin/fluValidator --fasta ${input_fasta_file} --report text | grep "^Full Serotype:" | cut -d ':' -f 2`
  else
    set ace_subtype = "HN"
  endif

  set glk_data = `/usr/local/common/Elvira/bin/flam -D ${db_name} -b ${bac_id} --attr "subtype,blinded_number,species_code" -H | cut -f 3- | tr '\t' '|'`
  set glk_subtype = `echo "${glk_data}" | cut -d '|' -f 1`
  set glk_blinded_number = `echo "${glk_data}" | cut -d '|' -f 2`
  set glk_species_code = `echo "${glk_data}" | cut -d '|' -f 3`

  set de_novo_ha = `ls -1 ${sample_data}/assembly_by_segment/HA/HA_100x_contigs.fasta`
  set de_novo_na = `ls -1 ${sample_data}/assembly_by_segment/NA/NA_100x_contigs.fasta`

  set ha_subtype_list = `blastall -p blastn -d /usr/local/projects/GIV/Influenza_full_length_NT/HA_full_length_NT_complete.fa -b 1 -v 1 -m 8 -i ${de_novo_ha} | \
     cut -f 2 | \
     sort -u | \
     join - /usr/local/projects/GIV/Influenza_full_length_NT/HA_gi_to_subtype_map.txt | \
     cut -d ' ' -f 2 | \
     tr -d 'H' | \
     sort -nu | \
     tr '\n' ',' | sed -e 's/,$//' `
  set na_subtype_list = `blastall -p blastn -d /usr/local/projects/GIV/Influenza_full_length_NT/NA_full_length_NT_complete.fa -b 1 -v 1 -m 8 -i ${de_novo_na} | \
     cut -f 2 | \
     sort -u | \
     join - /usr/local/projects/GIV/Influenza_full_length_NT/NA_gi_to_subtype_map.txt | \
     cut -d ' ' -f 2 | \
     tr -d 'N' | \
     sort -nu | \
     tr '\n' ',' | sed -e 's/,$//' `
  echo "${db_name}|${col_name}|${bac_id}|H${ha_subtype_list}N${na_subtype_list}|${ace_subtype}|${glk_subtype}"
end
