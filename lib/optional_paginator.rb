# frozen_string_literal: true

require_relative 'null_paginator'

class OptionalPaginator < SimpleDelegator
  class << self
    attr_accessor :wrapped_class

    def for(paginator_class_argument)
      Class.new(self).tap do |wrapper_class|
        wrapper_class.wrapped_class = paginator_class_argument
      end
    end
  end

  attr_reader :delegate

  def self.requires_record_count
    wrapped_class.requires_record_count
  end

  def initialize(params)
    inner_paginator = paginator_for_params(params).new(params)
    super(inner_paginator)
  end

  def paginator_for_params(params)
    if params.nil?
      NullPaginator
    else
      self.class.wrapped_class
    end
  end
end
