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