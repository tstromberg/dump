" General settings. ---------------------------------------------------------->
set autochdir            " set working directory to match the current file
set backup
set backupdir=~/.vim/backup
set expandtab            " To insert space characters whenever <tab> is pressed
set hidden
set history=200          " Store last 200 commands as history.
set hlsearch             " Highlight previous search results
set incsearch            " Incremental search
set laststatus=2         " enable the status bar
set list                 " highlight whitespace
set listchars=tab:>.,trail:.,extends:#,nbsp:.
set nocompatible              " be iMproved, required
set pastetoggle=<F2>     " hit this on insert when pasting code in
set ruler                " show the line number on the bar
set shiftwidth=2         " number of space characters inserted for indentation
set showcmd              " Show (partial) command in status line.
set showmatch            " Show matching brackets.
set showmode
"set smartindent
set softtabstop=2        " How many spaces to insert if you hit tab.
set tabstop=2            " Viewing a real tab uses two columns.
set undolevels=200
set wildmenu wildmode=longest:full

syntax on

" Vundle " ------------------------------------------------------------------->
" https://github.com/gmarik/Vundle.vim
filetype off                  " required
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'
" Other Plugins go here.
Plugin 'fatih/vim-go'
Plugin 'kien/ctrlp.vim'
Plugin 'majutsushi/tagbar'
Plugin 'scrooloose/syntastic'
call vundle#end()            " required
filetype plugin indent on    " required

" Plugin settings ------------------------------------------------------------>
" By default, CtrlP uses globpath() to build its index. You can dramatically speed up indexing by using https://github.com/ggreer/the_silver_searcher instead.

let g:ctrlp_user_command = 'ag %s -i --nocolor --nogroup --hidden
      \ --ignore .git
      \ --ignore .svn
      \ --ignore .hg
      \ --ignore .DS_Store
      \ --ignore "**/*.pyc"
      \ --ignore .git5_specs
      \ --ignore review
      \ -g ""'


" Key/Command mappings ------------------------------------------------------->
nnoremap ; :                          " save precious keystrokes
cmap w!! w !sudo tee % >/dev/null     " double exclamations to use sudo
let mapleader=','

" By default all window-related commands are under <C-w>, but these allow switching windows with <C-{hjkl}>
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-h> <C-w>h
nmap <C-l> <C-w>l

" Show a tagbar if F8 is hit.
nmap <F8> :TagbarToggle<CR>

" UI ------------------------------------------------------------------------->
set background=dark
set guifont=Inconsolata
colorscheme pablo
set t_Co=256

" hate whitespace: http://vim.wikia.com/wiki/Highlight_unwanted_spaces
highlight default link TrailingWhitespace Error
augroup filetypedetect
  autocmd WinEnter,BufNewFile,BufRead * match TrailingWhitespace /\s\+$/
augroup END
autocmd InsertEnter * match none
autocmd InsertLeave * match TrailingWhitespace /\s\+$/

" Highlight long lines in certain languages...
au BufWinEnter,WinEnter *.cc,*.h,*.py,*.sh if !exists("w:warning_match_id") | let w:warning_match_id = matchadd('WarningMsg', '\%>80v.\+', -1) | endif

" Don't hide useful syntax highlighting when editing JSON.
let g:vim_json_syntax_conceal = 0


" Pre/Post-Write Bindings ---------------------------------------------------->
" auto-reload changes to .vimrc
au! BufWritePost .vimrc source %

" automatically strip trailing whitespace
autocmd BufWritePost *.php :%s/\s\+$//e
autocmd BufWritePost *.rules :%s/\s\+$//e
autocmd BufWritePost *.rb :%s/\s\+$//e
autocmd BufWritePost BUILD :%s/\s\+$//e
autocmd BufWritePost *.py :%s/\s\+$//e
autocmd BufWritePost *.sh :%s/\s\+$//e
autocmd BufWritePost *.yml :%s/\s\+$//e
autocmd BufWritePost *.yaml :%s/\s\+$//e
autocmd BufWritePost *.gcl :%s/\s\+$//e

let g:go_fmt_command = "goimports"

" Type-specific overrides ---------------------------------------------------->
" For go, <tab>'s are great.
autocmd FileType go setlocal noexpandtab nolist shiftwidth=4 tabstop=4 softtabstop=4

" Import local settings ------------------------------------------------------>
if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif


