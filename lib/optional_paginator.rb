# frozen_string_literal: true

require_relative 'null_paginator'

class OptionalPaginator < JSONAPI::Paginator
  class << self
    attr_accessor :wrapped_class

    def for(paginator_class_argument)
      Class.new(self).tap do |wrapper_class|
        wrapper_class.wrapped_class = paginator_class_argument
      end
    end
  end

  attr_reader :delegate

  def initialize(params)
    @delegate = paginator_for_params(params).new(params)
  end

  def paginator_for_params(params)
    if params.nil?
      NullPaginator
    else
      self.class.wrapped_class
    end
  end

  def apply(relation, order_options)
    delegate.apply(relation, order_options)
  end
end
