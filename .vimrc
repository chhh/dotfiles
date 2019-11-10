" this helped me to get right-mouse-click to work as paste
set mouse=r


" settings for vim
syntax on
set ruler
set background=dark

" completion in command line
set wildmode=longest,list,full
set wildmenu

" easier buffer switching
nnoremap <F5> :buffers<CR>:buffer<Space>


set wrap

" Tabs are 2 characters
set tabstop=4

" (Auto)indent uses 2 characters
set shiftwidth=4

" spaces instead of tabs
set expandtab

" guess indentation
set autoindent

" Expand the command line using tab
set wildchar=<Tab>

" show line numbers
set number

" Fold using markers {{{
" like this
" }}}
set foldmethod=marker

" enable all features
set nocompatible

" powerful backspaces
set backspace=indent,eol,start

" highlight the searchterms
set hlsearch

" ignore case while searching
set ignorecase

" don't wrap words
set textwidth=0

" history
set history=50

" 1000 undo levels
set undolevels=1000

" show a ruler
set ruler

" show partial commands
set showcmd

" show matching braces
set showmatch

" allows hidden buffers to stay unsaved, but we do not want this, so comment
" it out:
" "set hidden

"set wmh=0

" auto-detect the filetype
filetype plugin indent on

" syntax highlight
syntax on

" Always show the menu, insert longest match
set completeopt=menuone,longest

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
autocmd BufReadPost *
  \ if line("'\"") > 0 && line("'\"") <= line("$") |
  \   exe "normal g`\"" |
  \ endif
