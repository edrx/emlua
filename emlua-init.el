;; This file:
;;   http://angg.twu.net/emlua/emlua-init.el.html
;;   http://angg.twu.net/emlua/emlua-init.el
;;           (find-angg "emlua/emlua-init.el")
;; https://raw.githubusercontent.com/edrx/emlua/main/emlua-init.el
;;           https://github.com/edrx/emlua/blob/main/emlua-init.el
;; Author: Eduardo Ochs <eduardoochs@gmail.com>
;; Version: 2022mar30
;; License: GPL2
;;
;; See: https://github.com/edrx/emlua



;; Based on: (find-eev "eev-beginner.el" "load-path-hack")
;; Test:     emlua-dir
;;
(setq emlua-dir
      (if load-in-progress
	  (file-name-directory load-file-name)
	default-directory))



;; Tests: (emlua-init-so-0)
;;        (emlua-init-so)
;;
(defun emlua-init-so-0 ()
  (concat emlua-dir "emlua.so"))

(defun emlua-init-so (&optional use-load-instead-of-require)
  (if (fboundp 'emlua-dostring)
      "emlua.so already loaded"
    (if use-load-instead-of-require
	(load (emlua-init-so-0))
      (require 'emlua (emlua-init-so-0)))))



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



;; Test: (emlua-init)
;;
(defun emlua-init (&optional use-load-instead-of-require)
  (list (emlua-init-so       use-load-instead-of-require)
        (emlua-init-dofiles)
        (emlua-init-newrepl)))
        


(provide 'emlua-init)


;; Local Variables:
;; coding:  utf-8-unix
;; End:
