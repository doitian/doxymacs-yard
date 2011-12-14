This is based on [Jonas](http://www.emacswiki.org/emacs/JonasBernoulli)'s
[doxymacs-yard.el](http://www.emacswiki.org/emacs/doxymacs-yard.el), where I
just added the font lock for yard tags.


Download `doxymacs-yard.el` and put it in your `load-path`.

- Enable `doxymacs-mode` (with shortcuts to create documentation for function
  and etc.)
  
      (add-hook 'ruby-mode-hook 'doxymacs-yard)
      
- Enable `font-lock` for tags

      (add-hook 'ruby-mode-hook 'doxymacs-yard-font-lock)


See font-lock screen shot below

![doxymacs yard screenshot](http://img806.imageshack.us/img806/1953/selection2011121401.png)