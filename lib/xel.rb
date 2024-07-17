# frozen_string_literal: true


module Xel

  VERSION = '1.5.1'
end

require 'raabro'

require 'xel/parser'
require 'xel/runner'


module Xel

  class << self

    def parse(s)

      Xel::Parser.parse(s)
    end
  end
end

