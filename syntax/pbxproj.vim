if exists('b:current_syntax') | finish | endif
syn region pbxprojComment start=/\/\*/ end=/\*\//
syn match pbxprojLineComment /\/\/.*$/
syn region pbxprojString start=/"/ skip=/\\"/ end=/"/
syn match pbxprojKey /[a-zA-Z0-9_]*\ze\s*=/
hi def link pbxprojComment Comment
hi def link pbxprojLineComment Comment
hi def link pbxprojString String
hi def link pbxprojKey Identifier
let b:current_syntax = 'pbxproj'
