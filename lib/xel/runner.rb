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

    def p2(n); n * n; end

    def eval_STDEV(tree, context)
      a = do_eval(tree[1], context)
      s = a.inject(0.0) { |acc, e| acc + e }
      m = s / a.length
      s = a.inject(0.0) { |acc, e| acc + p2(e - m) }
      v = s / (a.length - 1)
      Math.sqrt(v)
    end

    def do_eval(t, context={})

      return t unless t.is_a?(Array) && t.first.class == String

      send("eval_#{t[0]}", t, context)
    end

    def eval(s, context={})

      t = Xel::Parser.parse(s)
      fail ArgumentError.new("syntax error in >>#{s}<<") unless t

      do_eval(t, context)
    end

    def eeval(s, context={})

      return s unless s.is_a?(String)

      s = s.match(/\A\s*=?\s*(.+)\z/)[1]

      eval(s, context)
    end

    def keval(o, key, ctx)

      ukey = "_#{key}"

      if t = o[ukey]; return self.do_eval(t, ctx); end

      v = o[key]

      if v.is_a?(String) && v.strip[0] == '='

        o[ukey] = self.parse(v.strip[1..-1].strip)
        return self.do_eval(o[ukey], ctx)
      end

      v
    end
  end
end

