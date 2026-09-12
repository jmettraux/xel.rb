
#
# Specifying xel.rb
#
# Wed Jul 17 14:08:24 JST 2024  The Board Room
#

require 'pp'
require 'json'
#require 'ostruct'

require 'xel'


class Probatio::Group

  def trunc(s, max)
    s = s.gsub(/\s*\n\s*/, '↩  ')
    s[0..max] + (s.length > max ? '…' : '')
  end

  def trunc_out(out, max)
    return '(a lambda)' if out.is_a?(Proc)
    trunc(out.inspect, max)
  end
end

class Probatio::Context

  def jruby?; !! RUBY_PLATFORM.match(/java/); end
  def windows?; Gem.win_platform?; end
end # Probatio::Context


