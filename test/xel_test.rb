
#
# spec'ing Xel
#
# Fri Sep 25 13:24:56 JST 2015
#

def _eval(s)
  return Float::NAN if s == 'NaN'
  return (lambda() {}) if s == 'lambda'
  JSON.parse(JSON.dump(eval(s)))
end

XEL_CASES =
  eval(File.read('test/_xel.rb')) +
  File.read('test/_xel_eval.txt')
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
  File.read('test/_xel_tree.txt')
    .split(/]$/)
    .map { |ll|
      (ll + ']').strip.split("\n").reject { |s| s.match(/^\s*#/) }.join('') }
    .inject([]) { |a, l|
      ss = l.strip.split(/[→⟶]/)
      ss1 = ss[1] && ss[1].strip
      a << {
        c: ss[0],
        t: ss1 && ss1.match?(/^∅/) ? nil : eval(ss1)
          } if ss.length > 1
      a }
#pp XEL_CASES; p XEL_CASES.length


group Xel::Parser do

  group '.parse' do

    XEL_CASES.each do |k|

      code = k[:c]
      tree = k[:t]; next unless tree

      test "parses successfully #{code.inspect}" do

#Raabro.pp(Xel::Parser.parse(code, debug: 2), colours: true)
#Raabro.pp(Xel::Parser.parse(code, debug: 3), colours: true)
        assert Xel::Parser.parse(code), tree
      end
    end

    test 'returns nil when it cannot parse' do

      assert_nil Xel::Parser.parse('(')
    end
  end
end

group Xel do

  group '.eval' do

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

      test t do

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
          assert r.class, Proc
          assert r._source, /^LAMBDA\(/
        elsif out.is_a?(Float) && out.nan?
          assert r.nan?
        elsif out.is_a?(Float)
          assert '%0.2f' % r, '%0.2f' % out
        elsif out.is_a?(Array)
          assert floatify[r], floatify[out]
        else
          assert r, out
        end
      end
    end

    group 'custom functions' do

      test 'work' do

        r = Xel.eval(
          'Plus(1, 1)',
          { a: 0, Plus: lambda { |tree, context| [ tree[0], context.keys ] } })

        assert r, [ 'Plus', %i[ a Plus ] ]
      end
    end

    group 'VLOOKUP()' do

      before do
        @ctx = {
          table0: [
            [ 'finds - nada hello', 1.1 ],
            [ 'finds - income', 1.2 ],
            [ 'mac g - income', 1.3 ] ] }
      end

      test 'looks up and finds' do

        r = Xel.eval(
          "VLOOKUP('finds - income', table0, 2)",
          @ctx)

        assert r, 1.2
      end

      test 'looks up and finds, or not' do

        r = Xel.eval(%{
           { VLOOKUP('finds - income', table0, 2),
             VLOOKUP('mac g - income', table0, 2),
             VLOOKUP('fubar', table0, 2),
             VLOOKUP('finds - nada hello', table0, 2) }
               }.strip,
          @ctx)

        assert r, [ 1.2, 1.3, nil, 1.1 ]
      end

      test 'looks up and finds not' do

        r = Xel.eval(
          "VLOOKUP('fubar', table0, 2)",
          @ctx)

        assert_nil r
      end

      test 'fails' do

        assert_error(
          lambda { Xel.eval("VLOOKUP('fubar', table0, 'abc')", @ctx) },
          ArgumentError, / is not an integer/)
      end
    end

    group 'lambdas' do

      test 'have a _source' do

        r = Xel.eval("LAMBDA(a, b, a + b)", {})._source

        assert r, 'LAMBDA(a, b, a + b)'
      end
    end

    group 'callbacks' do

      before { Xel.callbacks.clear }
      after { Xel.callbacks.clear }

      test 'are called twice per each `eval` step' do

        r = []

        Xel.callbacks <<
          lambda { |tree, context, ret=nil| r << [ tree, context, ret ] }

        Xel.eval('12 + a', { a: 34 })

        assert(
          r,
          [[["plus", ["num", "12"], ["var", "a"]], {a: 34}, nil],
           [["num", "12"], {a: 34}, nil],
           [["num", "12"], {a: 34}, 12],
           [["var", "a"], {a: 34}, nil],
           [["var", "a"], {a: 34}, 34],
           [["plus", ["num", "12"], ["var", "a"]], {a: 34}, 46]])
      end
    end

    group 'ctx._callbacks' do

      before { Xel.callbacks.clear }
      after { Xel.callbacks.clear }

      test 'are called twice per each `eval` step' do

        r = []
        cb = lambda { |tree, _, ret=nil| r << [ tree, ret ] }
        Xel.eval('12 + a', { a: 35, _callbacks: [ cb ] })

        assert(
          r,
          [[["plus", ["num", "12"], ["var", "a"]], nil],
           [["num", "12"], nil],
           [["num", "12"], 12],
           [["var", "a"], nil],
           [["var", "a"], 35],
           [["plus", ["num", "12"], ["var", "a"]], 47]])
      end
    end
  end
end

