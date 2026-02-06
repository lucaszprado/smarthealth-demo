module ApplicationError
  class FilterError < StandardError
  end

  class MeasureValidationError < StandardError
  end

  class BiomarkerRangeError < StandardError
  end
end
