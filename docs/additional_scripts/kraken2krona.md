# QC with Kraken2
## Kraken2

## Krona
Krona provides a dynamic viewing of results from Kraken2

| Magnitued | NCBI TaxonomicID | Taxonomic Name |
|-----------|------------------|----------------|
| 670       | 1758             | M. musculus    |
| 40        | 9606             | H. sapiens     |
| 280       | 0                | Unclassified   |
| 10        | 2                | {Bacteria}     |

### Install
To install [Krona](https://telatin.github.io/microbiome-bioinformatics/Kraken-to-Krona/), you can type:
```
conda dinstall -c bioconda krona
```
Then you'll need to install the local taxonomic database
```ktUpdateTaxonomy.sh```

### Running Krona
You can genrate a plot of your data now with the command:
```
ktImportTaxonomy -m 1 -o Contam-check.html Kraken2_input.tsv
```
It should genrate a dynamic html like this:
[Example Krona](../_images/example_krona.png)
[<button>Example Krona</button>](example_krona.html){:target="_blank"}


