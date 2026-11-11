if exists('b:current_syntax') | finish | endif
runtime! syntax/haskell.vim
syn keyword spthyKeyword theory begin end rule lemma functions equations builtins let in
hi def link spthyKeyword Keyword
let b:current_syntax = 'spthy'
