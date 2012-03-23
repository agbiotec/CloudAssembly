#TODO Binary dependencies on JCVI's grid
#/usr/local/packages/seq454-2.6/bin
#/usr/local/packages/clc-ngs-cell:/usr/local/packages/clc-bfx-cell:${PATH} -- To be substituted with CAP3
#/usr/local/devel/DAS/users/tstockwe/Ruby/Tools/Bio
#/usr/local/bin/runLinux
#/usr/local/bin/runLinux2
#/usr/local/devel/VIRIFX/software/Grid/bin/grid-deconvolve.pl



csh
use sge
#TODO These should probably be fine if we have the SGE binaries on the master path in the VM.
source /usr/local/sge_current/jcvi/common/settings.csh
setenv PATH /usr/local/packages/seq454-2.6/bin:${PATH}
setenv PATH /usr/local/packages/clc-ngs-cell:/usr/local/packages/clc-bfx-cell:${PATH}
setenv RUBYLIB /usr/local/devel/DAS/users/tstockwe/Ruby/Tools/Bio
#TODO What is this ?
use emboss50
umask 002

#TODO These will have to be pulled by parameters that are being passed to the script
set sispa_pool_name = 20120202_44xH2EU_28xNORV_23xAGB
set sff_file_list = "\
/usr/local/seq454/2012_02_24/R_2012_02_24_13_49_39_FLX02080319_Administrator_022412FULLPLATE20120202/D_2012_02_24_23_38_57_dell-2-0-2_signalProcessing/sff/HJMRC1U01.sff,\
/usr/local/seq454/2012_02_24/R_2012_02_24_13_49_39_FLX02080319_Administrator_022412FULLPLATE20120202/D_2012_02_24_23_38_57_dell-2-0-2_signalProcessing/sff/HJMRC1U02.sff\
"
set fastq_file_list = "\
"


##########################################################################################################

#TODO these directories will need to be created by fabric inside the VM
set project_root = /usr/local/projects/VHTNGS
set scratch_root = /usr/local/scratch/VIRAL/VHTNGS
set barcode_data_root = ${project_root}/barcode_data
set sispa_data_root = ${project_root}/sispa_data_new
set sispa_data_root = ${scratch_root}/sispa_data_new
set sample_data_root = ${project_root}/sample_data_new
set barcode_data_dir = ${barcode_data_root}/${sispa_pool_name}
set sispa_data_dir = ${sispa_data_root}/${sispa_pool_name}
set fastq_dir = ${sispa_data_dir}/fastq
set merged_fastq_dir = ${sispa_data_dir}/merged_fastq
set deconvolved_merged_fastq_dir = ${sispa_data_dir}/deconvolved_merged_fastq
set sff_dir = ${sispa_data_dir}/sff
set merged_sff_dir = ${sispa_data_dir}/merged_sff
set deconvolved_merged_sff_dir = ${sispa_data_dir}/deconvolved_merged_sff
set merged_fastq_file = ${merged_fastq_dir}/merged_solexa_sequence.fastq
set merged_sff_file = ${merged_sff_dir}/merged_454.sff
set barcode_file_name = ${barcode_data_dir}/barcode_metadata_from_GLK.txt

mkdir -p ${scratch_root}

pushd ${project_root}

if ( -d ${barcode_data_root} ) then
else
  mkdir -p ${barcode_data_root}
endif
if ( -d ${sispa_data_root} ) then
else
  mkdir -p ${sispa_data_root}
endif
if ( -d ${sample_data_root} ) then
else
  mkdir -p ${sample_data_root}
endif

if ( -d ${barcode_data_dir} ) then
else
  mkdir -p ${barcode_data_dir}
endif
if ( -d ${sispa_data_dir} ) then
else
  mkdir -p ${sispa_data_dir}
endif


if ( -d ${fastq_dir} ) then
else
  mkdir -p ${fastq_dir}
endif
if ( -d ${merged_fastq_dir} ) then
else
  mkdir -p ${merged_fastq_dir}
endif
if ( -d ${deconvolved_merged_fastq_dir} ) then
else
  mkdir -p ${deconvolved_merged_fastq_dir}
endif


if ( -d ${sff_dir} ) then
else
  mkdir -p ${sff_dir}
endif
if ( -d ${merged_sff_dir} ) then
else
  mkdir -p ${merged_sff_dir}
endif
if ( -d ${deconvolved_merged_sff_dir} ) then
else
  mkdir -p ${deconvolved_merged_sff_dir}
endif


# build tab-separated-file of barcode metadata based on Excel file attached to 454 BugZero #???
# column order is:
# barcode_name, 
# barcode_sequence, 
# bac_id, 
# blinded_number, 
# species, 
# database_name, 
# collection_name,
# optional - sanger data exists? yes or no

#TODO What is kedit ?
kedit ${barcode_file_name}

# I used 
# for 20091215_MCEIRSsamples1to50
# cat /usr/local/projects/VHTNGS/sample_data/MCE_1_50_StandardPipeSFF/barcodes/barcode_metadata_from_GLK.txt | \
# gawk '{printf("%s\t%s\t%s\n",$0,"giv3","MCE");}' > ${barcode_file_name}
# for 20090205_HIsamples6to100
# cat /usr/local/projects/VHTNGS/sample_data/HI_6_100_StandardPipeSFF/barcodes/barcode_metadata_from_GLK.txt | \
# gawk '{printf("%s\t%s\t%s\n",$0,"giv3","HI");}' > ${barcode_file_name}
# and for 20091005_AVIAN113
# cat sample_data/AVIAN_113_StandardPipeSFF/barcodes/barcode_metadata_from_GLK.txt | \
#   gawk '{if ($4 ~ /\-AK\-/){c="AK";}\
#          else if($4 ~ /\-RF\-/){c="RF";}\
#          else if($4 ~ /\-SJC\-/){c="SJC";}\
#          else if($4 ~ /\-OHC\-/){c="OHC";}\
#          else if($4 ~ /\-DB\-/){c="DB";}\
#          else if($4 ~ /\_CC\_/){c="CC";}\
#          printf("%s\t%s\t%s\n",$0,"giv3",c);}' > ${barcode_file_name}

if ( -e ${barcode_file_name}.pat ) then
  rm ${barcode_file_name}.pat
endif
touch ${barcode_file_name}.pat
cat ${barcode_file_name} | \
  gawk '{mm=int(length($2)/10.0); printf(">%s <mismatch=%d>\n%s\n", $1, mm, $2);}' \
  >> ${barcode_file_name}.pat




########################## 454 SFF SISPA DATA PROCESSING #####################
# 454 sff data merging, deconvolution, trimming, and non-redundant filtering

# symlink or copy the 454 sff data

# merge the 454 sff data using grid resource 

# check that all is finished, and went ok

#TODO No problem here, JCVI storage tricks - we use the files straight up on the VM
# if sff files still on tier 1, can do this from any node
foreach sff_file (`echo ${sff_file_list} | tr -d ' ' | tr ',' '\n' | sort -u`)
  ln -s ${sff_file} ${sff_dir}/${sff_file:t}
end

# if sff files not on tier 1, do this from archive1
foreach sff_file (`echo ${sff_file_list} | tr -d ' ' | tr ',' '\n' | sort -u`)
  cp ${sff_file} ${sff_dir}/${sff_file:t}
end

#TODO The "runLinux" and "runLinux2" cmds need to be substituted by plain qsubs
#This merges all the sff files in the directory
runLinux2 \
  --output ${merged_sff_file}_sfffile_merging.stdout \
  --error ${merged_sff_file}_sfffile_merging.stderr \
  --project 810001 \
  --length fast \
  #TODO This binary needs to go to the VM as well (gets all sff in a dir and merges them)
  --commandline "/usr/local/packages/seq454-2.6/bin/sfffile -o ${merged_sff_file} ${sff_dir}/*.sff"

cat ${merged_sff_file}_sfffile_merging.std*


############ The NEW WAY - USING GRID DECONVOLVE #########################

set key = `sffinfo ${merged_sff_file} | \
             head -n 100 | \
             grep "Key Sequence:" | \
             cut -d ':' -f 2 | \
             sed -e 's/\s//g' | \
             gawk '{printf("%s\n",$1);}'`
set keylength = `sffinfo ${merged_sff_file} | \
             head -n 100 | \
             grep "Key Sequence:" | \
             cut -d ':' -f 2 | \
             sed -e 's/\s//g' | \
             gawk '{printf("%s\n",length($1));}'`

#TODO Here we will need SGE for the "grid-deconvolve.pl" - what dependencies does this .pl have though? 
runLinux2 \
  --output ${merged_sff_file}_grid_deconvolve.stdout \
  --error ${merged_sff_file}_grid_deconvolve.stderr \
  --project 810001 \
  --length fast \
  --commandline "/usr/local/devel/VIRIFX/software/Grid/bin/grid-deconvolve.pl --project 810001 --infile ${merged_sff_file} --pattern ${barcode_file_name}.pat --queue fast.q --tmpdir ${merged_sff_file}_deconvolver_tmp --outdir ${merged_sff_file}_deconvolver_test --errdir ${merged_sff_file}_deconvolver_err --trim_points_only --readlength 50 --clamplength 6 --keylength 4 --verbose >& ${merged_sff_file}_deconvolver.log"

# Now wait until this is finished...  takes a while...  Be sure to check log file(s)
# If any exits due to errors occurred, you will need to re-run the command...

#TODO Do a grep for errors here instead of "cat". Do an if conditional to repeat the "grid-deconvolve.pl"
# the grep returns any errors.
cat ${merged_sff_file}_deconvolver.log | more

#TODO Do we re-use the sfffile utility here !!!
# use the barcode deconvolver output to bin and trim the sff data
foreach bc ( `cat ${barcode_file_name} | cut -f 1`)
  if ( -e ${merged_sff_file}_deconvolver_test/${bc}/${bc}.trim ) then
    echo "INFO: Binning and trimming 454 data for SISPA pool [${sispa_pool_name}] barcode [${bc}]"
    sfffile -o ${deconvolved_merged_sff_dir}/trim_${bc}.sff \
      -i ${merged_sff_file}_deconvolver_test/${bc}/${bc}.trim \
      -t ${merged_sff_file}_deconvolver_test/${bc}/${bc}.trim \
      ${merged_sff_file}
  endif
end

############################# COPY 454 SISPA DATA TO SAMPLE AREAS ##########################

#TODO what are we doing here, copying barcoded data to a new separate directory?

foreach bc_rec ( `cat ${barcode_file_name} | tr ' ' '_' | tr '\t' ':' ` )
  set bc       = `echo "${bc_rec}" | cut -d ':' -f 1`
  set bc_seq   = `echo "${bc_rec}" | cut -d ':' -f 2`
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 3`
  set blinded  = `echo "${bc_rec}" | cut -d ':' -f 4`
  set species  = `echo "${bc_rec}" | cut -d ':' -f 5`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 6`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 7`
  set bac_id_len = `echo ${bac_id} | tr -d '\n' | wc -c`
  set db_name_len = `echo ${db_name} | tr -d '\n' | wc -c`
  set col_name_len = `echo ${col_name} | tr -d '\n' | wc -c`
  if (${bac_id_len} > 0 && ${db_name_len} > 0 && ${col_name_len} > 0) then
    echo "INFO: Copying 454 data to sample area for SISPA pool [${sispa_pool_name}] barcode [${bc}]"
    set deconvolved_sff = ${deconvolved_merged_sff_dir}/trim_${bc}.sff
    set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}
    set sample_data_solexa = ${sample_data}/solexa
    set sample_data_sff = ${sample_data}/sff

    if ( -d ${sample_data} ) then
    else
      mkdir -p ${sample_data}
    endif

    if ( -d ${sample_data_sff} ) then
    else
      mkdir -p ${sample_data_sff}
    endif

    if ( -e ${deconvolved_sff} ) then
      echo "INFO: copying sff data to [${db_name}/${col_name}/${bac_id}]"
      set key = `sffinfo ${deconvolved_sff} | \
                   head -n 100 | \
                   grep "Key Sequence:" | \
                   cut -d ':' -f 2 | \
                   sed -e 's/\s//g' | \
                   gawk '{printf("%s\n",$1);}'`
      cp ${deconvolved_sff} ${sample_data_sff}/${sispa_pool_name}_trim_${bc}.${key}.sff
    endif
  else
    echo "WARNING:  No 454 sample data transfer for bc_rec [${bc_rec}]"
  endif
end

########################## SETUP SANGER DIRECTORIES, AND IF SANGER DATA EXISTS FOR SAMPLES, COPY IT ##################################

csh
umask 002

set sispa_pool_name = 20090205_HIsamples6to100
set sispa_pool_name = 20110815_47xVEEV_6xARBO_3xJC_1xJEV_1xYFV
set sispa_pool_name = 20110816_65xMPV_7xRSV

set project_root = /usr/local/projects/VHTNGS
set sample_data_root = ${project_root}/sample_data_new


set barcode_data_root = ${project_root}/barcode_data
set barcode_data_dir = ${barcode_data_root}/${sispa_pool_name}
set barcode_file_name = ${barcode_data_dir}/barcode_metadata_from_GLK.txt

foreach bc_rec ( `cat ${barcode_file_name} | tr ' ' '_' | tr '\t' ':' | cut -d ':' -f 3,6,7 | sort -u | grep -v "POSCTRL"`)
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 1`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 2`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 3`

  echo "INFO: setting up sanger directory for [${db_name}/${col_name}/${bac_id}]"

  set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}
  set sample_data_sanger = ${sample_data}/sanger

  if ( -d ${sample_data_sanger} ) then
  else
    mkdir -p ${sample_data_sanger}
  endif
end


cat ${barcode_file_name} | \
  gawk -F'\t' '{if($8 == "YES"){print $0;}}' | \
  grep -v "POSCTRL" | \
  tr ' ' '_' | \
  tr '\t' ':' | \
  cut -d ':' -f 3,6,7 | \
  sort -u | \
  gawk -F':' '{printf("%s,%s,%s\n",$2,$3,$1);}' > ~/for_vhtngs/${sispa_pool_name}_tuples_with_sanger_data.txt

if ( `cat  ~/for_vhtngs/${sispa_pool_name}_tuples_with_sanger_data.txt | wc -l` > 0 ) then
  /usr/local/devel/DAS/software/Elvira/bin/pullAndTrimSangerDataForCLCAssembly \
    -in ~/for_vhtngs/${sispa_pool_name}_tuples_with_sanger_data.txt 
endif

exit


########################## CONSOLIDATE SAMPLE DATA ##################################
csh
set sispa_pool_name = 20090205_HIsamples6to100
set sispa_pool_name = 20090205_34xDW_5xHI_2xUNKNOWN_samples
set sispa_pool_name = 20090901_20xDW09_3xCC_12xSW_samples
set sispa_pool_name = 20091005_AVIAN113
set sispa_pool_name = 20091215_MCEIRSsamples1to50
set sispa_pool_name = 20100305_1_86xAK_1xSW
set sispa_pool_name = 20100305_2_32xAK_24xCOH_1xMCWS_2xKHBAT_1xSW
set sispa_pool_name = 20100416_B_57xMCE_14xAK_5xCOH_4xVEEV_3xINS_1xCC_1xWKS
set sispa_pool_name = 20100226_B_79xAK_1xMCE_3xARBO_3xVEEV_1xSW
set sispa_pool_name = 20100528_84xFBS_8xINS_1xJG
set sispa_pool_name = 20100813_22xGCV_30xHADV_40xVZV_16xMPV

set project_root = /usr/local/projects/VHTNGS
set sample_data_root = ${project_root}/sample_data_new


set barcode_data_root = ${project_root}/barcode_data
set barcode_data_dir = ${barcode_data_root}/${sispa_pool_name}
set barcode_file_name = ${barcode_data_dir}/barcode_metadata_from_GLK.txt

# set barcode_file_name = ${project_root}/ALL_SISPA_POOLS_${bc_part}_of_${num_bc_parts}_barcode_metadata_from_GLK.txt
# set barcode_file_name = ${project_root}/HAS_SANGER_barcode_metadata_from_GLK.txt

# set triplet_file = /home/tstockwe/for_avian_flu/20100730_data_deliveries/giv3_samples_with_edits.txt
# set triplet_file = /home/tstockwe/for_avian_flu/20100901_new_avian_samples_with_closure_reads.txt
# set triplet_file =  /home/tstockwe/for_avian_flu/20100914_samples_with_sanger_data.txt
# set triplet_file =  /home/tstockwe/for_avian_flu/20100921_FBS_samples_w_sanger.txt
# set triplet_file =  /home/tstockwe/for_avian_flu/20100922_veev_combined_samples.txt
# set triplet_file =  /home/dkatzel/for_tim/20101006.giv3.newSanger.tuples.lst
# set triplet_file =  /home/tstockwe/for_avian_flu/20101019_VHTNGS_139_samples.txt
# set triplet_file = /home/tstockwe/for_avian_flu/20101104_samples_with_closure_reads.txt
# set triplet_file = /home/tstockwe/for_avian_flu/20101105_samples_with_bad_refs.txt
# set triplet_file = /home/tstockwe/for_avian_flu/20101121_samples_with_closure_reads.txt
# set triplet_file = /home/tstockwe/for_veev/20110414_samples_for_VHTNGS_249.txt
set triplet_file = /home/tstockwe/for_vda/20110416_VHTNGS_250_samples.txt

foreach bc_rec ( `cat ${triplet_file} | tr ',' ':' | sort -u` )
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 3`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 1`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 2`

foreach bc_rec ( `cat ${barcode_file_name} | tr ' ' '_' | tr '\t' ':' | cut -d ':' -f 3,6,7 | sort -u | grep -v "POSCTRL"`)
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 1`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 2`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 3`

  echo "INFO: processing data for [${db_name}/${col_name}/${bac_id}]"

  set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}
  set sample_data_solexa = ${sample_data}/solexa
  set sample_data_sff = ${sample_data}/sff
  set sample_data_sanger = ${sample_data}/sanger
  set sample_mapping_dir = ${sample_data}/mapping
  set final_fasta_reads = ${sample_mapping_dir}/${db_name}_${col_name}_${bac_id}_final.fasta

  set sample_data_merged_solexa = ${sample_data}/merged_solexa
  set sample_data_merged_sff = ${sample_data}/merged_sff
  set sample_data_merged_sanger = ${sample_data}/merged_sanger

  set sample_data_merged_sff_file = ${sample_data_merged_sff}/${db_name}_${col_name}_${bac_id}.sff
  set sample_data_merged_sanger_file = ${sample_data_merged_sanger}/${db_name}_${col_name}_${bac_id}.fasta
  set sample_data_merged_solexa_file = ${sample_data_merged_solexa}/${db_name}_${col_name}_${bac_id}.fastq
  set sample_data_merged_solexa_file_t = ${sample_data_merged_solexa}/${db_name}_${col_name}_${bac_id}.fastq.trimpoints
  set sample_data_merged_solexa_file_u = ${sample_data_merged_solexa}/${db_name}_${col_name}_${bac_id}.fastq.untrimmed

  if ( -d ${sample_data_merged_sff} ) then
  else
    mkdir -p ${sample_data_merged_sff}
  endif

  if ( -d ${sample_data_merged_solexa} ) then
  else
    mkdir -p ${sample_data_merged_solexa}
  endif

  if ( -d ${sample_data_sanger} ) then
  else
    mkdir -p ${sample_data_sanger}
  endif

  if ( -d ${sample_data_merged_sanger} ) then
  else
    mkdir -p ${sample_data_merged_sanger}
  endif

  foreach key (`ls -1 ${sample_data_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
    sfffile -o ${sample_data_merged_sff_file:r}.${key}.sff \
      ${sample_data_sff}/*_trim_*.${key}.sff
  end


  cat ${sample_data_solexa}/*_nr_trim_*.fastq | \
    gawk '{t=NR % 4;\
           if(t==1){\
             if(length(sid) > 0 ) {printf("%s\t%s\t%s\t%s\n", sid,s,sid,q)};\
             sid=substr($0,2);\
           }\
           else if (t==2){s=$0;}\
           else if (t==3){qid=sid;}\
           else if (t==0){q=$0;}\
          }\
          END {\
             if(length(sid) > 0 ) {printf("%s\t%s\t%s\t%s\n", sid,s,sid,q)};\
          }' | \
    sort | \
    gawk -F'\t' '{printf("@%s\n%s\n+%s\n%s\n", $1, $2, "", $4);}' \
      > ${sample_data_merged_solexa_file}

  cat ${sample_data_solexa}/*_trim_*.fastq.trimpoints | \
    sort \
    > ${sample_data_merged_solexa_file_t}

  cat ${sample_data_solexa}/*_trim_*.fastq.untrimmed | \
    gawk '{t=NR % 4;\
           if(t==1){\
             if(length(sid) > 0 ) {printf("%s\t%s\t%s\t%s\n", sid,s,sid,q)};\
             sid=substr($0,2);\
           }\
           else if (t==2){s=$0;}\
           else if (t==3){qid=sid;}\
           else if (t==0){q=$0;}\
          }\
          END {\
             if(length(sid) > 0 ) {printf("%s\t%s\t%s\t%s\n", sid,s,sid,q)};\
          }' | \
    sort | \
    gawk -F'\t' '{printf("@%s\n%s\n+%s\n%s\n", $1, $2, "", $4);}' \
      > ${sample_data_merged_solexa_file_u}


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

################### THIS IS THE START OF VIRUS SPECIFIC HANDLING ###############
csh
setenv RUBYLIB /usr/local/devel/DAS/users/tstockwe/Ruby/Tools/Bio
setenv PATH /usr/local/packages/clc-ngs-cell:/usr/local/packages/clc-bfx-cell:${PATH}
use emboss50
umask 002

#TODO Does it get the very last value set here - could we parametrize these variables.
set sispa_pool_name = 20090205_HIsamples6to100
set sispa_pool_name = 20090205_34xDW_5xHI_2xUNKNOWN_samples
set sispa_pool_name = 20090901_20xDW09_3xCC_12xSW_samples
set sispa_pool_name = 20091005_AVIAN113
set sispa_pool_name = 20091215_MCEIRSsamples1to50
set sispa_pool_name = 20100305_1_86xAK_1xSW
set sispa_pool_name = 20100305_2_32xAK_24xCOH_1xMCWS_2xKHBAT_1xSW
set sispa_pool_name = 20100416_B_57xMCE_14xAK_5xCOH_4xVEEV_3xINS_1xCC_1xWKS
set sispa_pool_name = 20100226_B_79xAK_1xMCE_3xARBO_3xVEEV_1xSW
set sispa_pool_name = 20100528_84xFBS_8xINS_1xJG
set sispa_pool_name = 20100813_22xGCV_30xHADV_40xVZV_16xMPV
set sispa_pool_name = 20100805_89xWBC
set sispa_pool_name = 20110610_1_46xJBC
set sispa_pool_name = 20110707_104xMPA_2xMG_1xSW_6xNORV

set project_root = /usr/local/projects/VHTNGS
set sample_data_root = ${project_root}/sample_data_new

set barcode_data_root = ${project_root}/barcode_data
set barcode_data_dir = ${barcode_data_root}/${sispa_pool_name}
set barcode_file_name = ${barcode_data_dir}/barcode_metadata_from_GLK.txt


# under ref_dir, look for <seg>.fasta
# under blast_db_dir, look for <seg>_full_length_NT_complete.fa, must have been run through formatdb!
# cd  /usr/local/projects/VHTNGS/reference_data/
# e.g., formatdb -p F -o T -i veev_full_length_NT/MAIN_full_length_NT_complete.fa
# set vdb = hadv
# formatdb -p F -o T -i ${vdb}_full_length_NT/MAIN_full_length_NT_complete.fa
# cat ${vdb}_full_length_NT/MAIN_full_length_NT_complete.fa | \
#   gawk -v l=0 '{if($0 ~ />/){l=l+1;printf(">MAIN_%d %s\n",l,substr($0,2));}else{print $0;}}' > \
#   ${vdb}/MAIN.fasta
# 
set segments = "VP1 VP2 VP3 VP4 NSP1 VP6 NSP3 NSP2 VP7 NSP4 NSP5"
foreach seg ( `echo ${segments} | tr ' ' '\n'` )
  grep ${seg} /home/tstockwe/for_rtv/Tim_rotavirus_seq_segAssignment.txt | cut -d '.' -f 1,2 > ${seg}_accessions.list
  fnafile -i /home/tstockwe/for_rtv/${seg}_accessions.list -o /home/tstockwe/for_rtv/${seg}.fasta /home/tstockwe/for_rtv/ALLRECORDS.fna
  cat /home/tstockwe/for_rtv/${seg}.fasta | \
    gawk -v s=${seg} -v l=0 \
      '{if($0 ~ />/){l=l+1;printf(">%s_%d %s\n",s, l,substr($0,2));}else{print $0;}}' > \
    /usr/local/projects/VHTNGS/reference_data/rota_virus/${seg}.fasta
  cat /home/tstockwe/for_rtv/${seg}.fasta > \
    /usr/local/projects/VHTNGS/reference_data/rota_virus_full_length_NT/${seg}_full_length_NT_complete.fa
  pushd /usr/local/projects/VHTNGS/reference_data/rota_virus_full_length_NT  >& /dev/null
    formatdb -i ${seg}_full_length_NT_complete.fa -p F -o T 
  popd >& /dev/null
end

set segments = "VP1 VP2 VP3 VP4 NSP1 VP6 NSP3 NSP2 VP7 NSP4 NSP5"
foreach seg ( `echo ${segments} | tr ' ' '\n'` )
  cat /home/tstockwe/for_rtv/uclust_work/${seg}_AllCompleteCDSs_fasta_sorted_clusters_sorted_uc_accessions.fasta | \
    gawk -v s=${seg} -v l=0 \
      '{if($0 ~ />/){l=l+1;printf(">%s_%d %s\n",s, l,substr($0,2));}else{print $0;}}' > \
    /usr/local/projects/VHTNGS/reference_data/rota_virus/${seg}.fasta
  cat /home/tstockwe/for_rtv/uclust_work/${seg}_AllCompleteCDSs_fasta_sorted_clusters_sorted_uc_accessions.fasta > \
    /usr/local/projects/VHTNGS/reference_data/rota_virus_full_length_NT/${seg}_full_length_NT_complete.fa
  pushd /usr/local/projects/VHTNGS/reference_data/rota_virus_full_length_NT  >& /dev/null
    formatdb -i ${seg}_full_length_NT_complete.fa -p F -o T 
  popd >& /dev/null
end

# seg_cov is the segment followed by bps in 100x coverage
# for unsegmented viruses, use MAIN as segment name

# set barcode_file_name = ${project_root}/ALL_SISPA_POOLS_${bc_part}_of_${num_bc_parts}_barcode_metadata_from_GLK.txt
# set barcode_file_name = ${project_root}/ALL_SISPA_POOLS_barcode_metadata_from_GLK.txt
# set barcode_file_name = ${project_root}/HAS_SANGER_${bc_part}_of_${num_bc_parts}_barcode_metadata_from_GLK.txt

foreach bc_rec ( `cat ${barcode_file_name} | grep -v "POSCTRL" | tr ' ' '_' | tr '\t' ':' | cut -d ':' -f 3,6,7 | sort -u | grep -v "LASKEN" | grep -v "givtest" | grep -v "vda" | grep -v "giv2"` )
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 1`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 2`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 3`

# set triplet_file = /home/tstockwe/for_avian_flu/20100730_data_deliveries/giv3_samples_with_edits.txt
# set triplet_file = /home/tstockwe/for_avian_flu/20100901_new_avian_samples_with_closure_reads.txt
# set triplet_file =  /home/tstockwe/for_avian_flu/20100914_samples_with_sanger_data.txt
# set triplet_file =  /home/tstockwe/for_avian_flu/20100921_FBS_samples_w_sanger.txt
# set triplet_file =  /home/tstockwe/for_avian_flu/20100922_veev_combined_samples.txt
# set triplet_file =  /home/dkatzel/for_tim/20101006.giv3.newSanger.tuples.lst
# set triplet_file =  /home/tstockwe/for_avian_flu/20101019_VHTNGS_139_samples.txt
# set triplet_file =  /home/tstockwe/for_avian_flu/20101020_bad_HI_HA_vectorstrip_samples.txt
# set triplet_file =  /home/tstockwe/for_avian_flu/20101020_bad_HI_PA_vectorstrip_samples.txt
# set triplet_file = /home/tstockwe/for_avian_flu/20101104_samples_with_closure_reads.txt
# set triplet_file = /home/tstockwe/for_avian_flu/20101104_samples_with_bad_refs.txt
# set triplet_file = /home/tstockwe/for_avian_flu/20101104_samples_with_bad_refs_p2.txt
# set triplet_file = /home/tstockwe/for_avian_flu/20101105_samples_with_bad_refs.txt
# set triplet_file = /home/tstockwe/for_avian_flu/20101121_samples_with_closure_reads.txt
# set triplet_file = /home/tstockwe/for_veev/20110414_samples_for_VHTNGS_249.txt
# set triplet_file = /home/tstockwe/for_vhtngs/20111114_bad_refs_tuples.txt
set triplet_file = /home/tstockwe/for_vhtngs/20111121_samples_with_solexa_data_problems_tuples.txt

foreach bc_rec ( `cat ${triplet_file} | tr ',' ':' | sort -u | grep -v "LASKEN" | grep -v "givtest" | grep -v "vda"` )
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 3`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 1`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 2`

foreach bc_rec ( `cat ${barcode_file_name} | grep -v "POSCTRL" | tr ' ' '_' | tr '\t' ':' | cut -d ':' -f 3,6,7 | sort -u | grep -v "LASKEN" | grep -v "givtest" | grep -v "vda" | grep -v "giv2"` )
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 1`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 2`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 3`

  set flu_a = 0
  switch ($db_name)
    case barda:
      echo "Using Influenza A reference data for database [${db_name}]"
      set ref_dir = /usr/local/projects/VHTNGS/reference_data/influenza_a_virus
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/influenza_a_virus_full_length_NT
      set segments = "HA MP NA NP NS PA PB1 PB2"
      set seg_cov = "HA:175000 MP:100000 NA:145000 NP:155000 NS:89000 PA:220000 PB1:235000 PB2:235000"
      set flu_a = 1
    breaksw
    case giv:
      echo "Using Influenza A reference data for database [${db_name}]"
      set ref_dir = /usr/local/projects/VHTNGS/reference_data/influenza_a_virus
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/influenza_a_virus_full_length_NT
      set segments = "HA MP NA NP NS PA PB1 PB2"
      set seg_cov = "HA:175000 MP:100000 NA:145000 NP:155000 NS:89000 PA:220000 PB1:235000 PB2:235000"
      set flu_a = 1
    breaksw
    case giv3:
      echo "Using Influenza A reference data for database [${db_name}]"
      set ref_dir = /usr/local/projects/VHTNGS/reference_data/influenza_a_virus
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/influenza_a_virus_full_length_NT
      set segments = "HA MP NA NP NS PA PB1 PB2"
      set seg_cov = "HA:175000 MP:100000 NA:145000 NP:155000 NS:89000 PA:220000 PB1:235000 PB2:235000"
      set flu_a = 1
    breaksw
    case piv:
      echo "Using Influenza A reference data for database [${db_name}]"
      set ref_dir = /usr/local/projects/VHTNGS/reference_data/influenza_a_virus
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/influenza_a_virus_full_length_NT
      set segments = "HA MP NA NP NS PA PB1 PB2"
      set seg_cov = "HA:175000 MP:100000 NA:145000 NP:155000 NS:89000 PA:220000 PB1:235000 PB2:235000"
      set flu_a = 1
    breaksw
    case swiv:
      echo "Using Influenza A reference data for database [${db_name}]"
      set ref_dir = /usr/local/projects/VHTNGS/reference_data/influenza_a_virus
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/influenza_a_virus_full_length_NT
      set segments = "HA MP NA NP NS PA PB1 PB2"
      set seg_cov = "HA:175000 MP:100000 NA:145000 NP:155000 NS:89000 PA:220000 PB1:235000 PB2:235000"
      set flu_a = 1
    breaksw
    case rtv:
      echo "Using Rotavirus reference data for database [${db_name}]"
      set ref_dir      = /usr/local/projects/VHTNGS/reference_data/rota_virus
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/rota_virus_full_length_NT
      set segments = "VP1 VP2 VP3 VP4 NSP1 VP6 NSP3 NSP2 VP7 NSP4 NSP5"
      set seg_cov = "VP1:326700 VP2:268600 VP3:255000 VP4:232400 NSP1:151800 VP6:132300 NSP3:104100 NSP2:102200 VP7:103000 NSP4:70800 NSP5:62900"
      set flu_a = 0
    breaksw
    case gcv:
      echo "Using Coronavirus reference data for database [${db_name}]"
      set ref_dir      = /usr/local/projects/VHTNGS/reference_data/corona_virus
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/corona_virus_full_length_NT
      set segments = "MAIN"
      set seg_cov = "MAIN:3000000"
      set flu_a = 0
    breaksw
    case veev:
      echo "Using VEEV reference data for database [${db_name}]"
      set ref_dir      = /usr/local/projects/VHTNGS/reference_data/veev
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/veev_full_length_NT
      set segments = "MAIN"
      set seg_cov = "MAIN:1200000"
      set flu_a = 0
    breaksw
    case hadv:
      echo "Using HADV reference data for database [${db_name}]"
      set ref_dir      = /usr/local/projects/VHTNGS/reference_data/hadv
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/hadv_full_length_NT
      set segments = "MAIN"
      set seg_cov = "MAIN:4500000"
      set flu_a = 0
    breaksw
    case mpv:
      echo "Using MPV reference data for database [${db_name}]"
      set ref_dir      = /usr/local/projects/VHTNGS/reference_data/mpv
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/mpv_full_length_NT
      set segments = "MAIN"
      set seg_cov = "MAIN:1335000"
      set flu_a = 0
    breaksw
    case norv:
      echo "Using NORV reference data for database [${db_name}]"
      set ref_dir      = /usr/local/projects/VHTNGS/reference_data/norv
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/norv_full_length_NT
      set segments = "MAIN"
      set seg_cov = "MAIN:774600"
      set flu_a = 0
    breaksw
    case vzv:
      echo "Using VZV reference data for database [${db_name}]"
      set ref_dir      = /usr/local/projects/VHTNGS/reference_data/vzv
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/vzv_full_length_NT
      set segments = "MAIN"
      set seg_cov = "MAIN:12500000"
      set flu_a = 0
    breaksw
    case rsv:
      echo "Using RSV reference data for database [${db_name}]"
      set ref_dir      = /usr/local/projects/VHTNGS/reference_data/rsv
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/rsv_full_length_NT
      set segments = "MAIN"
      set seg_cov = "MAIN:1530000"
      set flu_a = 0
    breaksw
    case jev:
      echo "Using JEV reference data for database [${db_name}]"
      set ref_dir      = /usr/local/projects/VHTNGS/reference_data/jev
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/jev_full_length_NT
      set segments = "MAIN"
      set seg_cov = "MAIN:1100000"
      set flu_a = 0
    breaksw
    case yfv:
      echo "Using YFV reference data for database [${db_name}]"
      set ref_dir      = /usr/local/projects/VHTNGS/reference_data/yfv
      set blast_db_dir = /usr/local/projects/VHTNGS/reference_data/yfv_full_length_NT
      set segments = "MAIN"
      set seg_cov = "MAIN:1090000"
      set flu_a = 0
    breaksw
    default:
      echo "Using no reference data for database [${db_name}]"
      set ref_dir      = ""
      set blast_db_dir = ""
      set segments = ""
      set seg_cov = ""
      set flu_a = 0
    breaksw
  endsw

  echo "INFO: processing data for [${db_name}/${col_name}/${bac_id}]"
  set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}

  set sample_data_merged_solexa = ${sample_data}/merged_solexa
  set sample_data_merged_sff = ${sample_data}/merged_sff
  set sample_data_merged_sanger = ${sample_data}/merged_sanger
  set sample_data_merged_solexa_file = ${sample_data_merged_solexa}/${db_name}_${col_name}_${bac_id}.fastq
  set sample_data_merged_solexa_file_t = ${sample_data_merged_solexa}/${db_name}_${col_name}_${bac_id}.fastq.trimpoints
  set sample_data_merged_solexa_file_u = ${sample_data_merged_solexa}/${db_name}_${col_name}_${bac_id}.fastq.untrimmed
  set sample_data_merged_sff_file = ${sample_data_merged_sff}/${db_name}_${col_name}_${bac_id}.sff
  set sample_data_merged_sanger_file = ${sample_data_merged_sanger}/${db_name}_${col_name}_${bac_id}.fasta

  echo "INFO: converting sff to fasta for [${db_name}/${col_name}/${bac_id}]"
  if ( -e ${sample_data_merged_sff_file}.fna ) then
    rm ${sample_data_merged_sff_file}.fna
  endif
  touch ${sample_data_merged_sff_file}.fna
  foreach key (`ls -1 ${sample_data_merged_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
    sffinfo -s ${sample_data_merged_sff_file:r}.${key}.sff | \
      grep -v " length=0 " \
      >> ${sample_data_merged_sff_file}.fna 
  end

  if ( `cat ${sample_data_merged_sff_file}.fna | wc -l` > 0 ) then
    echo "INFO: formatdb of SFF fasta for [${db_name}/${col_name}/${bac_id}]"
    formatdb -p F -i ${sample_data_merged_sff_file}.fna
  endif

  if ( `cat ${sample_data_merged_sanger_file} | wc -l` > 0 ) then
    echo "INFO: formatdb of Sanger fasta for [${db_name}/${col_name}/${bac_id}]"
    formatdb -p F -i ${sample_data_merged_sanger_file}
  endif

  set tblastx_outdir = ${sample_data}/tblastx_output
  if ( -d ${tblastx_outdir} ) then
  else
    mkdir -p ${tblastx_outdir}
  endif

  foreach seg ( `echo ${segments} | tr ' ' '\n' ` )
    echo "INFO: tblastx segment data [${seg}] against SFF and Sanger reads databases for [${db_name}/${col_name}/${bac_id}]"
    set ref_fna = ${ref_dir}/${seg}.fasta

    if ( `cat ${sample_data_merged_sff_file}.fna | wc -l` > 0 ) then
      set blastdb = ${sample_data_merged_sff_file}.fna
      set blastout = ${tblastx_outdir}/${seg}.out
      blastall \
        -p tblastx \
        -d ${blastdb} \
        -i ${ref_fna} \
        -m 9 \
        -b 100000 \
        -v 100000 \
        -o ${blastout}
    else
      touch ${blastout}
    endif

    if ( `cat ${sample_data_merged_sanger_file} | wc -l` > 0 ) then
      set blastdb = ${sample_data_merged_sanger_file}
      set blastout = ${tblastx_outdir}/${seg}_sanger.out
      blastall \
        -p tblastx \
        -d ${blastdb} \
        -i ${ref_fna} \
        -m 9 \
        -b 100000 \
        -v 100000 \
        -o ${blastout}
    else
      touch ${blastout}
    endif
  end

  set noninter_chimera_list = ${tblastx_outdir}/noninter_chimera_reads.uaccno_list
  set inter_chimera_list = ${tblastx_outdir}/inter_chimera_reads.uaccno_list
  foreach seg ( `echo ${segments} | tr ' ' '\n' ` )
    echo "INFO: parsing tblastx output for segment [${seg}] against [${db_name}/${col_name}/${bac_id}]"
    set blastout = ${tblastx_outdir}/${seg}.out
    set blastout_sanger = ${tblastx_outdir}/${seg}_sanger.out
    set nonintra_chimera_list = ${tblastx_outdir}/${seg}_nonintra_chimera_reads.uaccno_list
    set intra_chimera_list = ${tblastx_outdir}/${seg}_intra_chimera_reads.uaccno_list
    if ( ${flu_a} > 0 ) then
      cat ${blastout} ${blastout_sanger} | \
        gawk '{if($0 !~ "#" && $3>60 && $4 > 25 ) {if(($7-$8)*($9-$10)>0){o=1;d=$8-$10;}else{o=0;d=$8+$10;}{printf("%s\t%s\t%s\t%06d\n",$1,$2, o,d);}}}' | \
        sort -g | \
        uniq | \
        gawk '{if( $1==q && $2==s && $3==o && sqrt(($4-d)^2) < 6){d=$4;}else {print $0;q=$1;s=$2;o=$3;d=$4;}}' | \
        cut -f 1,2 | \
        uniq -c | \
        grep " 1 " | \
        gawk '{print $3}' | \
        sort | \
        uniq > ${nonintra_chimera_list}
      cat ${blastout} ${blastout_sanger} | \
        gawk '{if($0 !~ "#" && $3>60 && $4 > 25 ) {if(($7-$8)*($9-$10)>0){o=1;d=$8-$10;}else{o=0;d=$8+$10;}{printf("%s\t%s\t%s\t%06d\n",$1,$2, o,d);}}}' | \
        sort -g | \
        uniq | \
        gawk '{if( $1==q && $2==s && $3==o && sqrt(($4-d)^2) < 6){d=$4;}else {print $0;q=$1;s=$2;o=$3;d=$4;}}' | \
        cut -f 1,2 | \
        uniq -c | \
        grep -v " 1 " | \
        gawk '{print $3}' | \
        sort | \
        uniq > ${intra_chimera_list}
    else
      cat ${blastout} ${blastout_sanger} | \
        gawk '{if($0 !~ "#" && $3>60 && $4 > 25 ) {print $2;}}' | \
        sort | \
        uniq > ${nonintra_chimera_list}
      echo "" > ${intra_chimera_list}     
    endif
  end
  cat ${tblastx_outdir}/*_nonintra_chimera_reads.uaccno_list | \
    sort | \
    uniq -c | \
    tr '\t' ' ' | \
    grep " 1 " | \
    gawk '{print $2}' > ${noninter_chimera_list}
  cat ${tblastx_outdir}/*_nonintra_chimera_reads.uaccno_list | \
    sort | \
    uniq -c | \
    tr '\t' ' ' | \
    grep -v " 1 " | \
    gawk '{print $2}' > ${inter_chimera_list}

  foreach seg ( `echo ${segments} | tr ' ' '\n' ` )
    set nonintra_chimera_list = ${tblastx_outdir}/${seg}_nonintra_chimera_reads.uaccno_list
    set non_chimera_list = ${tblastx_outdir}/${seg}_nonchimera_reads.uaccno_list
    join -1 1 -2 1 \
      ${noninter_chimera_list} \
      ${nonintra_chimera_list} > \
      ${non_chimera_list}
    echo "INFO: creating sff of non_chimeric reads from reads matching segment [${seg}] for [${db_name}/${col_name}/${bac_id}]"

    set sample_seg_sff_file = ${sample_data_merged_sff}/${db_name}_${col_name}_${bac_id}_nonchimera_${seg}.sff
    foreach key (`ls -1 ${sample_data_merged_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
      sfffile \
        -i ${non_chimera_list} \
        -o ${sample_seg_sff_file:r}.${key}.sff \
        ${sample_data_merged_sff_file:r}.${key}.sff
    end

    set sample_seg_sanger_file = ${sample_data_merged_sanger}/${db_name}_${col_name}_${bac_id}_nonchimera_${seg}.fasta
    if ( `cat ${sample_data_merged_sanger_file} | wc -l` > 0 ) then
      echo "INFO: creating Sanger fasta of non_chimeric reads from reads matching segment [${seg}] for [${db_name}/${col_name}/${bac_id}]"
      fnafile \
        -i ${non_chimera_list} \
        -o ${sample_seg_sanger_file} \
        ${sample_data_merged_sanger_file}
    endif

    echo "INFO: creating 100x max coverage sff of non_chimeric reads from reads matching segment [${seg}] for [${db_name}/${col_name}/${bac_id}]"
    set bps = `echo ${seg_cov} | tr ' ' '\n' | grep ${seg} | cut -d ':' -f 2`
    set sample_seg_100x_sff_file = ${sample_data_merged_sff}/${db_name}_${col_name}_${bac_id}_nonchimera_${seg}_100x.sff
    foreach key (`ls -1 ${sample_data_merged_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
      sfffile \
        -pick ${bps} \
        -o ${sample_seg_100x_sff_file:r}.${key}.sff \
        ${sample_seg_sff_file:r}.${key}.sff
    end

    set seg_assembly_dir = ${sample_data}/assembly_by_segment/${seg}
    if ( -d ${seg_assembly_dir} ) then
    else
      mkdir -p ${seg_assembly_dir}
    endif

    pushd ${seg_assembly_dir} >& /dev/null
      echo "INFO: performing de novo assembly of 100x coverage for nonchimera reads from segment [${seg}] for [${db_name}/${col_name}/${bac_id}]"

      ln -s /usr/local/packages/clc-bfx-cell/license.properties ./

      set input_read_files = ""
      foreach key (`ls -1 ${sample_data_merged_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
        set input_read_files = `echo "${input_read_files} -q ${sample_seg_100x_sff_file:r}.${key}.sff"`
      end
      if ( -e ${sample_seg_sanger_file} ) then
        if ( `cat ${sample_seg_sanger_file} | wc -l` > 0 ) then
          set input_read_files = `echo "${input_read_files} -q ${sample_seg_sanger_file}"`
        endif
      endif
      clc_novo_assemble \
        -o ${seg}_100x_contigs.fasta \
        ${input_read_files} \
        >& ${seg}_100x_clc_novo_assemble.log

      set contig_cnt = `grep "^>" ${seg}_100x_contigs.fasta | wc -l`
      if ( ${contig_cnt} < 1 ) then
        echo "WARNING: clc de novo assembly of 100x coverage failed, trying cap3 for nonchimera reads from segment [${seg}] for [${db_name}/${col_name}/${bac_id}]"
        if ( -e ${db_name}_${col_name}_${bac_id}_nonchimera_${seg}_100x.fasta ) then
          rm ${db_name}_${col_name}_${bac_id}_nonchimera_${seg}_100x.fasta
        endif
        touch ${db_name}_${col_name}_${bac_id}_nonchimera_${seg}_100x.fasta
        foreach key (`ls -1 ${sample_data_merged_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
          sffinfo \
            -s ${sample_seg_100x_sff_file:r}.${key}.sff | \
            grep -v " length=0 " \
            >> ${db_name}_${col_name}_${bac_id}_nonchimera_${seg}_100x.fasta
        end
        if ( -e ${sample_seg_sanger_file} ) then
          cat ${sample_seg_sanger_file} >> ${db_name}_${col_name}_${bac_id}_nonchimera_${seg}_100x.fasta
        endif

        cap3 ${db_name}_${col_name}_${bac_id}_nonchimera_${seg}_100x.fasta
        mv ${db_name}_${col_name}_${bac_id}_nonchimera_${seg}_100x.fasta.cap.contigs ${seg}_100x_contigs.fasta
        rm ${db_name}_${col_name}_${bac_id}_nonchimera_${seg}_100x.fasta*
      endif
      
      set blast_db = ${blast_db_dir}/${seg}_full_length_NT_complete.fa
      set best_reference = ${seg_assembly_dir}/${seg}_best_reference.fna
      if ( -e ${seg}_100x_contigs.fasta ) then
        echo "INFO: finding best FL reference for segment [${seg}] for [${db_name}/${col_name}/${bac_id}]"
        set best_hit = \
          `blastall \
             -p blastn \
             -d ${blast_db} \
             -b 1 \
             -v 1 \
             -m 8 \
             -i ${seg}_100x_contigs.fasta | \
          gawk -F'\t' '{printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);}' | \
          sort -nrk12 | \
          head -n 1 | \
          gawk '{printf("%s\n", $2);}'`
        fastacmd -d ${blast_db} -p F -s "${best_hit}"  -o ${best_reference}
        grep "^>" ${best_reference} | cut -c 2- | gawk -v s=${seg} '{printf(">%s %s\n", s, $0);}' > ${best_reference}_mod
        grep -v "^>" ${best_reference} >> ${best_reference}_mod
        mv ${best_reference}_mod ${best_reference}
      else
        echo "ERROR: missing de novo assembly of 100x coverage for nonchimera reads from segment [${seg}] for [${db_name}/${col_name}/${bac_id}]"
      endif
    popd >& /dev/null
  end

  echo "INFO: consolidating best FL reference sequences for [${db_name}/${col_name}/${bac_id}]"
  set seg_best_ref_dir = ${sample_data}/reference_fasta
  if ( -d ${seg_best_ref_dir} ) then
  else
    mkdir -p ${seg_best_ref_dir}
  endif
  set best_refs_file = ${seg_best_ref_dir}/reference.fasta
  cat ${sample_data}/assembly_by_segment/*/*_best_reference.fna > ${best_refs_file}

  echo "INFO: consolidating nonchimera 454 reads for [${db_name}/${col_name}/${bac_id}]"
  set non_chimera_list = ${tblastx_outdir}/nonchimera_reads.uaccno_list
  cat ${tblastx_outdir}/*_nonchimera_reads.uaccno_list > ${non_chimera_list}

  set deconvolved_sff = ${sample_data_merged_sff}/${db_name}_${col_name}_${bac_id}_nonchimera.sff
  foreach key (`ls -1 ${sample_data_merged_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
    sfffile -i ${non_chimera_list} \
      -o ${deconvolved_sff:r}.${key}.sff \
      ${sample_data_merged_sff_file:r}.${key}.sff
  end

  echo "INFO: mapping viral sequences for [${db_name}/${col_name}/${bac_id}]"
  set sample_mapping_dir = ${sample_data}/mapping
  if ( -d ${sample_mapping_dir} ) then
  else
    mkdir -p ${sample_mapping_dir}
  endif

  pushd ${sample_mapping_dir} >& /dev/null
    ln -s /usr/local/packages/clc-bfx-cell/license.properties ./

    set sff_exists = 0
    set input_read_files = ""
    foreach key (`ls -1 ${sample_data_merged_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
      set input_read_files = `echo "${input_read_files} -q ${deconvolved_sff:r}.${key}.sff"`
      set sff_exists = 1
    end

    touch ${db_name}_${col_name}_${bac_id}_454_only_gb_refs_find_variations.log
    if ( ${sff_exists} > 0 ) then
      echo "INFO: using clc_ref_assemble_long to find sff SNPs for [${db_name}_${col_name}_${bac_id}]"
      clc_ref_assemble_long \
        -s 0.95 \
        -o ${db_name}_${col_name}_${bac_id}_454_only_gb_refs.cas \
        ${input_read_files} \
        -d ${best_refs_file}
      find_variations \
        -a ${db_name}_${col_name}_${bac_id}_454_only_gb_refs.cas \
        -c 2 \
        -o ${db_name}_${col_name}_${bac_id}_454_only_gb_refs.new_contigs \
        -v \
        -f 0.2 >& ${db_name}_${col_name}_${bac_id}_454_only_gb_refs_find_variations.log
    endif
    cat ${db_name}_${col_name}_${bac_id}_454_only_gb_refs_find_variations.log | \
      grep -v Nochange | \
      cut -d ':' -f 1 | \
      gawk '{if($0 ~ /^[A-Z]/){s=$1;n=0; } \
             else if ($0 ~ /Difference/){l=$1; c=$5; n=0; printf("%s:%d:%s\n", s, l, c);}}' > \
      ${db_name}_${col_name}_${bac_id}_454_only_gb_refs_find_variations.log.reduced

    touch ${db_name}_${col_name}_${bac_id}_solexa_only_gb_refs_find_variations.log.reduced
    if ( `cat ${sample_data_merged_solexa_file} | wc -l` > 0 ) then
      echo "INFO: using clc_ref_assemble_long to find fastq SNPs for [${db_name}_${col_name}_${bac_id}]"
      clc_ref_assemble_long \
        -s 0.95 \
        -o ${db_name}_${col_name}_${bac_id}_solexa_only_gb_refs.cas \
        -q ${sample_data_merged_solexa_file} \
        -d ${best_refs_file}
      find_variations \
        -a ${db_name}_${col_name}_${bac_id}_solexa_only_gb_refs.cas \
        -c 2 \
        -o ${db_name}_${col_name}_${bac_id}_solexa_only_gb_refs.new_contigs \
        -v \
        -f 0.2 >& ${db_name}_${col_name}_${bac_id}_solexa_only_gb_refs_find_variations.log
      cat ${db_name}_${col_name}_${bac_id}_solexa_only_gb_refs_find_variations.log | \
        grep -v Nochange | \
        cut -d ':' -f 1 | \
        gawk '{if($0 ~ /^[A-Z]/){s=$1;n=0; } \
               else if ($0 ~ /Difference/){l=$1; c=$5; n=0; printf("%s:%d:%s\n", s, l, c);}}' > \
        ${db_name}_${col_name}_${bac_id}_solexa_only_gb_refs_find_variations.log.reduced
    endif

    if ( ${sff_exists} > 0 ) then
      if ( `cat ${db_name}_${col_name}_${bac_id}_solexa_only_gb_refs_find_variations.log.reduced | wc -l` > 0 ) then
        sdiff \
          ${db_name}_${col_name}_${bac_id}_454_only_gb_refs_find_variations.log.reduced \
          ${db_name}_${col_name}_${bac_id}_solexa_only_gb_refs_find_variations.log.reduced | \
          grep -v "[<|>]" | \
          cut -f 1 > \
            ${db_name}_${col_name}_${bac_id}_454_solexa_common_gb_refs_find_variations.log.reduced
      else
        cp \
          ${db_name}_${col_name}_${bac_id}_454_only_gb_refs_find_variations.log.reduced \
          ${db_name}_${col_name}_${bac_id}_454_solexa_common_gb_refs_find_variations.log.reduced
      endif
    else
      cp \
        ${db_name}_${col_name}_${bac_id}_solexa_only_gb_refs_find_variations.log.reduced \
        ${db_name}_${col_name}_${bac_id}_454_solexa_common_gb_refs_find_variations.log.reduced
    endif
 
    echo "INFO: building edited references based on common sff and fastq SNPs for [${db_name}_${col_name}_${bac_id}]"
    foreach seg ( `grep "^>" ${best_refs_file} | cut -d ' ' -f 1 | cut -c 2-` )
      nthseq -sequence ${best_refs_file} \
        -number `grep "^>" ${best_refs_file} | cut -d ' ' -f 1 | cut -c 2- | grep -n ${seg} | cut -d ':' -f 1` \
        -outseq ${db_name}_${col_name}_${bac_id}_${seg}.extracted >& /dev/null
      cat ${db_name}_${col_name}_${bac_id}_454_solexa_common_gb_refs_find_variations.log.reduced | \
        grep ${seg} | \
        cut -d ':' -f 2-3 | \
        tr '\n ' ' ' > ${db_name}_${col_name}_${bac_id}_${seg}.edits
      /usr/local/devel/DAS/software/resequencing/prod/data_analysis/delta2seq.pl \
        -r ${db_name}_${col_name}_${bac_id}_${seg}.extracted \
        -f ${db_name}_${col_name}_${bac_id}_${seg}.edits \
        -q ${db_name}_${col_name}_${bac_id}_${seg}.extracted.edited
      grep "^>" ${db_name}_${col_name}_${bac_id}_${seg}.extracted > \
        ${db_name}_${col_name}_${bac_id}_${seg}.extracted.edited.fasta
      grep -v "^>" ${db_name}_${col_name}_${bac_id}_${seg}.extracted.edited >> \
        ${db_name}_${col_name}_${bac_id}_${seg}.extracted.edited.fasta
    end
    set best_edited_refs_file = ${db_name}_${col_name}_${bac_id}_reference_edited.fasta
    cat ${db_name}_${col_name}_${bac_id}_*.extracted.edited.fasta > \
      ${best_edited_refs_file}

    echo "INFO: using 454 mapper for final chimera check for [${db_name}_${col_name}_${bac_id}]"

    if ( -d 454_mapping_best_refs_chimera_check ) then
      rm -Rf 454_mapping_best_refs_chimera_check
    endif
    newMapping 454_mapping_best_refs_chimera_check
    setRef 454_mapping_best_refs_chimera_check ${best_edited_refs_file}

    foreach key (`ls -1 ${sample_data_merged_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
      addRun 454_mapping_best_refs_chimera_check ${deconvolved_sff:r}.${key}.sff
    end

    if ( `cat ${sample_data_merged_solexa_file} | wc -l` > 0 ) then
      addRun 454_mapping_best_refs_chimera_check ${sample_data_merged_solexa_file}
    endif
    runProject -no 454_mapping_best_refs_chimera_check >& runProject_454_mapping_best_refs_chimera_check.log
    grep "Chimeric" 454_mapping_best_refs_chimera_check/mapping/454ReadStatus.txt | \
      gawk '{print $1}' > exclude_list.txt

    cat ${sample_data_merged_solexa_file_t} | gawk -F'\t' '{if($2!=29){print $1;}}' >> exclude_list.txt

    set final_sff_reads = ${db_name}_${col_name}_${bac_id}_final.sff
    set final_fastq_reads = ${db_name}_${col_name}_${bac_id}_final.fastq
    set final_fasta_reads = ${db_name}_${col_name}_${bac_id}_final.fasta

    if ( `cat ${sample_data_merged_sanger_file} | wc -l` > 0 ) then
      cp ${sample_data_merged_sanger_file} ${final_fasta_reads}
      cp ${sample_data_merged_sanger_file}.untrimmed ${final_fasta_reads}.untrimmed
      cp ${sample_data_merged_sanger_file}.trimpoints ${final_fasta_reads}.trimpoints
    endif

    foreach key (`ls -1 ${sample_data_merged_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
      sfffile \
        -o ${final_sff_reads:r}.${key}.sff \
        -e exclude_list.txt \
        ${deconvolved_sff:r}.${key}.sff
    end

    touch ${final_fastq_reads}
    touch ${final_fastq_reads}.trimpoints
    touch ${final_fastq_reads}.untrimmed

    if ( `cat ${sample_data_merged_solexa_file} | wc -l` > 0 ) then
      /home/tstockwe/bin/fastqfile.pl \
        -o ${final_fastq_reads} \
        -e exclude_list.txt \
        -f ${sample_data_merged_solexa_file}

      cat ${final_fastq_reads} | \
        gawk '{t=NR % 4;\
               if(t==1){\
                 if(length(sid) > 0 ) {printf("%s\t%s\t%s\t%s\n", sid,s,qid,q)};\
                 sid=substr($0,2);\
               }\
               else if (t==2){s=$0;}\
               else if (t==3){qid=substr($0,2);}\
               else if (t==0){q=$0;}\
              }\
              END {\
                if(length(sid) > 0 ) {printf("%s\t%s\t%s\t%s\n", sid,s,qid,q)};\
                sid=substr($0,2);\
              }' | \
        sort | \
        gawk -F'\t' '{printf("@%s\n%s\n+%s\n%s\n", $1, $2, $3, $4);}' > ${final_fastq_reads}.sorted
      mv ${final_fastq_reads} ${final_fastq_reads}.unsorted
      mv ${final_fastq_reads}.sorted ${final_fastq_reads}

      grep "^@SOLEXA" ${final_fastq_reads} | cut -c 2- | sort > include_list.txt
      join -1 1 -2 1 \
        include_list.txt \
        ${sample_data_merged_solexa_file_t} | \
        tr ' ' '\t' > ${final_fastq_reads}.trimpoints

      /home/tstockwe/bin/fastqfile.pl \
        -o ${final_fastq_reads}.untrimmed \
        -i include_list.txt \
        -f ${sample_data_merged_solexa_file_u}

      cat ${final_fastq_reads}.untrimmed | \
        gawk '{t=NR % 4;\
               if(t==1){\
                 if(length(sid) > 0 ) {printf("%s\t%s\t%s\t%s\n", sid,s,qid,q)};\
                 sid=substr($0,2);\
               }\
               else if (t==2){s=$0;}\
               else if (t==3){qid=substr($0,2);}\
               else if (t==0){q=$0;}\
              }\
              END {\
                if(length(sid) > 0 ) {printf("%s\t%s\t%s\t%s\n", sid,s,qid,q)};\
                sid=substr($0,2);\
              }' | \
        sort | \
        gawk -F'\t' '{printf("@%s\n%s\n+%s\n%s\n", $1, $2, $3, $4);}' > ${final_fastq_reads}.untrimmed.sorted
      mv ${final_fastq_reads}.untrimmed.sorted ${final_fastq_reads}.untrimmed
    endif

    echo "INFO: running clc_ref_assemble_long for [${db_name}_${col_name}_${bac_id}]"

    set input_read_files = ""
    foreach key (`ls -1 ${sample_data_merged_sff} | grep "\.[ACGT][ACGT][ACGT][ACGT]\." | cut -d '.' -f 2 | sort -u`)
      set input_read_files = `echo "${input_read_files} -q ${final_sff_reads:r}.${key}.sff"`
    end

    if ( `cat ${final_fasta_reads} | wc -l` > 0 ) then
      set input_read_files = `echo "${input_read_files} -q ${final_fasta_reads}"`
    endif

    if ( `cat ${final_fastq_reads} | wc -l` > 0 ) then
      set input_read_files = `echo "${input_read_files} -q ${final_fastq_reads}"`
    endif

    clc_ref_assemble_long \
      -s 0.95 \
      -o ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.cas \
      ${input_read_files} \
      -d ${best_edited_refs_file}

    find_variations \
      -a ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.cas \
      -c 2 \
      -o ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.new_contigs \
      -v \
      -f 0.2 >& ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs_find_variations.log

    if ( ${flu_a} > 0 ) then
      echo "INFO: running fluValidator for [${db_name}_${col_name}_${bac_id}]"
      /usr/local/devel/VIRIFX/software/Elvira/bin/fluValidator2 \
        --fasta ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.new_contigs > \
        ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.new_contigs.fluValidator 
    endif
  popd >& /dev/null
end

################### REVIEW FLU VALIDATOR RESULTS FOR CLC DATA #############################

set sispa_pool_name = 20110707_104xMPA_2xMG_1xSW_6xNORV
set sispa_pool_name = 20110715_1_61xMPS
set sispa_pool_name = 20110715_2_55xMPS
set sispa_pool_name = 20110721_47xMPA_6xSB
set sispa_pool_name = 20110815_47xVEEV_6xARBO_3xJC_1xJEV_1xYFV
set sispa_pool_name = 20110816_65xMPV_7xRSV


set project_root = /usr/local/projects/VHTNGS
set barcode_data_root = ${project_root}/barcode_data
set sample_data_root = ${project_root}/sample_data_new

set barcode_data_dir = ${barcode_data_root}/${sispa_pool_name}
set barcode_file_name = ${barcode_data_dir}/barcode_metadata_from_GLK.txt
foreach bc_rec ( `cat ${barcode_file_name} | grep -v "POSCTRL" | tr ' ' '_' | tr '\t' ':' | cut -d ':' -f 3,6,7 | sort -u | grep -v "LASKEN" | grep -v "givtest" | grep -v "giv2" | grep -v "norv"` )
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 1`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 2`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 3`

set triplet_file = /home/tstockwe/for_vhtngs/20111114_bad_refs_tuples.txt
set triplet_file = /home/tstockwe/for_vhtngs/20111117_bad_refs_tuples.txt
set triplet_file = /home/tstockwe/for_vhtngs/20111121_samples_with_solexa_data_problems_tuples.txt
set triplet_file = /home/tstockwe/for_vhtngs/20111121_MPA_samples_with_solexa_data_problems_tuples.txt

foreach bc_rec ( `cat ${triplet_file} | tr ',' ':' | sort -u` )
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 3`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 1`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 2`

  echo "INFO: examining sample tuple [${db_name}/${col_name}/${bac_id}]"
  set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}
  set sample_mapping_dir = ${sample_data}/mapping
  echo "INFO: pushd to [${sample_mapping_dir}]"
  if ( -d ${sample_mapping_dir} ) then
  pushd ${sample_mapping_dir} >& /dev/null
    if ( -e ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.new_contigs.fluValidator ) then
      cat ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.new_contigs.fluValidator 
    else if ( -e ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.new_contigs ) then
      echo "INFO: running fluValidator for [${db_name}_${col_name}_${bac_id}]"
      /usr/local/devel/VIRIFX/software/Elvira/bin/fluValidator2 \
        --fasta ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.new_contigs > \
        ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.new_contigs.fluValidator 
      cat ${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.new_contigs.fluValidator 
    else 
      echo "ERROR: running fluValidator for [${db_name}_${col_name}_${bac_id}], [${db_name}_${col_name}_${bac_id}_hybrid_edited_refs.new_contigs] does not exist"
    endif
    sleep 1
  popd >& /dev/null
  else
    echo "WARNING: [${sample_mapping_dir}] not visible from this node"
  endif
end

################### GENERATE CAS2CONSED DATA #############################

set sispa_pool_name = 20110707_104xMPA_2xMG_1xSW_6xNORV
set sispa_pool_name = 20110715_1_61xMPS
set sispa_pool_name = 20110715_2_55xMPS
set sispa_pool_name = 20110721_47xMPA_6xSB
set sispa_pool_name = 20110815_47xVEEV_6xARBO_3xJC_1xJEV_1xYFV
set sispa_pool_name = 20110816_65xMPV_7xRSV
set sispa_pool_name = 20111208_104xH2SJ


set project_root = /usr/local/projects/VHTNGS
set barcode_data_root = ${project_root}/barcode_data
set sample_data_root = ${project_root}/sample_data_new

set barcode_data_dir = ${barcode_data_root}/${sispa_pool_name}
set barcode_file_name = ${barcode_data_dir}/barcode_metadata_from_GLK.txt

cat $barcode_file_name | \
  grep -v "POSCTRL" | \
  grep -v "giv2" | \
  tr ' ' '_' | \
  tr '\t' ':' | \
  cut -d ':' -f 3,6,7 | \
  sort -u | \
  gawk -F':' '{printf("%s,%s,%s\n",$2,$3,$1);}' > ~/for_vhtngs/${sispa_pool_name}_tuples.txt

set triplet_file = /home/tstockwe/for_vhtngs/${sispa_pool_name}_tuples.txt

set triplet_file = /home/tstockwe/for_vhtngs/20111114_bad_refs_tuples.txt
set triplet_file = /home/tstockwe/for_vhtngs/20111117_bad_refs_tuples.txt
set triplet_file = /home/tstockwe/for_vhtngs/20111121_nonMPA_samples_with_solexa_data_problems_tuples.txt

/usr/local/devel/VIRIFX/software/Elvira/bin/gridMultiViralCas2ConsedPipeline \
  -in ${triplet_file} -project_code 810001

/usr/local/devel/VIRIFX/software/bin/flu_validate2_cas2consed_ace2_assemblies.csh \
  ${triplet_file}


################### REVIEW FLU VALIDATOR RESULTS FOR CAS2CONSED DATA #############################
set sispa_pool_name = 20090205_HIsamples6to100
set sispa_pool_name = 20090205_34xDW_5xHI_2xUNKNOWN_samples
set sispa_pool_name = 20090901_20xDW09_3xCC_12xSW_samples
set sispa_pool_name = 20091005_AVIAN113
set sispa_pool_name = 20091215_MCEIRSsamples1to50
set sispa_pool_name = 20100305_1_86xAK_1xSW
set sispa_pool_name = 20100305_2_32xAK_24xCOH_1xMCWS_2xKHBAT_1xSW
set sispa_pool_name = 20100416_B_57xMCE_14xAK_5xCOH_4xVEEV_3xINS_1xCC_1xWKS
set sispa_pool_name = 20110202_68xWBC_11xCA_2xMCE_2xMPV_1xAGS_1xEB_1x_FBS_1xRFS
set sispa_pool_name = 20110707_104xMPA_2xMG_1xSW_6xNORV
set sispa_pool_name = 20110715_1_61xMPS
set sispa_pool_name = 20110715_2_55xMPS
set sispa_pool_name = 20110721_47xMPA_6xSB
set sispa_pool_name = 20110815_47xVEEV_6xARBO_3xJC_1xJEV_1xYFV
set sispa_pool_name = 20110816_65xMPV_7xRSV

set project_root = /usr/local/projects/VHTNGS
set barcode_data_root = ${project_root}/barcode_data
set sample_data_root = ${project_root}/sample_data_new
set barcode_data_dir = ${barcode_data_root}/${sispa_pool_name}
set barcode_file_name = ${barcode_data_dir}/barcode_metadata_from_GLK.txt

if ( -e ${sispa_pool_name}_status.csv ) then
  rm ${sispa_pool_name}_status.csv
endif
touch ${sispa_pool_name}_status.csv
if ( -e ${sispa_pool_name}_status.log ) then
  rm ${sispa_pool_name}_status.log 
endif
touch ${sispa_pool_name}_status.log 

foreach bc_rec ( `cat ${barcode_file_name} | tr ' ' '_' | tr '\t' ':' | cut -d ':' -f 3,6,7 | sort -u | grep -v "norv" | grep -v "giv2" `)
  set bac_id   = `echo "${bc_rec}" | cut -d ':' -f 1`
  set db_name  = `echo "${bc_rec}" | cut -d ':' -f 2`
  set col_name = `echo "${bc_rec}" | cut -d ':' -f 3`
  set sample_data = ${sample_data_root}/${db_name}/${col_name}/${bac_id}
  set sample_mapping_dir = ${sample_data}/mapping

  if ( -e ${sample_mapping_dir}/consed_with_sanger/${db_name}_${col_name}_${bac_id}.ace.2.consensus.fasta.fluValidator ) then
      echo "\n\nINFO: ${db_name}_${col_name}_${bac_id}.ace.2.consensus.fasta.fluValidator for sample [${db_name}_${col_name}_${bac_id}]"
      cat ${sample_mapping_dir}/consed_with_sanger/${db_name}_${col_name}_${bac_id}.ace.2.consensus.fasta.fluValidator
      echo "\n\nINFO: ${db_name}_${col_name}_${bac_id}.ace.2.consensus.fasta.fluValidator for sample [${db_name}_${col_name}_${bac_id}]" >> ${sispa_pool_name}_status.log
      cat ${sample_mapping_dir}/consed_with_sanger/${db_name}_${col_name}_${bac_id}.ace.2.consensus.fasta.fluValidator >> ${sispa_pool_name}_status.log
      set valid_cnt = `cat ${sample_mapping_dir}/consed_with_sanger/${db_name}_${col_name}_${bac_id}.ace.2.consensus.fasta.fluValidator | grep " VALID " | wc -l`
      set contig_cnt = `cat ${sample_mapping_dir}/consed_with_sanger/${db_name}_${col_name}_${bac_id}.ace.2.consensus.fasta.fluValidator | grep "Contig " | wc -l`
      if ( ${valid_cnt} == 8 && ${contig_cnt} == 8 ) then
        echo "VALID,${valid_cnt},${contig_cnt},${db_name},${col_name},${bac_id}"
        echo "VALID,${valid_cnt},${contig_cnt},${db_name},${col_name},${bac_id}" >> ${sispa_pool_name}_status.log
        echo "VALID,${valid_cnt},${contig_cnt},${db_name},${col_name},${bac_id}" >> ${sispa_pool_name}_status.csv
      else
        echo "DRAFT,${valid_cnt},${contig_cnt},${db_name},${col_name},${bac_id}"
        echo "DRAFT,${valid_cnt},${contig_cnt},${db_name},${col_name},${bac_id}" >> ${sispa_pool_name}_status.log
        echo "DRAFT,${valid_cnt},${contig_cnt},${db_name},${col_name},${bac_id}" >> ${sispa_pool_name}_status.csv
      endif
    else
      echo "WARNING: NO ${db_name}_${col_name}_${bac_id}.ace.2.consensus.fasta.fluValidator FILE FOUND FOR SAMPLE [${db_name}_${col_name}_${bac_id}]"
      echo "WARNING: NO ${db_name}_${col_name}_${bac_id}.ace.2.consensus.fasta.fluValidator FILE FOUND FOR SAMPLE [${db_name}_${col_name}_${bac_id}]" >> ${sispa_pool_name}_status.log
    endif
end



