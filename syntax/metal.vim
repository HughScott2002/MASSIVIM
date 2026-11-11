if exists('b:current_syntax') | finish | endif
runtime! syntax/cpp.vim
syn keyword metalQualifier kernel vertex fragment device constant thread threadgroup
syn match metalAttribute /\[\[.\{-}\]\]/
hi def link metalQualifier StorageClass
hi def link metalAttribute PreProc
let b:current_syntax = 'metal'
