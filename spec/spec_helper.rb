
#
# Specifying xel.rb
#
# Wed Jul 17 14:08:24 JST 2024  The Board Room
#

require 'pp'
require 'ostruct'

require 'xel'


module Helpers

  def jruby?; !! RUBY_PLATFORM.match(/java/); end
  def windows?; Gem.win_platform?; end
end # Helpers

RSpec.configure do |c|

  c.alias_example_to(:they)
  c.alias_example_to(:so)
  c.include(Helpers)
end

