FastQ Screen is a quality control tool that allows you to determine the origin of reads in your FASTQ files by screening against multiple reference genomes. 
It identifies potential contamination or confirms sample identity by mapping subsets of reads to different genomes using aligners like bowtie2 or bwa.

This setup provides references for common lab organisms, contaminants (e.g., PhiX, Lambda, vectors), and rRNA/mitochondrial sequences. 
Each reference is indexed with bowtie2 to support efficient classification.
