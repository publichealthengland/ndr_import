require 'shellwords'

require 'ndr_import/file/registry'

module NdrImport
  # This mixin provides file importer helper methods that abstract away some of the
  # complexity of enumerating over files and tables (which should be universally useful).
  # It is assumed that the host module/class defines `unzip_path`.
  module UniversalImporterHelper
    # Helper class to allow multiple source enumerators to contribute to one overall table.
    class TableEnumProxy
      include Enumerable

      def initialize
        @table_enums = []
      end

      def add_table_enum(table_enum)
        @table_enums << table_enum
      end

      def each(&block)
        return enum_for(:each) unless block

        @table_enums.each { |table_enum| table_enum.each(&block) }
      end
    end

    def table_enumerators(filename)
      table_enumerators = Hash.new { |hash, key| hash[key] = TableEnumProxy.new }

      extract(filename).each do |table, rows|
        table_enumerators[table.canonical_name].add_table_enum table.transform(rows)
      end

      table_enumerators
    end

    # This method returns the correct NdrImport::{,NonTabular::}Table for the given
    # filename/tablename. It requires all the mappings to be stored in the table_mappings
    # instance variable.
    def get_table_mapping(filename, tablename)
      @table_mappings.find { |mapping| mapping.match(filename, tablename) }
    end

    # Iterate through the file(s) line by line, yielding each one in turn, using
    # get_table_mapping to select the mapping relevant to this file.
    def extract(source_file, &block)
      return enum_for(:extract, source_file) unless block

      NdrImport::File::Registry.files(source_file, 'unzip_path' => unzip_path).each do |filename|
        # now at the individual file level, can we find the table mapping?
        table_mapping = get_table_mapping(filename, nil)
        options       = table_options_from(table_mapping).merge { 'unzip_path' => unzip_path }

        tables = NdrImport::File::Registry.tables(filename, table_mapping.try(:format), options)
        yield_tables_and_their_content(filename, tables, &block)
      end
    end

    def table_options_from(table_mapping)
      { 'col_sep'                    => table_mapping.try(:delimiter),
        'file_password'              => table_mapping.try(:file_password),
        'liberal_parsing'            => table_mapping.try(:liberal_parsing),
        'xml_record_xpath'           => table_mapping.try(:xml_record_xpath),
        'slurp'                      => table_mapping.try(:slurp),
        'yield_xml_record'           => table_mapping.try(:yield_xml_record),
        'pattern_match_record_xpath' => table_mapping.try(:pattern_match_record_xpath),
        'xml_file_metadata'          => table_mapping.try(:xml_file_metadata),
        'vcf_file_metadata'          => table_mapping.try(:vcf_file_metadata) }
    end

    # This method does the table row yielding for the extract method, setting the notifier
    # so that we can monitor progress
    def yield_tables_and_their_content(filename, tables, &block)
      return enum_for(:yield_tables_and_their_content, filename, tables) unless block_given?

      tables.each do |tablename, table_content, file_metadata|
        mapping = get_table_mapping(filename, tablename)
        next if mapping.nil?

        mapping.notifier = get_notifier(record_total(filename, table_content))
        mapping.table_metadata = file_metadata || {}
        yield(mapping, table_content)
      end
    end

    def mapped_tables(filename)
      @mapped_tables ||= table_enumerators(filename)
    end

    # This method needs to be implemented where this mixin is used.
    def get_notifier(_total_records)
      raise NotImplementedError, 'get_notifier must be defined!'
    end

    def record_total(filename, table_content)
      if '.csv' == ::File.extname(filename).downcase
        return `wc -l #{Shellwords.escape(filename)}`.strip.match(/\A(\d+)/)[1].to_i
      elsif table_content.is_a?(Enumerator)
        nil # Avoid slurping
      else
        table_content.size
      end
    end
  end
end
