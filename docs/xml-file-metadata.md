---
layout: page
title: XML File Metdata
permalink: /xml-file-metadata/
---

### Introduction
XML can contain file level data, `NdrImport::Xml::Table` now supports retrieval and storage of that data.

### `xml_file_metadata`
* `NdrImport::Xml::Table` can optionally store `xml_file_metadata`. This is a hash of { attribute name => xpath }.
* The `NdrImport::File::Xml` handler uses `xml_file_metadata` to locate the metadata from within the file, then sets the `file_metadata` attribute as a hash of { attribute name => value at given xpath }.
* The `UniversalImporterHelper` then assigns the handler.file_metadata to the `NdrImport::Table` attribute `table_metadata`, which can then be accessed downstream.


###  Example:
Given the below example data:

```xml
<root>
  <metatadata_one extension="hello"/>
  <metatadata_two value="world"/>
  <record>
    <some_data>DOUGLAS</some_data>
  </record>
  <record>
    <some_data>DORA</some_data>
  </record>
<root>
```

The `NdrImport::Xml::Table` mapping might look like:

```yaml
- !ruby/object:NdrImport::Xml::Table
  filename_pattern: !ruby/regexp //
  format: xml_table
  xml_record_xpath: 'record'
  yield_xml_record: false
  xml_file_metadata:
    metatadata_one: '//root/metatadata_one/@extension'
    metatadata_two: '//root/metatadata_two/@value'
  columns:
  ...
```

This would result in a `table_metadata` value of:
```
{ metatadata_one: 'hello', metatadata_two: 'world' }
```
