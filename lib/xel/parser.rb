# frozen_string_literal: true


module Xel::Parser include Raabro

  # parse

  def aa(i); rex(nil, i, /\{\s*/); end
  def az(i); rex(nil, i, /\}\s*/); end
  def pa(i); rex(nil, i, /\(\s*/); end
  def pz(i); rex(nil, i, /\)\s*/); end
  def com(i); rex(nil, i, /,\s*/); end

  def number(i)
    rex(:number, i, /-?([0-9]*\.[0-9]+|[0-9][,0-9]*[0-9]|[0-9]+)\s*/)
  end

  def var(i); rex(:var, i, /[a-z_][A-Za-z0-9_.]*\s*/); end

  def arr(i); eseq(:arr, i, :aa, :cmp, :com, :az); end

  def qstring(i); rex(:qstring, i, /'(\\'|[^'])*'\s*/); end
  def dqstring(i); rex(:dqstring, i, /"(\\"|[^"])*"\s*/); end
  def string(i); alt(:string, i, :dqstring, :qstring); end

  def funargs(i); eseq(:funargs, i, :pa, :cmp, :com, :pz); end
  def funname(i); rex(:funname, i, /[A-Z][A-Z0-9]*/); end
  def fun(i); seq(:fun, i, :funname, :funargs); end

  def comparator(i); rex(:comparator, i, /([\<\>]=?|=~|!?=|IN)\s*/); end
  def multiplier(i); rex(:multiplier, i, /[*\/]\s*/); end
  def adder(i); rex(:adder, i, /[+\-]\s*/); end

  def par(i); seq(:par, i, :pa, :cmp, :pz); end
  def exp(i); alt(:exp, i, :par, :fun, :number, :string, :arr, :var); end

  def mul(i); jseq(:mul, i, :exp, :multiplier); end
  def add(i); jseq(:add, i, :mul, :adder); end

  def rcmp(i); seq(:rcmp, i, :comparator, :add); end
  def cmp(i); seq(:cmp, i, :add, :rcmp, '?'); end

  # rewrite

  def rewrite_cmp(tree)

    return rewrite(tree.children.first) if tree.children.size == 1

    [ 'cmp',
      tree.children[1].children.first.string.strip,
      rewrite(tree.children[0]),
      rewrite(tree.children[1].children[1]) ]
  end

  def rewrite_add(tree)

    return rewrite(tree.children.first) if tree.children.size == 1

    cn = tree.children.dup
    a = [ tree.name == :add ? 'SUM' : 'MUL' ]
    mod = nil

    while c = cn.shift
      v = rewrite(c)
      v = [ mod, v ] if mod
      a << v
      c = cn.shift
      break unless c
      mod = { '-' => 'opp', '/' => 'inv' }[c.string.strip]
    end

    a
  end
  alias rewrite_mul rewrite_add

  def rewrite_fun(tree)

    [ tree.children[0].string ] +
    tree.children[1].children.select(&:name).collect { |c| rewrite(c) }
  end

  def rewrite_exp(tree); rewrite(tree.children[0]); end
  def rewrite_par(tree); rewrite(tree.children[1]); end

  def rewrite_arr(tree)

    [ 'arr',
      *tree.children.inject([]) { |a, c| a << rewrite(c) if c.name; a } ]
  end

  def rewrite_var(tree); [ 'var', tree.string.strip ]; end
  def rewrite_number(tree); [ 'num', tree.string.strip ]; end

  def rewrite_string(tree)

    s = tree.children[0].string.strip
    q = s[0]
    s = s[1..-2]

    [ 'str', q == '"' ? s.gsub("\\\"", '"') : s.gsub("\\'", "'") ]
  end
end

