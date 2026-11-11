if exists('b:current_syntax') | finish | endif
runtime! syntax/json.vim
syn match jsonTemplatePlaceholder /%[A-Z_][A-Z_]*%/
hi def link jsonTemplatePlaceholder Identifier
let b:current_syntax = 'json_template'
