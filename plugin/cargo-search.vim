"=============================================================================
" Description: Perform a search using the command-line tool cargo search and 
" display the results in a scratch buffer.
" File: cargo_search.vim
" Author: Vanessa McHale <tmchale@wisc.edu>
" Version: 0.1.0.0
if exists('g:__CARGO_SEARCH_VIM__')
    finish
endif
let g:__CARGO_SEARCH_VIM__ = 1

if !exists('g:cargo_search_num')
    let g:cargo_search_num = 8
endif

if !exists('g:cargo_search_use_color')
    let g:cargo_search_use_color = 0
    ' TODO detect AnsiEsc plugin
endif

if !exists('g:cargo_search_options')
    let g:cargo_search_options = ''
endif

let g:cargo_search_buf_name = 'CargoSearch'

if !exists('g:cargo_search_buf_size')
    let g:cargo_search_buf_size = 8
endif

" Mark a buffer as scratch
function! s:ScratchMarkBuffer()
    setlocal buftype=nofile
    " make sure buffer is deleted when view is closed
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal buflisted
    setlocal nonumber
    setlocal statusline=%F
    setlocal nofoldenable
    setlocal foldcolumn=0
    setlocal wrap
    setlocal linebreak
    setlocal nolist
endfunction

" Return the number of visual lines in the buffer
fun! s:CountVisualLines()
    let initcursor = getpos('.')
    call cursor(1,1)
    let i = 0
    let previouspos = [-1,-1,-1,-1]
    " keep moving cursor down one visual line until it stops moving position
    while previouspos != getpos('.')
        let i += 1
        " store current cursor position BEFORE moving cursor
        let previouspos = getpos('.')
        normal! gj
    endwhile
    " restore cursor position
    call setpos('.', initcursor)
    return i
endfunction

" return -1 if no windows was open
"        >= 0 if cursor is now in the window
fun! s:CargoSearchGotoWin() "{{{
    let bufnum = bufnr( g:cargo_search_buf_name )
    if bufnum >= 0
        let win_num = bufwinnr( bufnum )
        " Will return negative for already deleted window
        exe win_num . 'wincmd w'
        return 0
    endif
    return -1
endfunction "}}}

" Close cargo_search Buffer
fun! CargoSearchClose() "{{{
    let last_buffer = bufnr('%')
    if s:CargoSearchGotoWin() >= 0
        close
    endif
    let win_num = bufwinnr( last_buffer )
    " Will return negative for already deleted window
    exe win_num . 'wincmd w'
endfunction "}}}

" Open a scratch buffer or reuse the previous one
fun! CargoSearchFn(...) "{{{
    let last_buffer = bufnr('%')

    if s:CargoSearchGotoWin() < 0
        new
        exe 'file ' . g:cargo_search_buf_name
        setl modifiable
    else
        setl modifiable
        exec 'normal! ggVGd'
    endif

    call s:ScratchMarkBuffer()

    if strlen(a:000) == 0
        let s:pkg = join(expand("<cword>"), ' ')
    else
        let s:pkg = join(a:000,' ')
    endif

    " TODO check whether vim uses color by presence of
    if g:cargo_search_use_color == 0
        execute '.!cargo search --color never --limit ' . g:cargo_search_num . ' '  . s:pkg . ' ' . g:cargo_search_options
    else
        execute '.!cargo search --limit ' . g:cargo_search_num . ' '  . s:pkg . ' ' . g:cargo_search_options
    endif

    setl nomodifiable
    
    let size = s:CountVisualLines()

    if size > g:cargo_search_buf_size
        let size = g:cargo_search_buf_size
    endif

    execute 'resize ' . size

    nnoremap <silent> <buffer> q <esc>:close<cr>

endfunction "}}}

command! -nargs=* CargoSearch call CargoSearchFn(<f-args>)
