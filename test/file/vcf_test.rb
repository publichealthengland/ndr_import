require 'test_helper'
require 'ndr_import/file/vcf'

module NdrImport
  module File
    # Vcf file handler tests
    class VcfTest < ActiveSupport::TestCase
      def setup
        @file_path = SafePath.new('permanent_test_files').join('sample_vcf.vcf')
      end

      test 'should read vcf files' do
        handler = NdrImport::File::Vcf.new(@file_path, nil)
        rows    = handler.send(:rows)

        assert rows.is_a? Enumerator
        assert(rows.all? { |row| row.is_a? Array })
        assert_equal 7, rows.to_a.length
      end

      test 'should read vcf file metadata' do
        vcf_file_mapping_metadata = {
          'genome_build' => %r{##reference=file.*?/humanGenome/(.+)},
          'platypus_version' => /##source=Platypus_Version_([\d.]+)/
        }
        options = { 'vcf_file_metadata' => vcf_file_mapping_metadata }
        handler = NdrImport::File::Vcf.new(@file_path, nil, options)

        assert_equal vcf_file_mapping_metadata, handler.vcf_file_metadata

        expected_metadata = { 'genome_build' => 'hs37d5.fa', 'platypus_version' => '0.8.1' }
        assert_equal expected_metadata, handler.file_metadata
        tables = handler.send(:tables).to_a
        assert_equal expected_metadata, tables.first.last
      end
    end
  end
end
