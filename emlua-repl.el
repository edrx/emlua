;; This file:
;;   http://angg.twu.net/emlua/emlua-repl.el.html
;;   http://angg.twu.net/emlua/emlua-repl.el
;;           (find-angg "emlua/emlua-repl.el")
;; https://raw.githubusercontent.com/edrx/emlua/main/emlua-repl.el
;;           https://github.com/edrx/emlua/blob/main/emlua-repl.el
;; Author: Eduardo Ochs <eduardoochs@gmail.com>
;; Version: 2022mar26
;; License: GPL2
;;
;; See: https://github.com/edrx/emlua

;; This file implements `eepitch-emlua', that is an eepitch whose
;; target is a Lua interpreter running in a dynamic module loaded by
;; Emacs. The interaction with that interpreter is shown in a buffer
;; called "*emlua*".
;;
;; Note: this is my N-th attempt (for N big!) of rewriting this file
;; to make its code easy to understand... but it still needs more
;; rewrites, and lots of explanations and tests. In particular, 1) I
;; need to rename some functions to make clear that we are
;; implementing a kind of an "inferior process" running Lua, 2) I need
;; to explain that the buffer "*emlua*" is just a log of our
;; interactions with our "inferior Lua" via `eepitch-emlua-esend' -
;; lines typed there are not automatically sent to the inferior Lua,
;; 3) it _seems_ that the functions that end in "-bw" are not needed,
;; 4) only a few functions defined in eepitch.el use
;;
;;   (setq eepitch-line 'eeepitch-line-<suffix>)
;;
;; to set up alternative ways to send lines to the target. I did not
;; remember the details of how they worked, and I improvised a lot,
;; using functions with bad names and weird constructs... I need to
;; clean up that code A LOT. There are some examples of "official"
;; functions that use alternative `eepitch-line's here:
;;
;;   (find-eev "eepitch.el" "other-terms")
;; 
;; See also:
;; 
;;   (find-eev "eepitch.el" "eepitch-this-line")

;; «.faces»			(to "faces")
;; «.find-buffer»		(to "find-buffer")
;; «.prep»			(to "prep")
;; «.insert»			(to "insert")
;; «.eepitch-emlua-fakesend»	(to "eepitch-emlua-fakesend")
;; «.esend»			(to "esend")
;; «.eepitch-emlua»		(to "eepitch-emlua")




;; To test this, compile emlua.cpp, then run:
;;
;;   (add-to-list 'load-path default-directory)
;;   (require 'emlua-repl)
;;   (emlua-init-so)
;;   (emlua-init-dofiles)
;;   (emlua-init-newrepl)
;;
;; and then run the test blocks in this file.

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
;; «find-buffer»  (to ".find-buffer")
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
;;
;; «prep»  (to ".prep")

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
;; «insert»  (to ".insert")

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





;;;   __       _                            _ 
;;;  / _| __ _| | _____  ___  ___ _ __   __| |
;;; | |_ / _` | |/ / _ \/ __|/ _ \ '_ \ / _` |
;;; |  _| (_| |   <  __/\__ \  __/ | | | (_| |
;;; |_|  \__,_|_|\_\___||___/\___|_| |_|\__,_|
;;;                                           
;; «eepitch-emlua-fakesend»  (to ".eepitch-emlua-fakesend")

(defun eepitch-emlua-fakesend (line)
  (eepitch-eval-at-target-window
   '(progn
      ;; (save-excursion (eepitch-emlua-prep-b))
      (eepitch-emlua-prep-b)
      (eepitch-emlua-insert-user-input line)
      (eepitch-emlua-insert-output "(Using fakesend)\n")
      (eepitch-emlua-insert-prompt ">>> "))))


'("This is a test block:
 (eepitch-emlua-fakesend)
 (eepitch-kill)
 (eepitch-emlua-fakesend)
foo
bar

--")




;;;                           _ 
;;;   ___  ___  ___ _ __   __| |
;;;  / _ \/ __|/ _ \ '_ \ / _` |
;;; |  __/\__ \  __/ | | | (_| |
;;;  \___||___/\___|_| |_|\__,_|
;;;                             
;; «esend»  (to ".esend")

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





;;;                  _ _       _                          _             
;;;   ___  ___ _ __ (_) |_ ___| |__         ___ _ __ ___ | |_   _  __ _ 
;;;  / _ \/ _ \ '_ \| | __/ __| '_ \ _____ / _ \ '_ ` _ \| | | | |/ _` |
;;; |  __/  __/ |_) | | || (__| | | |_____|  __/ | | | | | | |_| | (_| |
;;;  \___|\___| .__/|_|\__\___|_| |_|      \___|_| |_| |_|_|\__,_|\__,_|
;;;           |_|                                                       
;;
;; «eepitch-emlua»  (to ".eepitch-emlua")

(defun eepitch-emlua ()
  "Setup eepitch-ing to an emlua buffer."
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




;; TODO: rewrite this idea, that was from an older version...
;; (defun emlua-eval-this ()
;;   (eval (ee-read (aref (emlua-dostring "return eval_this") 0))))

(provide 'emlua-repl)


;; Local Variables:
;; coding:  utf-8-unix
;; End:
