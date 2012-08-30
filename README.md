Maple's vim config
==================
I use `vundle` to manage my plugins, which makes my `.vim` directory clean
and tidy. If you are new to vim, these two posts

* [Vim Introduction and Tutorial](http://blog.interlinked.org/tutorials/vim_tutorial.html)
* [Vim plugins I use](http://mirnazim.org/writings/vim-plugins-i-use/) 

will be good for you.

## Code Completion
* [supertab](http://github.com/ervandew/supertab) -  Perform all your vim insert mode completions with Tab.
* [neocomplcache](http://github.com/Shougo/neocomplcache) - Ultimate auto completion system for Vim 
* [zencoding](http://github.com/mattn/zencoding-vim) - High speed HTML and CSS coding.

### Shortcuts
* `Tab`        -> Select from the completion list
* `Ctrl` + `j` -> Call zen-coding expansion on html tags
* `Ctrl` + `k` -> Expand snippets
* `Ctrl` + `l` -> Jump to the next place holder for snippets

### Dependencies
Compile vim with `--enable-pythoninterp` and `--enable-rubyinterp` to enable powerful syntax completion supplied by neocomplcache


### Tutorial
``` vim
:help zencoding
```

### Screenshots
![Completions](https://github.com/humiaozuzu/dot-vimrc/raw/master/screenshots/completions.gif)
![Snippets](https://github.com/humiaozuzu/dot-vimrc/raw/master/screenshots/snippets.gif)

## Surrounding Operation
* [delimitMate](http://github.com/Raimondi/delimitMate) - Provides auto-balancing and some expansions for parens, quotes, etc.
* [matchit](http://github.com/tsaleh/vim-matchit) - Extended % matching for HTML, LaTeX, and many other languages.
* [surround](http://github.com/tpope/vim-surround) - Easily delete, change and add such surroundings in pairs.

### Tutorial
``` vim
:help text-objexts
:help surround
```

### Shortcuts
* `%` -> Jump between brackets and html/xml tags

## Code Reading
* [nerdtree](http://github.com/scrooloose/nerdtree) - A tree explorer plugin for navigating the filesystem.
* [nerdcommenter](http://github.com/scrooloose/nerdcommenter) - Easy commenting of code for many filetypes. 
* [tagbar](http://github.com/majutsushi/tagbar) - Displays the tags of the current file in a sidebar
* [tabbar](http://github.com/humiaozuzu/TabBar) -  Add tab bar and quickt tab switch with alt+1~9
* [ack-vim](http://github.com/mileszs/ack.vim) - Front for the Perl module App::Ack.
* [ctrlp](https://github.com/kien/ctrlp.vim) - Fuzzy file, buffer, mru and tag finder 
* [tabular](https://github.com/godlygeek/tabular) - Vim script for text filtering and alignment

### Dependencie
```bash
yaourt -S ack ctags                  # ArchLinux
sudo apt-get install ack-grep ctags  # Ubuntu
brew install ack ctags               # OSX
```

### Tutorial
* [Code Reading with Vim(to be finished)](http://lovemaple.info/blog/2011/12/effective-vim-part1-code-reading-with-vim/)

### Shortcuts
* `F5` -> Toggle Nerd-Tree file viewer
* `F6` -> Toggle tagbar
* `Ctrl` + `p` -> Toggle ctrlp
* `Alt` + `1~9` -> Switch between multiple buffers
* `Ctrl` + `h/j/k/l` -> Moving between spilt windows
* `:Ack` -> Toggle Ack searching

## Other Utils
* [powerline](https://github.com/Lokaltog/vim-powerline) - The ultimate vim statusline utility
* [fcitx-status](https://github.com/humiaozuzu/fcitx-status) - automatic change status of fcitx in vim
* [fugitive](https://github.com/tpope/vim-fugitive/) - a Git wrapper so awesome, it should be illegal
* [gundo](https://github.com/sjl/gundo.vim/) - visualize your Vim undo tree
* [mru](https://github.com/vim-scripts/mru.vim/) - Plugin to manage Most Recently Used (MRU) files
* [syntastic](https://github.com/scrooloose/syntastic) - Syntax checking hacks for vim
* [togglemouse](https://github.com/nvie/vim-togglemouse/) - Toggles the mouse focus between Vim and your terminal emulator, allowing terminal emulator mouse commands, like copy/paste

### Screenshots
![powerline](https://github.com/humiaozuzu/dot-vimrc/raw/master/screenshots/powerline.png)

## Better syntax/indent for language enhancement 
* [markdown](http://github.com/tpope/vim-markdown) -  Syntax highlight for Markdown text files
* [jquery](http://github.com/nono/jquery.vim) - Syntax file for jQuery in ViM
* [javascript](http://github.com/pangloss/vim-javascript) - Vastly improved vim's javascript indentation
* [coffee-script](https://github.com/kchmck/vim-coffee-script) - CoffeeScript support for vim
* [html5](https://github.com/othree/html5.vim) - HTML5 omnicomplete and syntax
* [haml](https://github.com/tpope/vim-haml) - Vim runtime files for Haml, Sass, and SCSS

## Themes
* [blackboard](https://github.com/rickharris/vim-blackboard) - Textmate's Blackboard theme for vim (with iTerm2 theme)
* [molokai](https://github.com/rickharris/vim-monokai) - A port of the monokai scheme for TextMate
* [solarized](https://github.com/altercation/vim-colors-solarized) - precision colorscheme for the vim text editor
* [vividchalk](https://github.com/tpope/vim-vividchalk) - colorscheme based on the Vibrant Ink theme for TextMate

# Installation
1. backup your old vim configuration file:

        mv ~/.vim ~/.vim.orig
        mv ~/.vimrc ~/.vimrc.orig

2. Clone and install this repo:

        git clone git://github.com/humiaozuzu/dot-vimrc.git ~/.vim
        ln -s ~/.vim/vimrc ~/.vimrc 
        
3. Setup `Vundle`:

		git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle

4. Install bundles. Launch vim(Ignore the errors and they will disappear after installing needed plugins) and run:
		
		:BundleInstall

Thst's it!