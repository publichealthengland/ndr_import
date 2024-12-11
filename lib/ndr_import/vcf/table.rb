require 'ndr_import/table'

module NdrImport
  module Vcf
    # Syntatic sugar to ensure `header_lines` and `footer_lines` are 1 and 0 respectively.
    # All other Table logic is inherited from `NdrImport::Table`
    class Table < ::NdrImport::Table
      def self.all_valid_options
        super - %w[delimiter header_lines footer_lines] + %w[vcf_file_metadata]
      end

      def header_lines
        1
      end

      def footer_lines
        0
      end
    end
  end
end
