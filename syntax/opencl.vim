if exists('b:current_syntax') | finish | endif
runtime! syntax/c.vim
syn keyword openclQualifier __kernel __global __local __constant __private __read_only __write_only
hi def link openclQualifier StorageClass
let b:current_syntax = 'opencl'
