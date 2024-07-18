# frozen_string_literal: true


module Xel

  # eval_XXX

  class << self

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
      1.0 / self.do_eval(tree[1], context)
    end
    def eval_opp(tree, context)
      - self.do_eval(tree[1], context)
    end

    def eval_bool(tree, context); tree[0].downcase == 'true'; end

    def do_eval_equal(sign, a0, a1)

      a0 = '' if a0 == nil
      a1 = '' if a1 == nil

      sign == '=' ? a0 == a1 : a0 != a1
    end

    def eval_cmp(tree, context)

      args = tree[2..-1].collect { |c| self.do_eval(c, context) }

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

    def eval_arr(tree, context)

      tree[1..-1].collect { |c| do_eval(c, context) }
    end

    def eval_plus(tree, context)

      args = tree[1..-1].collect { |c| do_eval(c, context) }

      if args[0].is_a?(Numeric)
        args.inject(&:+)
      elsif args[0].is_a?(Array)
        args.inject([]) { |a, arg| a.concat(arg) }
      else
        nil
      end
    end

    def eval_AND(tree, context)

#p[ :AND, tree, tree[1..-1].collect { |c| do_eval(c, context) } ]
      ! tree[1..-1].find { |c| do_eval(c, context) != true }
    end

    def eval_OR(tree, context)

#p[ :OR, tree, tree[1..-1].collect { |c| do_eval(c, context) } ]
      !! tree[1..-1].find { |c| do_eval(c, context) == true }
    end

    def eval_NOT(tree, context)

      ! do_eval(tree[1], context)
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

    def eval_MUL(tree, context)

      args = tree[1..-1].collect { |c| do_eval(c, context) }

      if args.find { |a| ! (a.is_a?(Integer) || a.is_a?(Float)) }
        fail ArgumentError.new("cannot multiply #{args.inspect}")
      end

      args.reduce(&:*)
    end

    def eval_SUM(tree, context)

      args = tree[1..-1].collect { |c| do_eval(c, context) }

      if args.find { |a|
        ! (a.is_a?(Integer) || a.is_a?(Float) || a.is_a?(Array)) }
      then
        args = args.map(&:to_s)
      end

      args.reduce(&:+)
    end

    def eval_MIN(tree, context)

      as = tree[1..-1].collect { |c| do_eval(c, context) }

      if as.find { |a| ! (a.is_a?(Integer) || a.is_a?(Float)) }
        as.first
      else
        as.min
      end
    end

    def eval_MAX(tree, context)

      as = tree[1..-1].collect { |c| do_eval(c, context) }

      if as.find { |a| ! (a.is_a?(Integer) || a.is_a?(Float)) }
        as.first
      else
        as.max
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
          key = (t[0] == 'var') ? t[1] : self.do_eval(t, ctx).to_s
        else
          ctx[key] = self.do_eval(t, ctx)
        end
      end

      self.do_eval(tree[-1], ctx)
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

#  evals.LAMBDA = function(tree, context) {
#
#    let args = tree.slice(1).map(function(t) { return t[1]; });
#
#    let code = tree[tree.length - 1];
#
#    let l = function() {
#
#      let as = Array.from(arguments);
#
#      let ctx1 = Object.assign({}, context, as.pop());
#      for (let i = 0, l = args.length; i < l; i++) { ctx1[args[i]] = as[i]; }
#
#      return self.eval(code, ctx1);
#    };
#
#    l._source = tree._source;
#
#    return l;
#  };
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

    def do_eval(tree, context={})

      return tree unless tree.is_a?(Array) && tree.first.class == String

      t0 = tree[0]

      if (v = context[t0]) && v.is_a?(Proc)
        args = tree[1..-1].collect { |t| do_eval(t, context) }
        args << context
        v.call(*args)
      else
        send("eval_#{t0}", tree, context)
      end
    end

    def eval(s, context={})

      t = s.is_a?(Array) ? s : Xel::Parser.parse(s)
      fail ArgumentError.new("syntax error in >>#{s}<<") unless t

      do_eval(t, context)
    end
  end
end

