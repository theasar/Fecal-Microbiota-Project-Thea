# Thea's Final GEN711 Project: Fecal-Microbiota-Project   

## Authors: Thea Sarajlic

### Background:
As a student interested in microbiology, I had decided that the Fecal Microbiota Project seemed the most interesting to me to work on for my final culminating project for lab. 

For our project, we are using data collected from a long-term evolution project that is being carried out by Richard Lenski- where more than 40,000 generations of E. coli have been grown in glucose-limited minimal medium to see what adaptations would occur. Lenski's project explores the genetic bases of adaptation occurring in E. coli that are passaged from a common ancestor- and what gains of fitness occur over the course of serial passaging over many, many generations. Over the course of this experiment, multiple types of mutations have been seen in evolved populations compared to ancestral strains, including: point mutations, deletions, inversions, and insertions (Crozat et al., 2005). Having such a well documented evolutionary experiment provides an excellent opportunity to understand what is happening through a genomics perspective- and sequencing and aligning to a reference genome is one way to explore what changes across populations at different points of times. This can help to further understand what mutations or changes in DNA sequence result in greater fitness and the ability to outperform more ancestral strains that still may be present in culture. 

For this project- instead of following the protocol provided by Dr. Miller for his projects (diatoms, etc) I will be following the workflow provided in the "wrangling-genomics" Github which is split into 5 modules 
1. Background
2. Quality Control
3. Trimming
4. Variant Calling
5. Automation

For this project, data we worked with originating from 3 different samples at different generation periods (5,000, 15,0000 and 50,000). The main goal for this project and workflow is identifying how these populations changed through processing the data and through the variant calling workflow that will help to distinguish differences between these three samples at different generations. The general workflow for this project involved obtaining sequence reads, doing quality control steps, aligning to a genome, cleaning up the alignment, and variant calling as our final step. 

## Methods 
### Part One: Downloads and FASTQs
To get out data for this project, we downloaded from the European Nucleotide Archive. Since the data is paired-end reads we downloaded two files for each sample for a total of 6 files (2 for each sample).

#### Fastq files (downloaded from ENA directly to fastq)
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/004/SRR2589044/SRR2589044_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/004/SRR2589044/SRR2589044_2.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_2.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/006/SRR2584866/SRR2584866_1.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/006/SRR2584866/SRR2584866_2.fastq.gz 

This was slightly different than the commands used in the wrangling-genomics module, which used the command curl instead. Both have a similar function for downloading files from online.

The files that we are working with are FASTQs- a common format for sequenced reads that will allow us to begin our workflow. Since these files are large, they came in a compressed format (gzip) so our workflow involved unzipping these files to access and view some of their contents as needed.

These files are useful and contain quality scores that tell us the confidence of each nucleotide.

By running a program called FastQC on our FASTQ files- we can assess quality based on a number of different diagnostics. The FastQC program is part of our conda genomics environment- which allows us to run this program. This gets run through the RON computing cluster at UNH.

#### Running FASTQC
fastqc *.fastq*

### Part Two: Trimming
In this part of the module, we follow instructions on how to use trimmomatic to find poor quality reads and remove them from our samples.

To be able to do this, I had to find where the Nextera adapters were located in our environment.

ls $CONDA_PREFIX/share/trimmomatic*/adapters
cp /home/share/anaconda/envs/genomics/share/trimmomatic-0.39-2/adapters/NexteraPE-PE.fa .

To be able to run the command in the same way that the module was telling me, I had to locate the files and copy it into my current directory (this provides a bit of a shortcut for our trimmomatic command). 

To be able to run the trimmmomatic program on all of our files- we used a for loop.

for infile in *_1.fastq
do
base =$(basename ${infile} _1.fastq) \
trimmomatic PE ${infile} ${base}_2/fastq \
${base}_1.trim.fastq ${base}_1un.trim.fastq \
${base}_2.trim.fastq ${base}_2un.trim.fastq \
SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:NexteraPE-PE.fa:2:40:15
done

This was the line of code I used- I had to switch things up slightly from the instructions due to my files having slightly different names than the wrangling-genomics module. 

### Part Three: Variant Calling
This is an important part fo the work flow and it will show us how generations are different from each other now that the quality of our reads is better. This will involve aligning our samples to a reference genome for E. coli REL606.

To accomplish this, I had to download the reference genome from ncbi/nih and gunzip the file. I then indexed the reference genome for BWA which helps the aligner find potential sites for alignment more easily. The alignment algorithm we will be using for this project is BWA-MEM. What we got from this SAM files, which we can change into a compressed binary version called a BAM file. 

To convert files, the samtools program was used.

The next steps I had to do a little digging to figure out because the process is a little different I believe from versions of conda. The wrangling-genomics module requires use of a program called bcftools- which I kept getting errors for saying it was not able to access this or it was not in the library. To bypass this, I was able to search for the specific version of bcftools that our conda environment is able to run and I activated bcftools-1.21 specifically, which then allowed me to run the commands I needed to run for the variant calling portion of this module.

For the bcftools portion of this module, we looked into read coverages, identifying SNVs- and filtering these SNVs to get our final file format, a VCF.

### Part Four: Automation
The automation portion of the modules involved writing scripts in order to automate the process of variant calling on all of our data so we do not have to type out every single line over and over again for each file.

First we wrote a shell script that reruns the FastQC program - and we will replace our original files when the script is done running.

set -e
cd ~/Fecal-Microbiota-Project-Thea/fastqs
echo "Running FastQC ..."
fastqc *.fastq*
mkdir -p ~/Fecal-Microbiota-Project-Thea/results/fastqc_untrimmed_reads
echo "Saving FastQC results..."
mv *.zip ~/Fecal-Microbiota-Project-Thea/results/fastqc_untrimmed_reads/
mv *.html ~/Fecal-Microbiota-Project-Thea/results/fastqc_untrimmed_reads/
cd ~/Fecal-Microbiota-Project-Thea/results/fastqc_untrimmed_reads/
echo "Unzipping..."
for filename in *.zip
do 
unzip $filename
done
echo "Saving summary..."
mkdir -p ~/Fecal-Microbiota-Project-Thea/docs
cat */summary.txt > ~/Fecal-Microbiota-Project-Thea/results/fastqc_summaries.txt

The second script we write is for automating the variant calling process. Since some of my directories are named a little differently than the module had their's organized, I had to switch up this script a little bit in order to get it working.

I had to troubleshoot a few instances in both scripts where I made errors either through a typo or not putting down the right path- but was able to get the scripts working after figuring out where my errors were.

set -e
cd ~/Fecal-Microbiota-Project-Thea/results

genome=~/Fecal-Microbiota-Project-Thea/data/ref_genome/ecoli_rel606.fasta

bwa index $genome

mkdir -p sam bam bcf vcf

for fq1 in ~/Fecal-Microbiota-Project-Thea/data/trimmed_fastq_small/*_1.trim.sub.fastq
do
echo "working with file $fq1"

base=$(basename $fq1 _1.trim.sub.fastq)
echo "base name is $base"

fq1=~/Fecal-Microbiota-Project-Thea/data/trimmed_fastq_small/${base}_1.trim.sub.fastq
fq1=~/Fecal-Microbiota-Project-Thea/data/trimmed_fastq_small/${base}_2.trim.sub.fastq
sam=~/Fecal-Microbiota-Project-Thea/results/sam/${base}.aligned.sam
bam=~/Fecal-Microbiota-Project-Thea/results/bam/${base}.aligned.bam
sorted_bam=~/Fecal-Microbiota-Project-Thea/results/bam/${base}.aligned.sort.bam
raw_bcf=~/Fecal-Microbiota-Project-Thea/results/bcf/${base}_raw.bcf
variants=~/Fecal-Microbiota-Project-Thea/results/vcf/${base}_variants.vcf
final_variants=~/Fecal-Microbiota-Project-Thea/results/vcf/${base}_final_variants.vcf

bwa mem $genome $fq1 $fq2 > $sam
samtools view -S -b $sam > $bam
samtools sort -o $sorted_bam $bam
samtools index $sorted_bam
bcftools mpileup -O b -o $raw_bcf -f $genome $sorted_bam
bcftools call --ploidy 1 -m -v -o $variants $raw_bcf
vcfutils.pl varFilter $variants > $final_variants

done

This was the last step for our workflow in the Fecal Microbiota Project provided.

(Herr et al., 2017)

## Findings

Before reporting findings, I'd like to note that the information from files SRR2589044 was from generation 5,000, SRR2584863 was from generation 15,000, and SRR2584866 was from generation 50,0000.

First I will include all the results from the original FastQC.

![alt text](<figs/SRR2589044_1 quality.png>)
Figure 1:
![alt text](<figs/SRR2589044_2 quality.png>)
Figure 2:

Figure 1,2: Results for the quality scoring for paired end reads of generation 5,000.

![alt text](<figs/SRR2584863_1 quality.png>)
Figure 3:
![alt text](<figs/SRR2584863_2.fastq quality.png>)
Figure 4:

Figures 3,4: Results for the quality scoring for paired end reads of generation 15,000.

![alt text](<figs/SRR2584866_1 quality.png>)
Figure 5:
![alt text](<figs/SRR2584866_2 quality.png>)
Figure 6:

Figures 5,6: Results for the quality scoring for paired end reads of generation 50,000.

Now I will include images from after the trimming process was completed (not including untrimmed pairs).

![alt text](figs/SRR2589044.1trim.quality.png)
Figure 7:
![alt text](figs/SRR2589044_2.trim.quality.png)
Figure 8: 

Figure 7,8: Results for quality scoring after trimming of generation 5,000

![alt text](figs/SRR2584863_1.trim.quality.png)
Figure 9:
![alt text](figs/SRR2584863_2.trim.quality.png)

Figure 9,10: Results for quality scoring after trimming of generation 15,000

![alt text](figs/SRR2584866_1.trim.quality.png)
Figure 10:
![alt text](figs/SRR2584866_2.trim.quality.png)
Figure 11:

Figure 10,11: Results for quality scoring after trimming of generation 50,000

Overall, it is very obvious to see how the quality scoring improves, especially towards the end of the sequence. This is important for this workflow as removing bad quality reads will reduce error in identifying variation between generations in our variant calling steps.

One of the most important results that was determined through this process was the amount of variation between generations 
### Conclusions

Overall, through this project I got to understand the workflow of aligning genomes and looking for variations/mutations a lot better. These are topics we have covered extensively in class, including file formats and what they are used for- but being able to input the code myself and see the results and learn how to interpret them was very useful to me. It felt like getting a whole circle feel for both lecture and lab concepts and I got to apply it to a project that interested me!

If I had the opportunity to further this project and the data that was processed over the course of it- I would maybe look to explore specific variations between generations and see if there are important genes associated with these changes in sequence that were picked out by our variant calling. 

The furthest generation out had the most variations from the reference genome- which can be seen clearly in the VCF files.

### References
Crozat, E., Philippe, N., Lenski, R. E., Geiselmann, J., & Schneider, D. (2005). Long-term experimental evolution in Escherichia coli. XII. DNA topology as a key target of selection. Genetics, 169(2), 523–532. https://doi.org/10.1534/genetics.104.035717.

Josh Herr, Ming Tang, Lex Nederbragt, Fotis Psomopoulos (eds): "Data Carpentry: Wrangling Genomics Lesson."
Version 2017.11.0, November 2017,
http://www.datacarpentry.org/wrangling-genomics/,
doi: 10.5281/zenodo.1064254
