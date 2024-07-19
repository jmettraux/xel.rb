
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

    it 'returns null when it cannot parse'
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

      they 'work'

      #  r = @bro.eval(%{
      #    Xel.eval(
      #      'Plus(1, 1)',
      #      ctx = { a: 0, _custom_functions: {
      #        Plus: function(tree, context) {
      #          return [ tree[0], Object.keys(context) ];
      #        }
      #      } }); })
      #
      #  expect(r).to eq([ 'Plus', %w[ a _custom_functions _eval ] ])
      #end
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

      they 'are called twice per each `eval` step'

      #  r = @bro.eval(%{
      #    (function() {
      #      var a = [];
      #      Xel.callbacks.push(function(tree, context, ret) {
      #        a.push([ tree, context, ret ]);
      #      });
      #      Xel.eval("12 + a", { a: 34 });
      #      Xel.callbacks.pop();
      #      return a;
      #    }()); })
      #
      #  expect(
      #    r
      #  ).to eq([
      #    [["plus", ["num", "12"], ["var", "a"]], {"a"=>34}],
      #    [["num", "12"], {"a"=>34}],
      #    [["num", "12"], {"a"=>34}, 12],
      #    [["var", "a"], {"a"=>34}],
      #    [["var", "a"], {"a"=>34}, 34],
      #    [["plus", ["num", "12"], ["var", "a"]], {"a"=>34}, 46]
      #  ])
      #end
    end

    context 'ctx._callbacks' do

      they 'are called twice per each `eval` step'

      #  r = @bro.eval(%{
      #    (function() {
      #      var a =
      #        [];
      #      var cb =
      #        function(tree, context, ret) {
      #          a.push([ tree, ret ]);
      #        };
      #      var ctx =
      #        { a: 35, _callbacks: [ cb ] };
      #      Xel.eval("12 + a", ctx);
      #      return a;
      #    }()); })
      #
      #  expect(
      #    r
      #  ).to eq([
      #    [["plus", ["num", "12"], ["var", "a"]]],
      #    [["num", "12"]],
      #    [["num", "12"], 12],
      #    [["var", "a"]],
      #    [["var", "a"], 35],
      #    [["plus", ["num", "12"], ["var", "a"]], 47]
      #  ])
      #end
    end
  end

  describe '.sash' do

    { '' =>
        '|||0|0',
      'foo' =>
        'foo|o|foo|3|849955110',
      'bar' =>
        'bar|a|bar|3|815990707',
      'The quick brown fox jumps over the lazy dog.' =>
        'The qui|m|zy dog.|44|8835820411',
      'Lorem ipsum dolor sit amet, consectetur adip' =>
        'Lorem i|a|ur adip|44|-6470139925',
    }.each do |k, v|

      it "returns #{v} for '#{k}'"

      #  expect(@bro.eval(%{
      #    Xel.sash(#{k.inspect});
      #  }.strip)).to eq(v)
      #end
    end
  end
end

