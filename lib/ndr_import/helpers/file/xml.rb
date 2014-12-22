require 'ndr_support/safe_file'

module NdrImport
  module Helpers
    module File
      # This mixin adds XML functionality to unified importers.
      module Xml
        private

        def read_xml_file(path)
          require 'nokogiri'
          file_data = SafeFile.new(path).read
          bad_ctrl_codes = (0..31).to_a - [9, 10, 13] # not allowed in XML data
          bad_re = Regexp.new("[#{bad_ctrl_codes.collect(&:chr).join}]")
          if file_data[0..1] == "\377\376" || file_data[0..1] == "\376\377"
            require 'iconv'
            ic = Iconv.new("UTF-8", "UTF-16")
            if ic.iconv(file_data) =~ bad_re
              msg = "UnifiedSources::Import::FileImporter#read_xml_file: Error: Cannot handle control characters in UTF-16 file #{path.inspect}"
              Rails.logger.warn(msg)
              puts msg
              raise "Invalid control characters in UTF-16 file."
            end
          elsif file_data =~ bad_re
            # Replace invalid XML control characters with escaped equivalents.
            # Technically, the escaped versions are only valid XML 1.1, and escaping
            # chr(0) is always invalid, but at least it doesn't break Nokogiri.
            # http://www.w3.org/International/questions/qa-controls
            bad_found = []
            bad_ctrl_codes.each{|ctrl|
              bad_chr = ctrl.chr
              if file_data.index(bad_chr)
                bad_found << ctrl
                escaped = "&#x%04x;" % ctrl # e.g. "&#x0019;" for chr(25)
                file_data = file_data.gsub(bad_chr, escaped)
              end
            }
            msg = "UnifiedSources::Import::FileImporter#read_xml_file: Warning: Replaced invalid control characters with codes #{bad_found.inspect} in file #{path.inspect}"
            Rails.logger.warn(msg)
            puts msg
          end
          Nokogiri::XML(file_data)
        end
      end
    end
  end
end
