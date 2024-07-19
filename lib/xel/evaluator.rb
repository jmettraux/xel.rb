# frozen_string_literal: true


module Xel

  # eval_XXX

  class << self

    protected

    def _eval_args(tree, context, opts={})

      sta = opts[:start] || 1
      max = opts[:max] || 99

      a = []
      tree[sta..-1].each do |t|
        break if a.length >= max
        a << do_eval(t, context)
      end

      a
    end

    def eval_str(tree, context); tree[1]; end

    def eval_num(tree, context)

      s = tree[1].gsub(',', '')

      s.index('.') ? s.to_f : s.to_i
    end

    def eval_var(tree, context)

      tree[1].split('.')
        .inject(context) { |r, k|
          if r && r.respond_to?(:has_key?)
            ks = k.to_sym
            if r.has_key?(k)
              r[k]
            elsif r.has_key?(ks)
              r[ks]
            else
              nil
            end
          else
            nil
          end }
    end

    def eval_inv(tree, context)
      1.0 / do_eval(tree[1], context)
    end
    def eval_opp(tree, context)
      - do_eval(tree[1], context)
    end

    def eval_bool(tree, context); tree[0].downcase == 'true'; end

    def do_eval_equal(sign, a0, a1)

      a0 = '' if a0 == nil
      a1 = '' if a1 == nil

      sign == '=' ? a0 == a1 : a0 != a1
    end

    def eval_cmp(tree, context)

      args = _eval_args(tree, context, start: 2)

      case tree[1]
      when '=', '!=' then do_eval_equal(tree[1], args[0], args[1])
      when '>' then args[0] > args[1]
      when '<' then args[0] < args[1]
      when '>=' then args[0] >= args[1]
      when '<=' then args[0] <= args[1]
      when '=~' then !! args[0].to_s.match(args[1].to_s)
      when 'IN' then args[1].include?(args[0])
      else false
      end

    rescue
      false
    end

    def eval_TRUE(tree, context); tree[0] == 'TRUE'; end
    alias eval_FALSE eval_TRUE

    alias eval_arr _eval_args

    def eval_plus(tree, context)

      args = _eval_args(tree, context)

      if args[0].is_a?(Array)
        args.inject([]) { |a, arg| a.concat(arg) }
      elsif args.find { |a| ! a.is_a?(Numeric) }
        args.map(&:to_s).join
      elsif args.all? { |a| a.is_a?(Numeric) }
        args.inject(&:+)
      else
        nil
      end
    end

    def eval_amp(tree, context)

      _eval_args(tree, context, start: 1).collect(&:to_s).join
    end

    def eval_AND(tree, context)

      ! tree[1..-1].find { |c| do_eval(c, context) != true }
    end

    def eval_OR(tree, context)

      !! tree[1..-1].find { |c| do_eval(c, context) == true }
    end

    def eval_NOT(tree, context)

      ! do_eval(tree[1], context)
    end

    def eval_ORV(tree, context)

      tree[1..-1].each do |t|
        v = do_eval(t, context)
        return v if v != '' && v!= nil
      end

      nil
    end

    def eval_IF(tree, context)

      return do_eval(tree[2], context) if do_eval(tree[1], context)
      do_eval(tree[3], context)
    end

    def eval_CASE(tree, context)

      control = do_eval(tree[1], context)
      args = tree[2..-1]

      if control == true || control == false
        args.unshift(control)
        control = true
      end

      default = args.size.odd? ? args.pop : nil

      while (ab = args.shift(2)).any?
        return do_eval(ab[1], context) if control == do_eval(ab[0], context)
      end
      do_eval(default, context)
    end
    alias eval_SWITCH eval_CASE

    def eval_UNIQUE(tree, context)

      arr = do_eval(tree[1], context)

      fail ArgumentError.new("UNIQUE() expects array not #{arr.class}") \
        unless arr.is_a?(Array)

      arr.uniq
    end

    # SORT({ 1, 3, 2 })         --> [ 1, 2, 3 ]
    # SORT({ 1, 3, 2 }, 1, -1)  --> [ 3, 2, 1 ]
    #
    def eval_SORT(tree, context)

      #arr, col, dir = _eval_args(tree, context, max: 3)
      arr, _, dir = _eval_args(tree, context, max: 3)

      fail ArgumentError.new("SORT() expects array not #{arr.class}") \
        unless arr.is_a?(Array)

      r =
        arr.all? { |e| e.is_a?(Numeric) } ? arr.sort :
        arr.sort_by(&:to_s)

      dir == -1 ? r.reverse : r
    end

    def eval_MUL(tree, context)

      args = _eval_args(tree, context)

      if args.find { |a| ! (a.is_a?(Integer) || a.is_a?(Float)) }
        fail ArgumentError.new("cannot multiply #{args.inspect}")
      end

      args.reduce(&:*)
    end

    def eval_SUM(tree, context)

      f = lambda { |r, e|
        case e
        when Numeric then r + e
        when Array then e.inject(r, &f)
        else r; end }

      _eval_args(tree, context).inject(0, &f);
    end

    def eval_PRODUCT(tree, context)

      f = lambda { |r, e|
        case e
        when Numeric then r * e
        when Array then e.inject(r, &f)
        else r; end }

      _eval_args(tree, context).inject(1, &f)
    end

    def eval_MIN(tree, context)

      args = _eval_args(tree, context)

      if args.find { |a| ! (a.is_a?(Integer) || a.is_a?(Float)) }
        args.first
      else
        args.min
      end
    end

    def eval_MAX(tree, context)

      args = _eval_args(tree, context)

      if args.find { |a| ! (a.is_a?(Integer) || a.is_a?(Float)) }
        args.first
      else
        args.max
      end
    end

    def eval_MATCH(tree, context)

      elt = do_eval(tree[1], context)
      arr = do_eval(tree[2], context)

      return -1 unless arr.is_a?(Array)
      arr.index(elt) || -1
    end

    def eval_HAS(tree, context)

      col = do_eval(tree[1], context)
      elt = do_eval(tree[2], context)

      return !! col.index(elt) if col.is_a?(Array)
      return col.has_key?(elt) if col.is_a?(Hash)
      false
    end

    def eval_INDEX(tree, context)

      col = do_eval(tree[1], context)
      i = do_eval(tree[2], context)

      return 0 unless col.is_a?(Array)
      return 0 unless i.is_a?(Numeric)

      i < 0 ?
        col[i] :
        col[i.to_i - 1]
    end

    def eval_COUNTA(tree, context)

      col = do_eval(tree[1], context)

      col.is_a?(Array) ? col.length : 0
    end

    def eval_ISBLANK(tree, context)

      val = do_eval(tree[1], context)

      val == '' || val == nil
    end

    def eval_ISNUMBER(tree, context)

      do_eval(tree[1], context).is_a?(Numeric)
    end

    def eval_PROPER(tree, context)
      do_eval(tree[1], context).gsub(/(^|[^a-z])([a-z])/) { $1 + $2.upcase }
    end
    def eval_LOWER(tree, context)
      do_eval(tree[1], context).downcase
    end
    def eval_UPPER(tree, context)
      do_eval(tree[1], context).upcase
    end

    def eval_LN(tree, context)
      a = do_eval(tree[1], context)
      return a.map { |e| Math.log(e) } if a.is_a?(Array)
      Math.log(a)
    end
    def eval_SQRT(tree, context)
      a = do_eval(tree[1], context)
      return a.map { |e| Math.sqrt(e) } if a.is_a?(Array)
      Math.sqrt(a)
    end

    def eval_LET(tree, context)

      ctx = context.dup

      key = nil
        #
      tree[1..-2].each_with_index do |t, i|
        if i % 2 == 0
          key = (t[0] == 'var') ? t[1] : do_eval(t, ctx).to_s
        else
          ctx[key] = do_eval(t, ctx)
        end
      end

      do_eval(tree[-1], ctx)
    end

    def eval_ROUND(tree, context)

      args = _eval_args(tree, context, max: 2)
      args << 0 if args.length < 2

      args[0].round(args[1])
    end

    def eval_MROUND(tree, context)

      n, m = _eval_args(tree, context, max: 2)

      return Float::NAN if (n * m) < 0

      (n.to_f / m).round * m rescue nil
    end

    alias eval_MROUND2 eval_MROUND

    def eval_CEILING(tree, context)

      as = _eval_args(tree, context, max: 2)
      as << 1 if as.length < 2
      n, m = as
      r = n % m

      r == 0 ? n : n - r + m
    end

    def eval_FLOOR(tree, context)

      as = _eval_args(tree, context, max: 2)
      as << 1 if as.length < 2
      n, m = as

      n - (n % m)
    end

    def eval_TRUNC(tree, context)

      as = _eval_args(tree, context, max: 2)
      as << 0 if as.length < 2
      n = as[0]; m = 10 ** as[1]

      (n * m).floor.to_f / m
    end

    def p2(n); n * n; end

    def eval_STDEV(tree, context)

      a = do_eval(tree[1], context)
      s = a.inject(0.0) { |acc, e| acc + e }
      m = s / a.length
      s = a.inject(0.0) { |acc, e| acc + p2(e - m) }
      v = s / (a.length - 1)

      Math.sqrt(v)
    end

    def eval_LAMBDA(tree, context)

      args = tree[1..-1].collect { |t| t[1] }
      code = tree[-1]

      l =
        Proc.new do |*argl|
          ctx = context.dup.merge(argl.pop)
          args.each_with_index { |arg, i| ctx[arg] = argl[i] }
          Xel.do_eval(code, ctx)
        end
      class << l; attr_accessor :_source; end
      l._source = tree._source

      l
    end

    def eval_KALL(tree, context)

      args = _eval_args(tree, context)
      args << context

      fun = args.shift

      fun.call(*args)
    end

    def eval_MAP(tree, context)

      arr, fun = _eval_args(tree, context, max: 2)

      arr.collect { |e| fun.call(e, context) }
    end

    def eval_REDUCE(tree, context)

      ts = tree[1..-1]
      fun = do_eval(ts.pop, context)
      v0 = do_eval(ts[0], context)

      acc, arr = nil
        if ts.length == 1
          arr = v0
          acc = arr.shift
        else
          acc = v0
          arr = do_eval(ts[1], context)
        end

      arr.inject(acc) { |r, e| fun.call(r, e, context) }
    end

    def do_eval(tree, context={})

      return tree unless tree.is_a?(Array) && tree.first.class == String

      t0 = tree[0]

      if (v = context[t0]) && v.is_a?(Proc)
        args = _eval_args(tree, context)
        args << context
        v.call(*args)
      else
        send("eval_#{t0}", tree, context)
      end
    end

    public

    def eval(s, context={})

      t = s.is_a?(Array) ? s : Xel::Parser.parse(s)
      fail ArgumentError.new("syntax error in >>#{s}<<") unless t

      do_eval(t, context)
    end
  end
end

