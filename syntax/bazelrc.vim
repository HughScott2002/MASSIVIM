if exists('b:current_syntax') | finish | endif
syn match bazelrcComment /^\s*#.*$/
syn match bazelrcCommand /^\s*[^#[:space:]][^[:space:]]*/
syn match bazelrcOption /--[a-zA-Z0-9_-]*/
hi def link bazelrcComment Comment
hi def link bazelrcCommand Keyword
hi def link bazelrcOption Identifier
let b:current_syntax = 'bazelrc'
