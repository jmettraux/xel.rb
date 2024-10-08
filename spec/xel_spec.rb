
#
# spec'ing Xel
#
# Fri Sep 25 13:24:56 JST 2015
#

require 'spec/spec_helper'


def _eval(s)
  return Float::NAN if s == 'NaN'
  return (lambda() {}) if s == 'lambda'
  JSON.parse(JSON.dump(eval(s)))
end

XEL_CASES =
  eval(File.read('spec/_xel.rb')) +
  File.read('spec/_xel_eval.txt')
    .gsub(/\\\n/, '')
    .split("\n")
    .inject([]) { |a, l|
      ss = l.strip.split(/[→⟶]/)
      if ss.length == 2
        a << { c: ss[0], o: _eval(ss[1].strip) }
      elsif ss.length >= 3
        a << { c: ss[0], ctx: _eval(ss[1]), o: _eval(ss[2]) }
      end
      a } +
  File.read('spec/_xel_tree.txt')
    .split(/]$/)
    .map { |ll|
      (ll + ']').strip.split("\n").reject { |s| s.match(/^\s*#/) }.join('') }
    .inject([]) { |a, l|
      ss = l.strip.split(/[→⟶]/)
      a << { c: ss[0], t: eval(ss[1].strip) } if ss.length > 1
      a }
#pp XEL_CASES; p XEL_CASES.length

def trunc(s, max)
  s = s.gsub(/\s*\n\s*/, '↩  ')
  s[0..max] + (s.length > max ? '…' : '')
end
def trunc_out(out, max)
  return '(a lambda)' if out.is_a?(Proc)
  trunc(out.inspect, max)
end


describe Xel::Parser do

  describe '.parse' do

    XEL_CASES.each do |k|

      code = k[:c]
      tree = k[:t]; next unless tree

      it "parses successfully #{code.inspect}" do

#Raabro.pp(Xel::Parser.parse(code, debug: 2), colours: true)
#Raabro.pp(Xel::Parser.parse(code, debug: 3), colours: true)
        expect(
          Xel::Parser.parse(code)
        ).to eq(
          tree
        )
      end
    end

    it 'returns nil when it cannot parse' do

      expect(Xel::Parser.parse('(')).to eq(nil)
    end
  end
end

describe Xel do

  describe '.eval' do

    XEL_CASES.each do |k|

      next unless k.has_key?(:o)
      code = k[:c]
      ctx = k[:ctx] || {}
      out = k[:o]

      l =
        ctx.any? ? 29 : 56
      t =
        "evals #{trunc(code, l)} to #{trunc_out(out, l)}" +
        (ctx.any? ? ' when ' + trunc(ctx.inspect, l) : '')

      it(t) do

        r = Xel.eval(Xel::Parser.parse(code), ctx)

        floatify = lambda { |a|
          a.collect { |e|
            if e.is_a?(Float)
              r = '%0.2f' % e
              r.match?(/\.00$/) ? r.to_i : r
            else
              e
            end } }

        if out.is_a?(Proc)
          expect(r).to be_a(Proc)
          expect(r._source).to match(/^LAMBDA\(/)
        elsif out.is_a?(Float) && out.nan?
          expect(r.nan?).to eq(true)
        elsif out.is_a?(Float)
          expect('%0.2f' % r).to eq('%0.2f' % out)
        elsif out.is_a?(Array)
          expect(floatify[r]).to eq(floatify[out])
        else
          expect(r).to eq(out)
        end
      end
    end

    context 'custom functions' do

      they 'work' do

        r = Xel.eval(
          'Plus(1, 1)',
          { a: 0, Plus: lambda { |tree, context| [ tree[0], context.keys ] } })

        expect(r).to eq([ 'Plus', %i[ a Plus ] ])
      end
    end

    context 'VLOOKUP()' do

      before :each do
        @ctx = {
          table0: [
            [ 'finds - nada hello', 1.1 ],
            [ 'finds - income', 1.2 ],
            [ 'mac g - income', 1.3 ] ] }
      end

      it 'looks up and finds' do

        r = Xel.eval(
          "VLOOKUP('finds - income', table0, 2)",
          @ctx)

        expect(r).to eq(1.2)
      end

      it 'looks up and finds, or not' do

        r = Xel.eval(%{
           { VLOOKUP('finds - income', table0, 2),
             VLOOKUP('mac g - income', table0, 2),
             VLOOKUP('fubar', table0, 2),
             VLOOKUP('finds - nada hello', table0, 2) }
               }.strip,
          @ctx)

        expect(r).to eq([ 1.2, 1.3, nil, 1.1 ])
      end

      it 'looks up and finds not' do

        r = Xel.eval(
          "VLOOKUP('fubar', table0, 2)",
          @ctx)

        expect(r).to eq(nil)
      end

      it 'fails' do

        expect {
          Xel.eval(
            "VLOOKUP('fubar', table0, 'abc')",
            @ctx)
        }.to raise_error(ArgumentError, / is not an integer/)
      end
    end

    context 'lambdas' do

      they 'have a _source' do

        r = Xel.eval("LAMBDA(a, b, a + b)", {})._source

        expect(r).to eq('LAMBDA(a, b, a + b)')
      end
    end

    context 'callbacks' do

      before(:each) { Xel.callbacks.clear }
      after(:each) { Xel.callbacks.clear }

      they 'are called twice per each `eval` step' do

        r = []

        Xel.callbacks <<
          lambda { |tree, context, ret=nil| r << [ tree, context, ret ] }

        Xel.eval('12 + a', { a: 34 })

        expect(
          r
        ).to eq([
          [["plus", ["num", "12"], ["var", "a"]], {a: 34}, nil],
          [["num", "12"], {a: 34}, nil],
          [["num", "12"], {a: 34}, 12],
          [["var", "a"], {a: 34}, nil],
          [["var", "a"], {a: 34}, 34],
          [["plus", ["num", "12"], ["var", "a"]], {a: 34}, 46]
        ])
      end
    end

    context 'ctx._callbacks' do

      before(:each) { Xel.callbacks.clear }
      after(:each) { Xel.callbacks.clear }

      they 'are called twice per each `eval` step' do

        r = []
        cb = lambda { |tree, _, ret=nil| r << [ tree, ret ] }
        Xel.eval('12 + a', { a: 35, _callbacks: [ cb ] })

        expect(
          r
        ).to eq([
          [["plus", ["num", "12"], ["var", "a"]], nil],
          [["num", "12"], nil],
          [["num", "12"], 12],
          [["var", "a"], nil],
          [["var", "a"], 35],
          [["plus", ["num", "12"], ["var", "a"]], 47]
        ])
      end
    end
  end
end

