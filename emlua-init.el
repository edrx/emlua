;; This file:
;;   http://angg.twu.net/emacs-lua/emlua-init.el.html
;;   http://angg.twu.net/emacs-lua/emlua-init.el
;;           (find-angg "emacs-lua/emlua-init.el")
;; Author: Eduardo Ochs <eduardoochs@gmail.com>
;;
;; (defun e () (interactive) (find-angg "emacs-lua/emlua-init.el"))



;; See: (find-eev "eev-beginner.el" "load-path-hack")

(setq emlua-dir
      (if load-in-progress
	  (file-name-directory load-file-name)
	default-directory))



'("This is a test block:
 (eepitch-shell)
 (eepitch-kill)
 (eepitch-shell)

# (find-fline "~/bigsrc/emacs29/")
# (find-anggfile "emacs-lua/Makefile")

cp -v ~/LUA/lua50init.lua ~/emacs-lua/edrxlib.lua
make clean
make EMACS_DIR=$HOME/bigsrc/emacs29

--")




;;;  _                 _ 
;;; | | ___   __ _  __| |
;;; | |/ _ \ / _` |/ _` |
;;; | | (_) | (_| | (_| |
;;; |_|\___/ \__,_|\__,_|
;;;                      
;; «load-everything»  (to ".load-everything")

(setq emlua-dot-so       "~/emacs-lua/emlua.so")
(setq emlua-dot-el       "~/emacs-lua/emlua.el")
(setq emlua-luainit-file "~/LUA/lua50init.lua")
(setq emlua-edrxrepl-dir "~/emacs-lua/")


(fboundp 'emlua-dostring)

;; Test: (find-estring (emlua-init-lua-0))
;;
(defun emlua-init-0 ()
  (format "
     dofile '%s'
     package.path = '%s?.lua;'..package.path
     require 'edrxrepl'
     REPL = EdrxRepl.new()
     return EdrxRepl, PP
     "
     (ee-expand emlua-luainit-file)
     (ee-expand emlua-edrxrepl-dir)))

;; Test: (emlua-load-all)
;;
(defun emlua-load-all ()
  (list (load emlua-dot-so)
	(emlua-dostring (emlua-init-lua-0))))




;; Local Variables:
;; coding:  utf-8-unix
;; End:
