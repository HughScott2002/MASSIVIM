if exists('b:current_syntax') | finish | endif
syn match fluentComment /^\s*#.*$/
syn match fluentIdentifier /^[-a-zA-Z][a-zA-Z0-9_-]*\s*=/
syn match fluentVariable /\$[a-zA-Z][a-zA-Z0-9_-]*/
syn region fluentPlaceable start=/{/ end=/}/ contains=fluentVariable
hi def link fluentComment Comment
hi def link fluentIdentifier Identifier
hi def link fluentVariable Identifier
hi def link fluentPlaceable Special
let b:current_syntax = 'fluent'
