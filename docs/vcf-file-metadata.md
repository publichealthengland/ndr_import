---
layout: page
title: VCF File Metdata
permalink: /vcf-file-metadata/
---

### Introduction
VCF files contain a header storing metadata, `NdrImport::Vcf::Table` now supports retrieval and storage of that data.

### `vcf_file_metadata`
* `NdrImport::Vcf::Table` can optionally store `vcf_file_metadata`. This is a hash of { attribute name => regular expression }.
* The `NdrImport::File::Vcf` handler uses `vcf_file_metadata` to locate the metadata from within the file, then sets the `file_metadata` attribute as a hash of { attribute name => regular expression first captured group }.
* The `UniversalImporterHelper` then assigns the handler.file_metadata to the `NdrImport::Table` attribute `table_metadata`, which can then be accessed downstream.


###  Example:
Given the below example data:

```
 ##contig=<ID=GL000194.1,length=191469>
 ##contig=<ID=GL000225.1,length=211173>
 ##contig=<ID=GL000192.1,length=547496>
 ##contig=<ID=NC_007605,length=171823>
 ##contig=<ID=hs37d5,length=35477943>
 ##fileDate=2023-03-29
 ##reference=file:///data/humanGenome/hs37d5.fa
 ##source=Platypus_Version_0.8.1
 #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	Sample1
1	26387783	.	G	A	847.77	PASS	AC=1;AF=0.500;AN=2;DP=85;set=Intersection	GT:AD:DP:GQ:PL:SAC	0/1:52,32:84:99:876,0,1277:21,31,14,18
```

The `NdrImport::Vcf::Table` mapping might look like:

```
- !ruby/object:NdrImport::Vcf::Table
  filename_pattern: !ruby/regexp //
  vcf_file_metadata:
    genome_build: /##reference=file:///data/humanGenome\/(.+)\z/
  columns:
  ...
```

This would result in a `table_metadata` value of:
```
{ genome_build: 'hs37d5.fa' }
```
