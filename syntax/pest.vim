if exists('b:current_syntax') | finish | endif
syn match pestComment /\/\/.*$/
syn keyword pestBuiltin ANY SOI EOI ASCII_DIGIT ASCII_ALPHA WHITESPACE COMMENT
syn match pestRule /^\s*[a-zA-Z_][a-zA-Z0-9_]*\ze\s*=/
syn match pestOperator /[~|*+?!&]/
syn region pestString start=/"/ skip=/\\"/ end=/"/
hi def link pestComment Comment
hi def link pestBuiltin Keyword
hi def link pestRule Identifier
hi def link pestOperator Operator
hi def link pestString String
let b:current_syntax = 'pest'
