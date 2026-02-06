# Service for parsing Excel files and converting them to structured data
#
# This service automatically reads Excel files and converts them to Ruby hashes
# using the first row as headers for the hash keys. It supports multiple sheets
# and provides validation capabilities.
#
# @example Basic usage
#   parser = ExcelParserService.new('path/to/file.xlsx')
#   data = parser.parse_sheet('Sheet1')
#
# @example Parse all sheets
#   parser = ExcelParserService.new('path/to/file.xlsx')
#   all_data = parser.parse_all_sheets
#
# @since 1.0.0
class ExcelParserService
  # Initialize the Excel parser service
  #
  # @param file_path [String] Path to the Excel file to parse
  # @raise [ArgumentError] If the file path is invalid or file doesn't exist
  # @raise [RuntimeError] If the file format is not supported by Roo
  #
  # @example
  #   parser = ExcelParserService.new('data.xlsx')
  #   parser = ExcelParserService.new((Rails.root.join('data.xlsx')).to_s)
  def initialize(file_path)
    @file_path = file_path.to_s #file_path must be a string for Roo::Spreadsheet
    @workbook = Roo::Spreadsheet.open(@file_path)
  end

  attr_reader :workbook, :file_path

  # Parse all sheets in the workbook automatically
  #
  # Reads all sheets from the Excel file and returns them as a hash where
  # keys are sheet names (as symbols) and values are arrays of row hashes.
  #
  # @return [Hash<Symbol, Array<Hash>>] Hash with sheet names as keys and arrays of row data as values
  # @example
  #   parser = ExcelParserService.new('data.xlsx')
  #   all_data = parser.parse_all_sheets
  #   # Returns: { :products => [...], :categories => [...], :users => [...] }
  #
  # To understand the structure of the data from each sheet, check the parse_sheet method YARD documentation.
  def parse_all_sheets
    result = {}

    @workbook.sheets.each do |sheet_name|
      result[sheet_name.to_sym] = parse_sheet(sheet_name)
    end

    result
  end

  # Parse a specific sheet using headers as hash keys
  #
  # Reads a single sheet from the Excel file and converts it to an array of hashes.
  # Each hash represents a row of data with keys from the header row.
  #
  # @param sheet_name [String] Name of the sheet to parse
  # @return [Array<Hash>] Array of hashes representing rows, where keys are column headers
  # @example
  #   parser = ExcelParserService.new('data.xlsx')
  #   products = parser.parse_sheet('products')
  #   # Returns: [{ :name => "Laptop", :price => "999.99" }, { :name => "Book", :price => "19.99" }]
  #   # Returns nil if cell is empty
  #   # Returns numbers in float format, text as string and dates as date objects
  def parse_sheet(sheet_name)
    sheet = @workbook.sheet(sheet_name)
    return [] unless sheet

    # Read headers from first row
    headers = read_headers(sheet)
    return [] if headers.empty?

    rows = []

    # Start from row 2 (data rows)
    (2..sheet.last_row).each do |row|
      row_data = {}

      headers.each_with_index do |header, index|
        column_index = index + 1
        cell_value = sheet.cell(row, column_index)
        row_data[header.to_sym] = cell_value.is_a?(String) ? cell_value&.strip : cell_value
      end

      # Skip empty rows (all values are blank)
      next if row_data.values.all?(&:blank?)

      rows << row_data
    end

    rows
  end

  # Get headers from a specific sheet
  #
  # Retrieves the column headers from the first row of a specified sheet.
  #
  # @param sheet_name [String] Name of the sheet to get headers from
  # @return [Array<String>] Array of header strings from the first row
  # @example
  #   parser = ExcelParserService.new('data.xlsx')
  #   headers = parser.get_headers('products')
  #   # Returns: ["name", "price", "category", "description"]
  def get_headers(sheet_name)
    sheet = @workbook.sheet(sheet_name)
    return [] unless sheet

    read_headers(sheet)
  end

  # Get sheet structure (headers and dimensions)
  #
  # Retrieves both the headers and dimensions of a specified sheet.
  #
  # @param sheet_name [String] Name of the sheet to analyze
  # @return [Hash, nil] Hash containing headers and dimensions, or nil if sheet doesn't exist
  # @option return [Array<String>] :headers Array of column headers
  # @option return [Hash] :dimensions Sheet dimensions with :rows and :columns keys
  # @example
  #   parser = ExcelParserService.new('data.xlsx')
  #   structure = parser.get_sheet_structure('products')
  #   # Returns: { headers: ["name", "price"], dimensions: { rows: 100, columns: 2 } }
  def get_sheet_structure(sheet_name)
    sheet = @workbook.sheet(sheet_name)
    return nil unless sheet

    {
      headers: read_headers(sheet),
      dimensions: {
        rows: sheet.last_row,
        columns: sheet.last_column
      }
    }
  end

  # Get structure of all sheets
  #
  # Retrieves the structure (headers and dimensions) of all sheets in the workbook.
  #
  # @return [Hash<String, Hash>] Hash with sheet names as keys and structure hashes as values
  # @example
  #   parser = ExcelParserService.new('data.xlsx')
  #   all_structures = parser.get_all_sheets_structure
  #   # Returns: { "products" => { headers: [...], dimensions: {...} }, "users" => {...} }
  def get_all_sheets_structure
    result = {}

    @workbook.sheets.each do |sheet_name|
      result[sheet_name] = get_sheet_structure(sheet_name)
    end

    result
  end

  # Validate that required sheets exist
  #
  # Checks if all required sheets are present in the Excel workbook.
  #
  # @param required_sheets [Array<String>] Array of sheet names that must exist
  # @return [Array<String>] Array of error messages for missing sheets (empty if all valid)
  # @example
  #   parser = ExcelParserService.new('data.xlsx')
  #   errors = parser.validate_sheets(['products', 'categories', 'users'])
  #   # Returns: [] if all sheets exist, or ["Sheet 'missing_sheet' not found"] if not
  def validate_sheets(required_sheets)
    errors = []

    required_sheets.each do |sheet_name|
      unless @workbook.sheets.include?(sheet_name)
        errors << "Sheet '#{sheet_name}' not found in Excel file"
      end
    end

    errors
  end

  # Validate that required headers exist in a sheet
  #
  # Checks if all required column headers are present in the specified sheet.
  #
  # @param sheet_name [String] Name of the sheet to validate
  # @param required_headers [Array<String>] Array of header names that must exist
  # @return [Array<String>] Array of error messages for missing headers (empty if all valid)
  # @example
  #   parser = ExcelParserService.new('data.xlsx')
  #   errors = parser.validate_headers('products', ['name', 'price', 'category'])
  #   # Returns: [] if all headers exist, or ["Header 'missing_header' not found"] if not
  def validate_headers(sheet_name, required_headers)
    sheet = @workbook.sheet(sheet_name)
    return ["Sheet '#{sheet_name}' not found"] unless sheet

    actual_headers = read_headers(sheet)
    errors = []

    required_headers.each do |required_header|
      unless actual_headers.include?(required_header)
        errors << "Header '#{required_header}' not found in sheet '#{sheet_name}'"
      end
    end

    errors
  end

  # Get available sheets
  #
  # Returns a list of all sheet names available in the Excel workbook.
  #
  # @return [Array<String>] Array of sheet names
  # @example
  #   parser = ExcelParserService.new('data.xlsx')
  #   sheets = parser.available_sheets
  #   # Returns: ["products", "categories", "users"]
  def available_sheets
    @workbook.sheets
  end

  # Get sheet dimensions
  #
  # Returns the dimensions (number of rows and columns) of a specified sheet.
  #
  # @param sheet_name [String] Name of the sheet to get dimensions for
  # @return [Hash, nil] Hash with :rows and :columns keys, or nil if sheet doesn't exist
  # @example
  #   parser = ExcelParserService.new('data.xlsx')
  #   dimensions = parser.sheet_dimensions('products')
  #   # Returns: { rows: 100, columns: 5 }
  def sheet_dimensions(sheet_name)
    sheet = @workbook.sheet(sheet_name)
    return nil unless sheet

    {
      rows: sheet.last_row,
      columns: sheet.last_column
    }
  end

  private

  # Read headers from the first row of a sheet
  #
  # Extracts column headers from the first row of a sheet and handles empty headers
  # by providing default names.
  #
  # @param sheet [Roo::Sheet] The sheet object to read headers from
  # @return [Array<String>] Array of header strings, with defaults for empty headers
  # @example
  #   headers = read_headers(sheet)
  #   # Returns: ["name", "price", "column_3"] (if third column was empty)
  def read_headers(sheet)
    headers = []

    (1..sheet.last_column).each do |column_index|
      header_value = sheet.cell(1, column_index)&.strip
      # Use a default header if the cell is empty
      header_value = "column_#{column_index}" if header_value.blank?
      # Convert header to snake_case
      header_value = header_value.downcase.gsub(/[^a-z0-9\s]/i, ' ').strip.gsub(/\s+/, '_')
      headers << header_value
    end

    headers
  end
end
