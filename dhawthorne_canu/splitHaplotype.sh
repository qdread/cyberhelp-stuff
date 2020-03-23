#!/bin/sh


#  Path to Canu.

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

bin="/nfs/dhawthorne-data/canu/bin/$syst-$arch/bin"

if [ ! -d "$bin" ] ; then
  bin="/nfs/dhawthorne-data/canu/bin"
fi

#  Report paths.

echo ""
echo "Found perl:"
echo "  " `which perl`
echo "  " `perl --version | grep version`
echo ""
echo "Found java:"
echo "  " `which java`
echo "  " `java -showversion 2>&1 | head -n 1`
echo ""
echo "Found canu:"
echo "  " $bin/canu
echo "  " `$bin/canu -version`
echo ""


#  Environment for any object storage.

export CANU_OBJECT_STORE_CLIENT=
export CANU_OBJECT_STORE_CLIENT_UA=
export CANU_OBJECT_STORE_CLIENT_DA=
export CANU_OBJECT_STORE_NAMESPACE=cpb
export CANU_OBJECT_STORE_PROJECT=




#  Discover the job ID to run, from either a grid environment variable and a
#  command line offset, or directly from the command line.
#
if [ x$SLURM_ARRAY_TASK_ID = x -o x$SLURM_ARRAY_TASK_ID = xundefined -o x$SLURM_ARRAY_TASK_ID = x0 ]; then
  baseid=$1
  offset=0
else
  baseid=$SLURM_ARRAY_TASK_ID
  offset=$1
fi
if [ x$offset = x ]; then
  offset=0
fi
if [ x$baseid = x ]; then
  echo Error: I need SLURM_ARRAY_TASK_ID set, or a job index on the command line.
  exit
fi
jobid=`expr -- $baseid + $offset`
if [ x$SLURM_ARRAY_TASK_ID = x ]; then
  echo Running job $jobid based on command line options.
else
  echo Running job $jobid based on SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID and offset=$offset.
fi

if [ $jobid -gt 1 ]; then
  echo Error: Only 1 job, you asked for $jobid.
  exit 1
fi

#  If the unknown haplotype assignment exists, we're done.

if [ -e ./haplotype.log ] ; then
  echo Read to haplotype assignment already exists.
  exit 0
fi

#  Assign reads to haplotypes.

/nfs/dhawthorne-data/canu/bin/splitHaplotype \
  -cl 1000 \
  -threads 8 \
  -memory  12 \
  -R /nfs/dhawthorne-data/CPB_Trio_Binning_Data/Extracted_OR5_pacbio_files/XDHUM.201981024.PACBIO_DATA/Pellet_Pestle_A/PACBIO_DATA/XDHUM_20180914_S54024R1_PL100106367-1_B01/XDHUM_20180914_S54024R1_PL100106367-1_B01.subreads.fastq \
  -R /nfs/dhawthorne-data/CPB_Trio_Binning_Data/Extracted_OR5_pacbio_files/XDHUM.201981024.PACBIO_DATA/Pellet_Pestle_A/PACBIO_DATA/XDHUM_20180914_S54024R1_PL100106367-1_C01/XDHUM_20180914_S54024R1_PL100106367-1_C01.subreads.fastq \
  -R /nfs/dhawthorne-data/CPB_Trio_Binning_Data/Extracted_OR5_pacbio_files/XDHUM.201981024.PACBIO_DATA/Pellet_Pestle_A/PACBIO_DATA/XDHUM_20180917_S54024R1_PL100106367-1_A01/XDHUM_20180917_S54024R1_PL100106367-1_A01.subreads.fastq \
  -R /nfs/dhawthorne-data/CPB_Trio_Binning_Data/Extracted_OR5_pacbio_files/XDHUM.201981024.PACBIO_DATA/Pellet_Pestle_A/PACBIO_DATA/XDHUM_20180917_S54024R1_PL100106367-1_B01/XDHUM_20180917_S54024R1_PL100106367-1_B01.subreads.fastq \
  -R /nfs/dhawthorne-data/CPB_Trio_Binning_Data/Extracted_OR5_pacbio_files/XDHUM.201981024.PACBIO_DATA/Pellet_Pestle_A/PACBIO_DATA/XDHUM_20180917_S54024R1_PL100106367-1_C01/XDHUM_20180917_S54024R1_PL100106367-1_C01.subreads.fastq \
  -R /nfs/dhawthorne-data/CPB_Trio_Binning_Data/Extracted_OR5_pacbio_files/XDHUM.201981024.PACBIO_DATA/Pellet_Pestle_A/PACBIO_DATA/XDHUM_20180917_S54024R1_PL100106367-1_D01/XDHUM_20180917_S54024R1_PL100106367-1_D01.subreads.fastq \
  -H ./0-kmers/haplotype-F.meryl ./0-kmers/reads-F.statistics ./haplotype-F.fasta.gz \
  -H ./0-kmers/haplotype-M.meryl ./0-kmers/reads-M.statistics ./haplotype-M.fasta.gz \
  -A ./haplotype-unknown.fasta.gz \
> haplotype.log.WORKING \
&& \
mv -f ./haplotype.log.WORKING ./haplotype.log \

exit 0
