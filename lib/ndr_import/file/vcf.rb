require 'bio-vcf/vcfline'
require 'ndr_support/safe_file'
require_relative 'registry'

module NdrImport
  # This is one of a collection of file handlers that deal with individual formats of data.
  # They can be instantiated directly or via the factory method Registry.tables
  module File
    # This class is a vcf file handler that returns a single table.
    class Vcf < Base
      attr_accessor :vcf_file_metadata

      def initialize(*)
        super

        @vcf_file_metadata = @options['vcf_file_metadata']
        assign_file_metadata
      end

      private

      def assign_file_metadata
        return unless vcf_file_metadata.is_a?(Hash)

        file_metadata_hash = {}

        ::File.read(@filename).each_line do |line|
          next unless line.match?(/^##/)

          vcf_file_metadata.each do |attribute, pattern|
            file_metadata_hash[attribute] = line.match(pattern)[1].presence if line.match? pattern
          end
        end

        self.file_metadata = file_metadata_hash
      end

      def rows(&block)
        return enum_for(:rows) unless block

        ::File.read(@filename).each_line do |line|
          next if line.match?(/^##/)

          yield BioVcf::VcfLine.parse(line)
        end
      end
    end
    Registry.register(Vcf, 'vcf')
  end
end
