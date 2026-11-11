if exists('b:current_syntax') | finish | endif
syn match brainfuckOperator /[+<>.,-]/
syn match brainfuckLoop /\[\|\]/
hi def link brainfuckOperator Operator
hi def link brainfuckLoop Repeat
let b:current_syntax = 'brainfuck'
