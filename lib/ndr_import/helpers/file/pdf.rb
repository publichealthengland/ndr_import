module NdrImport
  module Helpers
    module File
      # This mixin adds PDF functionality to unified importers. It provides a file reader method.
      module Pdf
        def read_pdf_file(path)
          require 'pdf-reader'
          lines = []
          pagenum = 0
          begin
            reader = PDF::Reader.new(SafeFile.safepath_to_string(path))

            reader.pages.each_with_index do |page|
              lines.concat page.text.split("\n")
              pagenum += 1
            end
          rescue => e
            raise("Invalid format on page #{pagenum + 1} of #{SafeFile.basename(path)}")
          end
          lines
        end
      end
    end
  end
end
