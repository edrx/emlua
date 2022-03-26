;; This file:
;;   http://angg.twu.net/emlua/emlua-repl.el.html
;;   http://angg.twu.net/emlua/emlua-repl.el
;;           (find-angg "emlua/emlua-repl.el")
;; Author: Eduardo Ochs <eduardoochs@gmail.com>
;; Version: 2022mar26
;; Status: seems to work but needs more tests and comments
;;
;; (defun e () (interactive) (find-angg "emlua/emlua-repl.el"))

;; «.faces»			(to "faces")
;; «.eepitch-emlua-insert»	(to "eepitch-emlua-insert")

;; (add-to-list 'load-path "~/emlua/")
;; (load (buffer-file-name))
;; (emlua-init)

(require 'eepitch)
(require 'emlua-data)
(require 'emlua-init)





;;;  _____                   
;;; |  ___|_ _  ___ ___  ___ 
;;; | |_ / _` |/ __/ _ \/ __|
;;; |  _| (_| | (_|  __/\__ \
;;; |_|  \__,_|\___\___||___/
;;;                          
;; «faces»  (to ".faces")
;;
(defface emlua-prompt-face
  '((t (:foreground "RoyalBlue3")))
  "")

(defface emlua-user-input-face
  '((t (:foreground "orange1")))
  "")

(defface emlua-output-face
  '((t (:foreground "bisque")))
  "")

(defface emlua-error-face
  '((t (:foreground "red")))
  "")




;;;   __ _           _       _            __  __           
;;;  / _(_)_ __   __| |     | |__  _   _ / _|/ _| ___ _ __ 
;;; | |_| | '_ \ / _` |_____| '_ \| | | | |_| |_ / _ \ '__|
;;; |  _| | | | | (_| |_____| |_) | |_| |  _|  _|  __/ |   
;;; |_| |_|_| |_|\__,_|     |_.__/ \__,_|_| |_|  \___|_|   
;;;                                                        
;; Tests: (eepitch-emlua-insert-prepare)
;;        (eepitch-emlua-insert-user-input "foo")
;;        (eepitch-emlua-insert-output "bar plic\n")
;;        (eepitch-emlua-insert-prompt ">-> ")

(defun eepitch-emlua-buffer ()
  (get-buffer "*emlua*"))

(defun eepitch-emlua-initial-prompt ()
  (propertize "Emlua:\n>>> " 'face 'emlua-prompt-face))

(defun eepitch-emlua-find-buffer ()
  "Like `(find-ebuffer \"*emlua*\")', but also initializes the
buffer if it does not exist."
  (if (eepitch-emlua-buffer)
      (find-ebuffer "*emlua*")
    (find-ebuffer "*emlua*")
    (insert (eepitch-emlua-initial-prompt))))




;;;                       
;;;  _ __  _ __ ___ _ __  
;;; | '_ \| '__/ _ \ '_ \ 
;;; | |_) | | |  __/ |_) |
;;; | .__/|_|  \___| .__/ 
;;; |_|            |_|    

(defun eepitch-emlua-window ()
  (get-buffer-window "*emlua*"))

(defun eepitch-emlua-prep-b ()
  "Prepare eepitch-emlua - buffer-only version"
  (eepitch-emlua-find-buffer))

(defun eepitch-emlua-prep-bw ()
  "Prepare eepitch-emlua - buffer+window version"
  (if (eepitch-emlua-window)
      "Everything ready"
    (find-2a nil '(eepitch-emlua-find-buffer))))

;; Choose one:
(defalias 'eepitch-emlua-prep 'eepitch-emlua-prep-b)
(defalias 'eepitch-emlua-prep 'eepitch-emlua-prep-bw)



;;;  _                     _   
;;; (_)_ __  ___  ___ _ __| |_ 
;;; | | '_ \/ __|/ _ \ '__| __|
;;; | | | | \__ \  __/ |  | |_ 
;;; |_|_| |_|___/\___|_|   \__|
;;;                            

(defun eepitch-emlua-insert-b (str &optional face)
  "Insert STR at the end of the emlua buffer - buffer-only version"
  (eepitch-emlua-prep-b)
  (goto-char (point-max))
  (insert (propertize str 'face face)))

(defun eepitch-emlua-insert-bw (str &optional face)
  "Insert STR at the end of the emlua buffer - buffer+window version"
  (eepitch-emlua-prep-bw)
  (eepitch-emlua-insert-b str face))

;; Choose one:
(defalias 'eepitch-emlua-insert 'eepitch-emlua-insert-b)
(defalias 'eepitch-emlua-insert 'eepitch-emlua-insert-bw)

(defun eepitch-emlua-insert-prompt (prompt)
  (eepitch-emlua-insert prompt 'emlua-prompt-face))

(defun eepitch-emlua-insert-user-input (line)
  (eepitch-emlua-insert (concat line "\n") 'emlua-user-input-face))

(defun eepitch-emlua-insert-output (output)
  (eepitch-emlua-insert output 'emlua-output-face))

(defun eepitch-emlua-insert-error (err)
  (eepitch-emlua-insert err 'emlua-error-face))





;;;                           _ 
;;;   ___  ___  ___ _ __   __| |
;;;  / _ \/ __|/ _ \ '_ \ / _` |
;;; |  __/\__ \  __/ | | | (_| |
;;;  \___||___/\___|_| |_|\__,_|
;;;                             

(defvar eepitch-emlua-out nil
  "The results of the last call to `eepitch-emlua-esend0'.")

(defun eepitch-emlua-esend0 (line)
  "Run REPL:esend(LINE) and save the results in `eepitch-emlua-out'."
  (setq eepitch-emlua-out
	(emlua-dostring
	 (emlua-format "return REPL:esend(%s)" line))))

(defun eepitch-emlua-esend1 ()
  "Insert the contents of `eepitch-emlua-out' in the right way."
  (if (stringp eepitch-emlua-out)
      (eepitch-emlua-insert-error (concat eepitch-emlua-out "\n"))
    (if (< 0 (length eepitch-emlua-out))
	(eepitch-emlua-insert-output (aref eepitch-emlua-out 0))
      "eepitch-emlua-out is []: do nothing")))

(defun eepitch-emlua-eprompt ()
  "Insert the result of REPL:eprompt() at the end of the *emlua* buffer."
  (eepitch-emlua-insert-prompt
   (aref (emlua-dostring "return REPL:eprompt()") 0)))

(defun eepitch-emlua-esend (line)
  (eepitch-eval-at-target-window
   '(progn
      (eepitch-emlua-prep-b)
      (eepitch-emlua-insert-user-input line)
      (eepitch-emlua-esend0 line)
      (eepitch-emlua-esend1)
      (eepitch-emlua-eprompt))))


;;;   __       _                            _ 
;;;  / _| __ _| | _____  ___  ___ _ __   __| |
;;; | |_ / _` | |/ / _ \/ __|/ _ \ '_ \ / _` |
;;; |  _| (_| |   <  __/\__ \  __/ | | | (_| |
;;; |_|  \__,_|_|\_\___||___/\___|_| |_|\__,_|
;;;                                           

(defun eepitch-emlua-fakesend (line)
  (eepitch-eval-at-target-window
   '(progn
      ;; (save-excursion (eepitch-emlua-prep-b))
      (eepitch-emlua-prep-b)
      (eepitch-emlua-insert-user-input line)
      (eepitch-emlua-insert-output "(Using fakesend)\n")
      (eepitch-emlua-insert-prompt ">>> "))))





;;;                  _ _       _                          _             
;;;   ___  ___ _ __ (_) |_ ___| |__         ___ _ __ ___ | |_   _  __ _ 
;;;  / _ \/ _ \ '_ \| | __/ __| '_ \ _____ / _ \ '_ ` _ \| | | | |/ _` |
;;; |  __/  __/ |_) | | || (__| | | |_____|  __/ | | | | | | |_| | (_| |
;;;  \___|\___| .__/|_|\__\___|_| |_|      \___|_| |_| |_|_|\__,_|\__,_|
;;;           |_|                                                       

(defun eepitch-emlua ()
  "Setup eepitch-ing to an emlua buffer.
This function is a prototype that only works in a controlled setting."
  (interactive)
  (defalias 'eepitch-emlua-prep   'eepitch-emlua-prep-b)
  (defalias 'eepitch-emlua-insert 'eepitch-emlua-insert-b)
  (eepitch '(eepitch-emlua-find-buffer))
  (setq eepitch-line 'eepitch-emlua-esend)
  )







'("This is a test block:
 (eepitch-emlua)
 (eepitch-kill)
 (eepitch-emlua)
print(2 + 3)
print(2 +
      3 +
      4)
= 2,
  3,
  4
= 2 + nil
= EdrxEmacsRepl
PPP(EdrxEmacsRepl)
PPPV(EdrxEmacsRepl.__index)

--")





;;;                 _                                   _       _   _     _     
;;;   ___ _ __ ___ | |_   _  __ _        _____   ____ _| |     | |_| |__ (_)___ 
;;;  / _ \ '_ ` _ \| | | | |/ _` |_____ / _ \ \ / / _` | |_____| __| '_ \| / __|
;;; |  __/ | | | | | | |_| | (_| |_____|  __/\ V / (_| | |_____| |_| | | | \__ \
;;;  \___|_| |_| |_|_|\__,_|\__,_|      \___| \_/ \__,_|_|      \__|_| |_|_|___/
;;;                                                                             
;; «emlua-eval-this»  (to ".emlua-eval-this")
;; Old code, needs updating

(defun emlua-eval-this ()
  (eval (ee-read (aref (emlua-dostring "return eval_this") 0))))





(provide 'emlua-repl)


;; Local Variables:
;; coding:  utf-8-unix
;; End:
