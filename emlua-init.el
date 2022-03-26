;; This file:
;;   http://angg.twu.net/emacs-lua/emlua-init.el.html
;;   http://angg.twu.net/emacs-lua/emlua-init.el
;;           (find-angg "emacs-lua/emlua-init.el")
;; Author: Eduardo Ochs <eduardoochs@gmail.com>
;;
;; (defun e () (interactive) (find-angg "emacs-lua/emlua-init.el"))



;; Based on:
;; (find-eev "eev-beginner.el" "load-path-hack")
(setq emlua-dir
      (if load-in-progress
	  (file-name-directory load-file-name)
	default-directory))

(defun emlua-init-0 ()
  (load (concat emlua-dir "emlua.so"))) 

(defun emlua-init-1 ()
  (if (not (fboundp 'emlua-dostring))
      (emlua-init-0)
    "Already loaded"))

(defun emlua-init-2 ()
  (ee-template0 "\
     loadstring = loadstring or load
     dofile '{emlua-dir}edrxlib.lua'
     dofile '{emlua-dir}Repl1.lua'
     -- package.path = '{emlua-dir}?.lua;'..package.path
     REPL = EdrxEmacsRepl.new()
     return 'REPL =', REPL"))

(defun emlua-init-3 ()
  (emlua-init-1)
  (emlua-dostring (emlua-init-2)))

(defun emlua-init ()
  (emlua-init-3))


;; Tests:
;; emlua-dir
;; (emlua-init-0)
;; (emlua-init-1)
;; (emlua-init-2)
;; (emlua-init-3)
;; (emlua-init)


(provide 'emlua-init)


;; Local Variables:
;; coding:  utf-8-unix
;; End:
