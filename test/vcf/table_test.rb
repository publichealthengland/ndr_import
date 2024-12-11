require 'test_helper'

# This tests the NdrImport::Vcf::Table mapping class
module Vcf
  class TableTest < ActiveSupport::TestCase
    def setup
      file_path = SafePath.new('permanent_test_files').join('sample_vcf.vcf')
      handler   = NdrImport::File::Vcf.new(file_path, nil)

      @rows = handler.send(:rows)
    end

    test 'test_all_valid_options' do
      valid_options = %w[canonical_name columns file_password filename_pattern format klass
                         last_data_column liberal_parsing row_identifier
                         significant_mapped_fields slurp tablename_pattern vcf_file_metadata]
      assert_equal valid_options.sort, NdrImport::Vcf::Table.all_valid_options.sort
    end

    test 'should transform avro lines' do
      table = NdrImport::Vcf::Table.new(klass: 'SomeTestKlass', columns: vcf_column_mapping)

      expected_data = ['SomeTestKlass',
                       { 'zipped_field' =>
                         [%w[GT 0/1],
                          %w[AD 52,32],
                          %w[DP 84],
                          %w[GQ 99],
                          %w[PL 876,0,1277],
                          %w[SAC 21,31,14,18]],
                         'lab_number' => 'Sample1',
                         rawtext:
                         { '#chrom'     => '1',
                           'pos'        => '26387783',
                           'id'         => '.',
                           'ref'        => 'G',
                           'alt'        => 'A',
                           'qual'       => '847.77',
                           'filter'     => 'PASS',
                           'info'       => 'AC=1;AF=0.500;AN=2;DP=85;set=Intersection',
                           'format'     => 'GT:AD:DP:GQ:PL:SAC',
                           'sample1'    => '0/1:52,32:84:99:876,0,1277:21,31,14,18',
                           'lab_number' => 'Sample1' } },
                       1]

      transformed_data = table.transform(@rows)
      assert_equal 6, transformed_data.count

      assert_equal expected_data, transformed_data.first
    end

    test 'should fail with too many columns of data' do
      table = NdrImport::Vcf::Table.new(klass: 'SomeTestKlass', columns: unexpected_columns_mapping)

      exception = assert_raises(RuntimeError) { table.transform(@rows).to_a }
      assert_equal 'Header is not valid! unexpected: ["format", "sample1"]', exception.message
    end

    test 'should fail with missing columns of data' do
      table = NdrImport::Vcf::Table.new(klass: 'SomeTestKlass', columns: missing_columns_mapping)

      exception = assert_raises(RuntimeError) { table.transform(@rows).to_a }
      expected_error = 'Header is not valid! missing: ["missing_column_one", "missing_column_two"]'
      assert_equal expected_error, exception.message
    end

    private

    def vcf_column_mapping
      [{ 'column' => '#chrom' },
       { 'column' => 'pos' },
       { 'column' => 'id' },
       { 'column' => 'ref' },
       { 'column' => 'alt' },
       { 'column' => 'qual' },
       { 'column' => 'filter' },
       { 'column' => 'info' },
       { 'column' => 'format', 'mappings' => ['field' => 'zipped_field', 'zip_order' => 1, 'split_char' => /[:;]/] },
       { 'column' => /sample\d+/i, 'map_columname_to' => 'lab_number', 'mappings' => ['field' => 'zipped_field', 'zip_order' => 2] }]
    end

    def unexpected_columns_mapping
      [{ 'column' => '#chrom' },
       { 'column' => 'pos' },
       { 'column' => 'id' },
       { 'column' => 'ref' },
       { 'column' => 'alt' },
       { 'column' => 'qual' },
       { 'column' => 'filter' },
       { 'column' => 'info' }]
    end

    def missing_columns_mapping
      [{ 'column' => '#chrom' },
       { 'column' => 'pos' },
       { 'column' => 'id' },
       { 'column' => 'ref' },
       { 'column' => 'alt' },
       { 'column' => 'qual' },
       { 'column' => 'filter' },
       { 'column' => 'info' },
       { 'column' => 'format' },
       { 'column' => 'sample1' },
       { 'column' => 'missing_column_one' },
       { 'column' => 'missing_column_two' }]
    end
  end
end
