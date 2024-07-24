# frozen_string_literal: true


module Xel

  VERSION = '1.6.0'
end

require 'raabro'

require 'xel/parser'
require 'xel/evaluator'


module Xel

  class << self

    def parse(s)

      Xel::Parser.parse(s)
    end
  end
end

