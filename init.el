;; -*- coding: utf-8; lexical-binding: t; -*-
;; (advice-add #'package-initialize :after #'update-load-path)

;; Without this comment emacs25 adds (package-initialize) here
;; (package-initialize)

(push (expand-file-name "~/.emacs.d/lisp") load-path)

(let* ((minver "24.4"))
  (when (version< emacs-version minver)
    (error "Emacs v%s or higher is required." minver)))

(defvar best-gc-cons-threshold
  4000000
  "Best default gc threshold value.  Should NOT be too big!")

;; don't GC during startup to save time
(setq gc-cons-threshold most-positive-fixnum)

(setq emacs-load-start-time (current-time))

;; {{ emergency security fix
;; https://bugs.debian.org/766397
(eval-after-load "enriched"
  '(defun enriched-decode-display-prop (start end &optional param)
     (list start end)))
;; }}
;;----------------------------------------------------------------------------
;; Which functionality to enable (use t or nil for true and false)
;;----------------------------------------------------------------------------
(setq *is-a-mac* (eq system-type 'darwin))
(setq *win64* (eq system-type 'windows-nt))
(setq *cygwin* (eq system-type 'cygwin) )
(setq *linux* (or (eq system-type 'gnu/linux) (eq system-type 'linux)) )
(setq *unix* (or *linux* (eq system-type 'usg-unix-v) (eq system-type 'berkeley-unix)) )
(setq *emacs24* (>= emacs-major-version 24))
(setq *emacs25* (>= emacs-major-version 25))
(setq *emacs26* (>= emacs-major-version 26))
(setq *no-memory* (cond
                   (*is-a-mac*
                    (< (string-to-number (nth 1 (split-string (shell-command-to-string "sysctl hw.physmem")))) 4000000000))
                   (*linux* nil)
                   (t nil)))

;; @see https://www.reddit.com/r/emacs/comments/55ork0/is_emacs_251_noticeably_slower_than_245_on_windows/
;; Emacs 25 does gc too frequently
(when *emacs25*
  ;; (setq garbage-collection-messages t) ; for debug
  (setq best-gc-cons-threshold (* 64 1024 1024))
  (setq gc-cons-percentage 0.5)
  (run-with-idle-timer 5 t #'garbage-collect))

(defmacro require-init (pkg)
  `(load (file-truename (format "~/.emacs.d/lisp/%s" ,pkg)) t t))

(defmacro local-require (pkg)
  `(unless (featurep ,pkg)
     (load (expand-file-name
             (cond
               ((eq ,pkg 'go-mode-load)
                (format "~/.emacs.d/site-lisp/go-mode/%s" ,pkg))
               (t
                 (format "~/.emacs.d/site-lisp/%s/%s" ,pkg ,pkg))))
           t t)))

;; *Message* buffer should be writable in 24.4+
(defadvice switch-to-buffer (after switch-to-buffer-after-hack activate)
  (if (string= "*Messages*" (buffer-name))
      (read-only-mode -1)))

;; @see https://www.reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start/
;; Normally file-name-handler-alist is set to
;; (("\\`/[^/]*\\'" . tramp-completion-file-name-handler)
;; ("\\`/[^/|:][^/|]*:" . tramp-file-name-handler)
;; ("\\`/:" . file-name-non-special))
;; Which means on every .el and .elc file loaded during start up, it has to runs those regexps against the filename.
(let* ((file-name-handler-alist nil))

  ;; ;; {{
  ;; (require 'benchmark-init-modes)
  ;; (require 'benchmark-init)
  ;; (benchmark-init/activate)
  ;; ;; `benchmark-init/show-durations-tree' to show benchmark result
  ;; ;; }}

  (require-init 'init-autoload)
  ;; `package-initialize' takes 35% of startup time
  ;; need check https://github.com/hlissner/doom-emacs/wiki/FAQ#how-is-dooms-startup-so-fast for solution
  (require-init 'init-modeline)
  (require-init 'init-utils)
  (require-init 'init-elpa)
  (require-init 'init-exec-path) ;; Set up $PATH
  ;; Any file use flyspell should be initialized after init-spelling.el
  (require-init 'init-spelling)
  (require-init 'init-gui-frames)
  (require-init 'init-uniquify)
  (require-init 'init-ibuffer)
  (require-init 'init-ivy)
  (require-init 'init-hippie-expand)
  (require-init 'init-windows)
  (require-init 'init-markdown)
  (require-init 'init-javascript)
  (require-init 'init-org)
  (require-init 'init-css)
  (require-init 'init-python)
  (require-init 'init-ruby-mode)
  (require-init 'init-lisp)
  (require-init 'init-elisp)
  (require-init 'init-yasnippet)
  (require-init 'init-cc-mode)
  (require-init 'init-gud)
  (require-init 'init-linum-mode)
  (require-init 'init-git) ;; git-gutter should be enabled after `display-line-numbers-mode' turned on
  ;; (require-init 'init-gist)
  (require-init 'init-gtags)
  ;; init-evil dependent on init-clipboard
  (require-init 'init-clipboard)
  ;; use evil mode (vi key binding)
  ;;(require-init 'init-evil)
  (require-init 'init-ctags)
  (require-init 'init-bbdb)
  (require-init 'init-gnus)
  (require-init 'init-lua-mode)
  (require-init 'init-workgroups2)
  (require-init 'init-term-mode)
  (require-init 'init-web-mode)
  (require-init 'init-company)
  (require-init 'init-chinese) ;; cannot be idle-required
  ;; need statistics of keyfreq asap
  (require-init 'init-keyfreq)
  (require-init 'init-httpd)

  ;; projectile costs 7% startup time

  ;; misc has some crucial tools I need immediately
  (require-init 'init-misc)

  (require-init 'init-emacs-w3m)
  (require-init 'init-hydra)
  (require-init 'init-shackle)
  (require-init 'init-dired)
  (require-init 'init-writting)

  ;; @see https://github.com/hlissner/doom-emacs/wiki/FAQ
  ;; Adding directories under "site-lisp/" to `load-path' slows
  ;; down all `require' statement. So we do this at the end of startup
  ;; NO ELPA package is dependent on "site-lisp/".
  (setq load-path (cdr load-path))
  (my-add-subdirs-to-load-path "~/.emacs.d/site-lisp/")

  ;; my personal setup, other major-mode specific setup need it.
  ;; It's dependent on "~/.emacs.d/site-lisp/*.el"
  (load (expand-file-name "~/.custom.el") t nil)

  ;; @see https://www.reddit.com/r/emacs/comments/4q4ixw/how_to_forbid_emacs_to_touch_configuration_files/
  ;; See `custom-file' for details.
  (load (setq custom-file (expand-file-name "~/.emacs.d/custom-set-variables.el")) t t))

(setq gc-cons-threshold best-gc-cons-threshold)

(when (require 'time-date nil t)
  (message "Emacs startup time: %d seconds."
           (time-to-seconds (time-since emacs-load-start-time))))

;;; Local Variables:
;;; no-byte-compile: t
;;; End:
(put 'erase-buffer 'disabled nil)

;; 编码设置 begin
(set-language-environment 'Chinese-GB)
;; default-buffer-file-coding-system变量在emacs23.2之后已被废弃，使用buffer-file-coding-system代替
(set-default buffer-file-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)
(setq-default pathname-coding-system 'euc-cn)
(setq file-name-coding-system 'euc-cn)
;; 另外建议按下面的先后顺序来设置中文编码识别方式。
;; 重要提示:写在最后一行的，实际上最优先使用; 最前面一行，反而放到最后才识别。
;; utf-16le-with-signature 相当于 Windows 下的 Unicode 编码，这里也可写成
;; utf-16 (utf-16 实际上还细分为 utf-16le, utf-16be, utf-16le-with-signature等多种)
(prefer-coding-system 'cp950)
(prefer-coding-system 'gb2312)
(prefer-coding-system 'cp936)
(prefer-coding-system 'gb18030)
;(prefer-coding-system 'utf-16le-with-signature)
(prefer-coding-system 'utf-16)
;; 新建文件使用utf-8-unix方式
;; 如果不写下面两句，只写
;; (prefer-coding-system 'utf-8)
;; 这一句的话，新建文件以utf-8编码，行末结束符平台相关
(prefer-coding-system 'utf-8-dos)
(prefer-coding-system 'utf-8-unix)
;; 编码设置 end
