
" This is a sequence of letters which describes how
" automatic formatting is to be done.
"
" letter    meaning when present in 'formatoptions'
" ------    ---------------------------------------
" c         Auto-wrap comments using textwidth, inserting
"           the current comment leader automatically.
" q         Allow formatting of comments with "gq".
" r         Automatically insert the current comment leader
"           after hitting <Enter> in Insert mode. 
" t         Auto-wrap text using textwidth (does not apply
"           to comments)
set formatoptions=c,q,r,t

set ruler	" Display line number/column number
set background=dark

if !has("gui_running")
	:source $VIMRUNTIME/menu.vim
	:set wildmenu
	:set cpo-=<
	:set wcm=<C-Z>
	:map <F4> :emenu <C-Z>
endif

" set paste   " Do not apply formatting to pasted content
" Beware that setting `paste` globally will effectively disables
" `autoindent`!!!


" If you are using a console version of Vim, or dealing
" with a file that changes externally (e.g. a web server log)
" then Vim does not always check to see if the file has been changed.
" The GUI version of Vim will check more often (for example on Focus change),
" and prompt you if you want to reload the file.
"
" There can be cases where you can be working away, and Vim does not
" realize the file has changed. This command will force Vim to check
" more often.
"
" Calling this command sets up autocommands that check to see if the
" current buffer has been modified outside of vim (using checktime)
" and, if it has, reload it for you.
"
" This check is done whenever any of the following events are triggered:
" * BufEnter
" * CursorMoved
" * CursorMovedI
" * CursorHold
" * CursorHoldI
"
" In other words, this check occurs whenever you enter a buffer, move the cursor,
" or just wait without doing anything for 'updatetime' milliseconds.
"
" Normally it will ask you if you want to load the file, even if you haven't made
" any changes in vim. This can get annoying, however, if you frequently need to reload
" the file, so if you would rather have it to reload the buffer *without*
" prompting you, add a bang (!) after the command (WatchForChanges!).
" This will set the autoread option for that buffer in addition to setting up the
" autocommands.
"
" If you want to turn *off* watching for the buffer, just call the command again while
" in the same buffer. Each time you call the command it will toggle between on and off.
"
" WatchForChanges sets autocommands that are triggered while in *any* buffer.
" If you want vim to only check for changes to that buffer while editing the buffer
" that is being watched, use WatchForChangesWhileInThisBuffer instead.
"
command! -bang WatchForChanges                  :call WatchForChanges(@%,  {'toggle': 1, 'autoread': <bang>0})
command! -bang WatchForChangesWhileInThisBuffer :call WatchForChanges(@%,  {'toggle': 1, 'autoread': <bang>0, 'while_in_this_buffer_only': 1})
command! -bang WatchForChangesAllFile           :call WatchForChanges('*', {'toggle': 1, 'autoread': <bang>0})
" WatchForChanges function
"
" This is used by the WatchForChanges* commands, but it can also be
" useful to call this from scripts. For example, if your script executes a
" long-running process, you can have your script run that long-running process
" in the background so that you can continue editing other files, redirects its
" output to a file, and open the file in another buffer that keeps reloading itself
" as more output from the long-running command becomes available.
"
" Arguments:
" * bufname: The name of the buffer/file to watch for changes.
"     Use '*' to watch all files.
" * options (optional): A Dict object with any of the following keys:
"   * autoread: If set to 1, causes autoread option to be turned on for the buffer in
"     addition to setting up the autocommands.
"   * toggle: If set to 1, causes this behavior to toggle between on and off.
"     Mostly useful for mappings and commands. In scripts, you probably want to
"     explicitly enable or disable it.
"   * disable: If set to 1, turns off this behavior (removes the autocommand group).
"   * while_in_this_buffer_only: If set to 0 (default), the events will be triggered no matter which
"     buffer you are editing. (Only the specified buffer will be checked for changes,
"     though, still.) If set to 1, the events will only be triggered while
"     editing the specified buffer.
"   * more_events: If set to 1 (the default), creates autocommands for the events
"     listed above. Set to 0 to not create autocommands for CursorMoved, CursorMovedI,
"     (Presumably, having too much going on for those events could slow things down,
"     since they are triggered so frequently...)
function! WatchForChanges(bufname, ...)
  " Figure out which options are in effect
  if a:bufname == '*'
    let id = 'WatchForChanges'.'AnyBuffer'
    " If you try to do checktime *, you'll get E93: More than one match for * is given
    let bufspec = ''
  else
    if bufnr(a:bufname) == -1
      echoerr "Buffer " . a:bufname . " doesn't exist"
      return
    end
    let id = 'WatchForChanges'.bufnr(a:bufname)
    let bufspec = a:bufname
  end
  if len(a:000) == 0
    let options = {}
  else
    if type(a:1) == type({})
      let options = a:1
    else
      echoerr "Argument must be a Dict"
    end
  end
  let autoread    = has_key(options, 'autoread')    ? options['autoread']    : 0
  let toggle      = has_key(options, 'toggle')      ? options['toggle']      : 0
  let disable     = has_key(options, 'disable')     ? options['disable']     : 0
  let more_events = has_key(options, 'more_events') ? options['more_events'] : 1
  let while_in_this_buffer_only = has_key(options, 'while_in_this_buffer_only') ? options['while_in_this_buffer_only'] : 0
  if while_in_this_buffer_only
    let event_bufspec = a:bufname
  else
    let event_bufspec = '*'
  end
  let reg_saved = @"
  "let autoread_saved = &autoread
  let msg = "\n"
  " Check to see if the autocommand already exists
  redir @"
    silent! exec 'au '.id
  redir END
  let l:defined = (@" !~ 'E216: No such group or event:')
  " If not yet defined...
  if !l:defined
    if l:autoread
      let msg = msg . 'Autoread enabled - '
      if a:bufname == '*'
        set autoread
      else
        setlocal autoread
      end
    end
    silent! exec 'augroup '.id
      if a:bufname != '*'
        "exec "au BufDelete    ".a:bufname . " :silent! au! ".id . " | silent! augroup! ".id
        "exec "au BufDelete    ".a:bufname . " :echomsg 'Removing autocommands for ".id."' | au! ".id . " | augroup! ".id
        exec "au BufDelete    ".a:bufname . " execute 'au! ".id."' | execute 'augroup! ".id."'"
      end
        exec "au BufEnter     ".event_bufspec . " :checktime ".bufspec
        exec "au CursorHold   ".event_bufspec . " :checktime ".bufspec
        exec "au CursorHoldI  ".event_bufspec . " :checktime ".bufspec
      " The following events might slow things down so we provide a way to disable them...
      " vim docs warn:
      "   Careful: Don't do anything that the user does
      "   not expect or that is slow.
      if more_events
        exec "au CursorMoved  ".event_bufspec . " :checktime ".bufspec
        exec "au CursorMovedI ".event_bufspec . " :checktime ".bufspec
      end
    augroup END
    let msg = msg . 'Now watching ' . bufspec . ' for external updates...'
  end
  " If they want to disable it, or it is defined and they want to toggle it,
  if l:disable || (l:toggle && l:defined)
    if l:autoread
      let msg = msg . 'Autoread disabled - '
      if a:bufname == '*'
        set noautoread
      else
        setlocal noautoread
      end
    end
    " Using an autogroup allows us to remove it easily with the following
    " command. If we do not use an autogroup, we cannot remove this
    " single :checktime command
    " augroup! checkforupdates
    silent! exec 'au! '.id
    silent! exec 'augroup! '.id
    let msg = msg . 'No longer watching ' . bufspec . ' for external updates.'
  elseif l:defined
    let msg = msg . 'Already watching ' . bufspec . ' for external updates'
  end
  echo msg
  let @"=reg_saved
endfunction

execute pathogen#infect()

" plug.vim settings block
"
"call plug#begin('~/.vim/plugged')
"Plug 'junegunn/fzf', { 'dir': '~/workspace/dev/go/src/github.com/junegunn/fzf/', 'do': 'yes \| ./install' }
"call plug#end()

" :let loaded_matchparen=1
set noshowmatch

" Mouse scroll with a page shift (in lieu of moving the text cursor)
set mouse=a
" Tab size of 4 spaces, tabs expanded to spaces
set tabstop=4 shiftwidth=4 expandtab

" Define tabulation behavior per file type
" autocmd Filetype python setlocal ts=2 sts=2 sw=2
" autocmd Filetype cucumber setlocal ts=2 sts=2 sw=2

set smarttab
set number	" Show line numbers

set hlsearch	" Highlight all search matches
set incsearch	" Incremental search

" Clear hlsearch results
nmap \q :nohlsearch<CR>

set ignorecase	" Ignore case in searches
set smartcase	" Except when mixing upper and lower case

set cindent
set autoindent	" Use indent from previous line


" Setup colors
highlight Normal guibg=grey90
highlight Cursor guibg=Green guifg=NONE
highlight NonText guibg=grey80
highlight Constant gui=NONE guibg=grey95
highlight Special gui=NONE guibg=grey95

" Set the number of colors to support to 256 (for colorscheme)
if $TERM=="xterm-256color" || $TERM=="screen-256color" || $COLORTERM=="gnome-terminal"
	set t_Co=256
endif

" colorscheme hybrid
colorscheme zenburn

" Start in ~/workspace
" cd ~/workspace

" Quickly switch between various tab size modes to be able to
" adjust to most source code settings
nmap \t :set expandtab tabstop=8 shiftwidth=8 softtabstop=4<CR>
nmap \T :set expandtab tabstop=4 shiftwidth=4 softtabstop=4<CR>
nmap \M :set noexpandtab tabstop=8 softtabstop=4 shiftwidth=4<CR>
nmap \m :set expandtab tabstop=2 shiftwidth=2 softtabstop=2<CR>

" Toggle wrap modes quickly
nmap \w :setlocal wrap!<CR>:setlocal wrap?<CR>

" Toggle line numbers
nmap \l :setlocal number!<CR>

" Toggle paste mode
nmap \o :set paste!<CR>

" Make wrap mode navigation more natural by allowing flowing within broken
" wrapped lines
nmap j gj
nmap k gk

" Return to previously edited buffer
nmap <C-e> :e#<CR>

" Cycle between buffers
nmap <C-n> :bnext<CR>
nmap <C-p> :bprev<CR>

" Search with Ctrlp
set runtimepath^=~/.vim/bundle/ctrlp.vim
nmap ; :CtrlPBuffer<CR>


" Ctrlp settings block
"
let g:ctrlp_working_path_mode = 'rc'
let g:ctrlp_map = '<Leader>t'
let g:ctrlp_match_window_bottom = 0
let g:ctrlp_match_window_reversed = 0
let g:ctrlp_custom_ignore = '\v\~$|\.(o|swp|pyc)$|(^|[/\\])\.(hg|git)($|[/\\])|__init__\.py'
let g:ctrlp_working_path_mode = 0
let g:ctrlp_dotfiles = 0
let g:ctrlp_switch_buffer = 0

" fzf settings block
"
set rtp+=~/workspace/dev/go/src/github.com/junegunn/fzf
" Toggle fzf with \e
:nmap \f :FZF<CR>


" Start NERDTree autmatically on vim's start
autocmd StdinReadPre * let s:std_in=1
" autocmd VimEnter * NERDTree
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Handy mappings for NERDTree
:nmap \e :NERDTreeToggle<CR>
" map \   :NERDTreeToggle<CR>
" map \|  :NERDTreeFind<CR>

map <Leader>nt  :NERDTree %:p:h<CR>

" Always display status line
set laststatus=2

" Map F3 to clear result of search
" set hlsearch!

nnoremap <F3>   :set hlsearch!<CR>

" Enable copy/paste to system clipboard
set clipboard=unnamedplus

" Set font
set guifont=ProggyCleanTT\ 12


" PlantUML-integration
" Language:     PlantUML
" Maintainer:   Aaron C. Meadows &lt; language name at shadowguarddev dot com&gt;
" Last Change:  19-Jun-2012
" Version:      0.1
"
if exists("g:loaded_plantuml_plugin")
    finish
endif
let g:loaded_plantuml_plugin = 1

if !exists("g:plantuml_executable_script")
        let g:plantuml_executable_script='java -jar ~/workspace/dev/plantuml/plantuml.jar'
endif
let s:makecommand=g:plantuml_executable_script." %"

" define a sensible makeprg for plantuml files
autocmd Filetype plantuml let &l:makeprg=s:makecommand
" End-of-PlantUML-integration

" Enable neocomplete (https://github.com/Shougo/neocomplete.vim)
let g:neocomplete#enable_at_startup = 1


filetype plugin indent on

" Close completion suggestion pane after completing
autocmd CompleteDone * pclose

syntax on

" Map syntastic checking on Ctrl-w E
nnoremap <C-w>E :SyntasticCheck<CR> :SyntasticToggleMode<CR>
