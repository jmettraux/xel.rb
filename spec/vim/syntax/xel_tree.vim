
"
" in .vimrc :
"   set runtimepath+=spec/vim/
"
" place at the end of _xel_eval.txt :
"   # vim: syntax=xel_tree
"

  " (<pattern>)@<=<match>  ~~~ positive lookbehind
  " <match>(<pattern>)@=   ~~~ positive lookahead
  " (<pattern>)@!<match>   ~~~ negative lookbehind
  " <match>(<pattern>)@!   ~~~ negative lookahead

hi! default link xtComment Comment
hi! xtCode cterm=NONE ctermfg=green ctermbg=16
hi! xtArrow cterm=NONE ctermfg=blue ctermbg=16
"hi! xtOutcome cterm=NONE ctermfg=darkgreen ctermbg=16
"hi! xtContext cterm=NONE ctermfg=darkgrey ctermbg=16

syn match xtComment '\v^ *#[^\n]*\n'
syn match xtCode '\v^[^\U27f6]+(%U27f6)@='
syn match xtArrow '\v%U27f6'
"syn match xtContext '\v(%U27f6)@<=[^\U27f6]+(%U27f6)@='
"syn match xtOutcome '\v(%U27f6)@<=[^\U27f6]+$'

let b:current_syntax = "xel_tree"

