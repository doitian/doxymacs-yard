;;;
;;; doxymacs-yard.el --- Use doxymacs package for yard, a ruby documentation tool.
;;
;; Work based on http://www.emacswiki.org/emacs/doxymacs-yard.el
;;
;; You can use this snippet to create YARD comments in Ruby buffers and
;; highlight them to the extent the YARD tags match with the Doxygen ones.
;; Any files opened in this buffer after a ruby file was loaded will retain
;; the settings, but this is still the least intrusive method I could find.
;; Another solution would be extending doxymacs itself with another style.
;;
;; - Put (require 'doxymacs-yard) in .emacs, or use autoload
;;
;;   (autoload 'doxymacs-yard "doxymacs-yard" nil t)
;;   (autoload 'doxymacs-yard-font-lock "doxymacs-yard" nil t)
;;
;; - Enable doxymacs-mode and font lock for ruby mode:
;;
;;   (add-hook 'ruby-mode-hook 'doxymacs-yard)
;;   (add-hook 'ruby-mode-hook 'doxymacs-yard-font-lock)
;;

(defun doxymacs-yard--make-keywords-regexp(&rest keywords)
  (concat
   "\\([@\\\\]\\(?:"
   (mapconcat 'identity keywords "\\|")
   "\\)\\)\\>"))

(defun doxymacs-yard--concat-regexp-with-whitespace(&rest regexps)
  (mapconcat 'identity regexps "\\s-+"))

(defun doxymacs-yard--concat-optional-regexp-with-whitespace(first &rest regexps)
  (concat
   first
   (mapconcat
    (lambda (r)
      (concat "\\(?:\\s-+" r "\\)?"))
    regexps "")))

(defconst doxymacs-yard--variable-type-regexp "\\(\\[[^]]+\\]\\)")
(defconst doxymacs-yard--variable-name-regexp "\\(\\sw+\\)")

(defconst doxymacs-yard-keywords
  (list
   (list
    ;; One shot keywords that take no arguments
    (doxymacs-yard--make-keywords-regexp
     "abstract"
     "api"
     "author"
     "deprecated"
     "example"
     "note"
     "private"
     "scope"
     "see"
     "since"
     "todo"
     "version"
     "visibility")
    '(0 font-lock-keyword-face prepend))
   (list
    ;; Keywords that take variable type and name as arguments
    (doxymacs-yard--concat-optional-regexp-with-whitespace
     (doxymacs-yard--make-keywords-regexp
      "attr\\(?:_reader\\|_wirter\\|ibute\\)?"
      "macro"
      "param"
      "yieldparam")
     doxymacs-yard--variable-type-regexp
     doxymacs-yard--variable-name-regexp)
    '(1 font-lock-keyword-face prepend)
    '(2 font-lock-type-face prepend t)
    '(3 font-lock-variable-name-face prepend t))
   (list
    ;; Keywords that take function as argument
    (doxymacs-yard--concat-optional-regexp-with-whitespace
     (doxymacs-yard--make-keywords-regexp
      "method"
      "overload")
     "\\(\sw+\\)")
    '(1 font-lock-keyword-face prepend)
    '(2 font-lock-function-name-face prepend t))
   (list
    ;; Keywords that take variable name, then type and then variable name as arguments
    (doxymacs-yard--concat-optional-regexp-with-whitespace
     (doxymacs-yard--make-keywords-regexp "option")
     doxymacs-yard--variable-name-regexp
     doxymacs-yard--variable-type-regexp
     doxymacs-yard--variable-name-regexp)
    '(1 font-lock-keyword-face prepend)
    '(2 font-lock-variable-name-face prepend t)
    '(3 font-lock-type-face prepend t)
    '(4 font-lock-variable-name-face prepend t))
   (list
    ;; Keywords that take optional variable type
    (doxymacs-yard--concat-optional-regexp-with-whitespace
     (doxymacs-yard--make-keywords-regexp
      "raise"
      "return"
      "yieldreturn"
      )
     doxymacs-yard--variable-type-regexp)
    '(1 font-lock-keyword-face prepend)
    '(2 font-lock-type-face prepend t))
   (list
    ;; Keywords that take list of variable names
    (doxymacs-yard--concat-optional-regexp-with-whitespace
     (doxymacs-yard--make-keywords-regexp "yield")
     doxymacs-yard--variable-type-regexp)
    '(1 font-lock-keyword-face prepend)
    '(2 font-lock-variable-name-face prepend t))))

;;;###autoload
(defun doxymacs-yard-font-lock()
  "Turn on font-lock for yard tags"
  (interactive)
  (let ((doxymacs-doxygen-keywords doxymacs-yard-keywords))
    (doxymacs-font-lock)))

;;;###autoload
(defun doxymacs-yard ()
  (interactive)
  (doxymacs-mode)

  ;; The templates
  (set (make-local-variable 'doxymacs-file-comment-template)
       '(
         "#" > n
         "# " (doxymacs-doxygen-command-char) "file   "
         (if (buffer-file-name)
             (file-name-nondirectory (buffer-file-name))
           "") > n
           "# " (doxymacs-doxygen-command-char) "author " (user-full-name)
           (doxymacs-user-mail-address)
           > n
           "# " (doxymacs-doxygen-command-char) "date   " (current-time-string) > n
           "# " > n
           "# " (doxymacs-doxygen-command-char) "brief  " (p "Brief description of this file: ") > n
           "# " > n
           "# " p > n
           "#" > n
           ))

  (set (make-local-variable 'doxymacs-blank-multiline-comment-templave)
       '("#" > n "# " p > n "#" > n))
  (set (make-local-variable 'doxymacs-blank-singleline-comment-template)
       '("# " > p))

  (set (make-local-variable 'doxymacs-function-comment-template)
       '((let ((next-func (doxymacs-find-next-func)))
           (if next-func
               (list
                'l
                "# " 'p '> 'n
                "#" '> 'n
                (doxymacs-parm-tempo-element (cdr (assoc 'args next-func)))
                (unless (string-match
                         (regexp-quote (cdr (assoc 'return next-func)))
                         doxymacs-void-types)
                  '(l "#" > n "# " (doxymacs-doxygen-command-char)
                      "return " (p "Returns: ") > n))
                "#" '>)
             (progn
               (error "Can't find next function declaraton.")
               nil)))))

  (make-variable-buffer-local 'doxymacs-parm-tempo-element)
  (defun doxymacs-parm-tempo-element (parms)
    (if parms
        (let ((prompt (concat "Parameter " (car parms) ": ")))
          (list 'l "# " (doxymacs-doxygen-command-char)
                "param [mixed] " (car parms) " " (list 'p prompt) '> 'n
                (doxymacs-parm-tempo-element (cdr parms))))
      nil))

  (set (make-local-variable 'doxymacs-member-comment-start) '("#< "))
  (set (make-local-variable 'doxymacs-member-comment-end) '(""))

  (set (make-local-variable 'doxymacs-group-comment-start) '("# @{"))
  (set (make-local-variable 'doxymacs-group-comment-end) '("# @}")))

(provide 'doxymacs-yard)