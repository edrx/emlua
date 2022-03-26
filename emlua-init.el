;; This file:
;;   http://angg.twu.net/emacs-lua/emlua-init.el.html
;;   http://angg.twu.net/emacs-lua/emlua-init.el
;;           (find-angg "emacs-lua/emlua-init.el")
;; https://raw.githubusercontent.com/edrx/emlua/main/emlua-init.el
;;           https://github.com/edrx/emlua/blob/main/emlua-init.el
;; Author: Eduardo Ochs <eduardoochs@gmail.com>
;; Version: 2022mar26
;; License: GPL2
;;
;; See: https://github.com/edrx/emlua



;; Based on:
;; (find-eev "eev-beginner.el" "load-path-hack")
(setq emlua-dir
      (if load-in-progress
	  (file-name-directory load-file-name)
	default-directory))



;; Tests: (emlua-init-so-0)
;;        (emlua-init-so)
;;
(defun emlua-init-so-0 ()
  (concat emlua-dir "emlua.so"))

(defun emlua-init-so ()
  (if (not (fboundp 'emlua-dostring))
      (load (emlua-init-so-0))
    "emlua.so already loaded"))



;; Tests: (emlua-init-dofiles-0)
;;        (emlua-init-dofiles)
;;
(defun emlua-init-dofiles-0 ()
  (ee-template0 "\
     dofile '{emlua-dir}edrxlib.lua'
     dofile '{emlua-dir}Repl1.lua'
     -- package.path = '{emlua-dir}?.lua;'..package.path
     return 'EdrxEmacsRepl =', EdrxEmacsRepl"))

(defun emlua-init-dofiles ()
  (emlua-dostring (emlua-init-dofiles-0)))



;; Tests: (emlua-init-newrepl-0)
;;        (emlua-init-newrepl)
;;
(defun emlua-init-newrepl-0 ()
  "REPL = EdrxEmacsRepl.new()
   return 'REPL =', REPL")

(defun emlua-init-newrepl ()
  (emlua-dostring (emlua-init-newrepl-0)))




(provide 'emlua-init)


;; Local Variables:
;; coding:  utf-8-unix
;; End:
