
"
" in .vimrc :
"   set runtimepath+=spec/vim/
"
" place at the end of _xel_eval.txt :
"   # vim: syntax=xel_eval
"

  " (<pattern>)@<=<match>  ~~~ positive lookbehind
  " <match>(<pattern>)@=   ~~~ positive lookahead
  " (<pattern>)@!<match>   ~~~ negative lookbehind
  " <match>(<pattern>)@!   ~~~ negative lookahead

hi! default link xeComment Comment
hi! xeCode cterm=NONE ctermfg=green ctermbg=16
hi! xeArrow cterm=NONE ctermfg=blue ctermbg=16
hi! xeOutcome cterm=NONE ctermfg=darkgreen ctermbg=16
hi! xeContext cterm=NONE ctermfg=darkgrey ctermbg=16

syn match xeComment '\v^ *#[^\n]*\n'
syn match xeCode '\v^[^\U27f6]+(%U27f6)@='
syn match xeArrow '\v%U27f6'
syn match xeContext '\v(%U27f6)@<=[^\U27f6]+(%U27f6)@='
syn match xeOutcome '\v(%U27f6)@<=[^\U27f6]+$'

let b:current_syntax = "xel_eval"

