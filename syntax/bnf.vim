if exists('b:current_syntax') | finish | endif
syn match bnfComment /#.*$/
syn match bnfRule /<[^>]*>/
syn match bnfOperator /::=\|[|*+?]/
syn region bnfString start=/"/ skip=/\\"/ end=/"/
hi def link bnfComment Comment
hi def link bnfRule Identifier
hi def link bnfOperator Operator
hi def link bnfString String
let b:current_syntax = 'bnf'
