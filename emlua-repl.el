;; This file:
;;   http://angg.twu.net/emlua/emlua-repl.el.html
;;   http://angg.twu.net/emlua/emlua-repl.el
;;           (find-angg "emlua/emlua-repl.el")
;; https://raw.githubusercontent.com/edrx/emlua/main/emlua-repl.el
;;           https://github.com/edrx/emlua/blob/main/emlua-repl.el
;; Author: Eduardo Ochs <eduardoochs@gmail.com>
;; Version: 2022mar27
;; License: GPL2
;;
;; See: <https://github.com/edrx/emlua>.


;; Introduction
;; ============
;; This file implements `eepitch-emlua' and several variants of it -
;; i.e., it implements "several different `eepitch-emlua's".
;;
;; All these `eepitch-emlua's pitch things to the emlua buffer, and
;; this GENERALLY means that they talk to a Lua interpreter via
;; `emlua-dostring' and then use the emlua buffer as a kind of log of
;; the communication. This screenshot shows how this is _typically_
;; used:
;;
;;   http://angg.twu.net/IMAGES/2022eepitch-emlua-0.png
;;
;; BUT: the emlua buffer is just a log buffer, and to keep the code
;; simple I keep it in fundamental mode. This means that RET there is
;; not special: typing, say,
;;
;;   print(2+3)
;;
;; after a prompt in the emlua buffer and then typing RET does not
;; send the "print(2+3)" to the Lua interpreter, or anywhere - the RET
;; just inserts a "\n".
;;
;; Remember that `eepitch-shell' sets up a target buffer running an
;; "inferior shell". See:
;;
;;   (find-eev-quick-intro "6. Controlling shell-like programs")
;;   (find-enode "Major Modes" "inferior shell process")
;;   (find-enode "Interactive Shell")
;;
;; Here are the first two paragraphs of the page "Interactive Shell":
;;
;;   To run a subshell interactively, type ‘M-x shell’. This creates
;;   (or reuses) a buffer named ‘*shell*’, and runs a shell subprocess
;;   with input coming from and output going to that buffer. That is
;;   to say, any terminal output from the subshell goes into the
;;   buffer, advancing point, and any terminal input for the subshell
;;   comes from text in the buffer. To give input to the subshell, go
;;   to the end of the buffer and type the input, terminated by <RET>.
;;   
;;   By default, when the subshell is invoked interactively, the
;;   ‘*shell*’ buffer is displayed in a new window, unless the current
;;   window already shows the ‘*shell*’ buffer. This behavior can be
;;   customized via ‘display-buffer-alist’.
;;
;; In this file the notion "inferior Lua" will be kept deliberately
;; vague: the meaning of "sending (something) the the inferior Lua"
;; will depend on the context, and _can be modified at will_. In most
;; cases it means:
;;
;;   send [this] to the REPL running in the Lua interpreter showing
;;   [this] in the log buffer, and then show in the log buffer the
;;   answer of the Lua interpreter and the next prompt
;;
;; but the details of this "send" can change, and the REPL can change
;; - for example, Technomancy is experimenting with REPLs based on
;; coroutines, and I am making some experiments with REPLs that send
;; text with properties back to Emacs - and in same cases we perform
;; tests using fake REPLs that always answer the same string.
;;
;;
;; `emlua-do'
;; ==========
;; One of the main building blocks of this file is the function
;; `emlua-do', whose semantics can also be changed. In principle
;;
;;   (emlua-do '(foo bar))
;;
;; evals `(foo bar)' inside the emlua buffer, but this can mean
;; something full of add-ons, like "make sure that the emlua buffer
;; exists, is initialized, and is shown in a visible window, and run
;; `(foo bar)' there with the point at the end of the buffer".
;;
;; Right now the behavior of `emlua-do' is changed by defalias-ing it
;; to different functions.


;; An older description:
;; ---------------------
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
;; «.find-emluabuffer»		(to "find-emluabuffer")
;; «.emlua-do»			(to "emlua-do")
;; «.emlua-insert»		(to "emlua-insert")
;; «.eepitch-emlua-fake1»	(to "eepitch-emlua-fake1")

;; «.find-buffer»		(to "find-buffer")
;; «.prep»			(to "prep")
;; «.insert»			(to "insert")
;; «.eepitch-emlua-fakesend»	(to "eepitch-emlua-fakesend")
;; «.esend»			(to "esend")
;; «.eepitch-emlua»		(to "eepitch-emlua")
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
  '((((background dark))  :foreground "RoyalBlue3")
    (((background light)) :foreground "RoyalBlue3"))
  "")

(defface emlua-user-input-face
  '((((background dark))  :foreground "orange1")
    (((background light)) :foreground "DarkOrange"))
  "")

(defface emlua-output-face
  '((((background dark))  :foreground "bisque")
    (((background light)) :foreground "SaddleBrown"))
  "")

(defface emlua-error-face
  '((((background dark))  :foreground "red")
    (((background light)) :foreground "red"))
  "")





;;;   __ _           _       _            __  __           
;;;  / _(_)_ __   __| |     | |__  _   _ / _|/ _| ___ _ __ 
;;; | |_| | '_ \ / _` |_____| '_ \| | | | |_| |_ / _ \ '__|
;;; |  _| | | | | (_| |_____| |_) | |_| |  _|  _|  __/ |   
;;; |_| |_|_| |_|\__,_|     |_.__/ \__,_|_| |_|  \___|_|   
;;;                                                        
;; «find-emluabuffer»  (to ".find-emluabuffer")

(defun emlua-buffer ()
  "Return the *emlua* buffer, or nil if it doesn't exist."
  (get-buffer "*emlua*"))

(defun emlua-buffer-initial-prompt ()
  (propertize "Emlua:\n>>> " 'face 'emlua-prompt-face))

(defun find-emluabuffer ()
  "Go to the *emlua* buffer, and make sure it's initialized."
  (if (emlua-buffer)
      (find-ebuffer "*emlua*")
    (find-ebuffer "*emlua*")
    (insert (emlua-buffer-initial-prompt))))

;; Other basic tools:
;;
(defun emlua-window ()
  "Return a window with the *emlua* buffer, or nil if it doesn't exist."
  (get-buffer-window "*emlua*"))

(defun emlua-buffer-kill ()
  (if (emlua-buffer) (ee-kill-buffer (emlua-buffer))))



;;;                 _                       _       
;;;   ___ _ __ ___ | |_   _  __ _        __| | ___  
;;;  / _ \ '_ ` _ \| | | | |/ _` |_____ / _` |/ _ \ 
;;; |  __/ | | | | | | |_| | (_| |_____| (_| | (_) |
;;;  \___|_| |_| |_|_|\__,_|\__,_|      \__,_|\___/ 
;;;                                                 
;; «emlua-do»  (to ".emlua-do")

(defun emlua-do-b (code)
  (find-emluabuffer)
  (goto-char (point-max))
  (eval code))

(defun emlua-do-bs (code)
  (save-excursion
    (find-emluabuffer)
    (goto-char (point-max))
    (eval code)))

(defun emlua-do-w (code)
  (if (not (emlua-window))
      (find-2a nil '(find-emluabuffer)))
  (save-selected-window
    (select-window (emlua-window))
    (goto-char (point-max))
    (eval code)))

(defalias 'emlua-do 'emlua-do-bs)



;;;  _                     _   
;;; (_)_ __  ___  ___ _ __| |_ 
;;; | | '_ \/ __|/ _ \ '__| __|
;;; | | | | \__ \  __/ |  | |_ 
;;; |_|_| |_|___/\___|_|   \__|
;;;                            
;; «emlua-insert»  (to ".emlua-insert")

(defun emlua-insert (str &optional face)
  (emlua-do `(insert ,(propertize str 'face face))))

(defun emlua-insert-prompt (prompt)
  (emlua-insert prompt 'emlua-prompt-face))

(defun emlua-insert-user-input (line)
  (emlua-insert (concat line "\n") 'emlua-user-input-face))

(defun emlua-insert-output (output)
  (emlua-insert output 'emlua-output-face))

(defun emlua-insert-error (err)
  (emlua-insert err 'emlua-error-face))


'("This is a test block:
 (emlua-buffer-kill)
 (defalias 'emlua-do 'emlua-do-w)
 (emlua-do nil)
 (emlua-insert-user-input "foo")
 (emlua-insert-output "bar\n")
 (emlua-insert-prompt ">-> ")

--")




;;;   __       _        _ 
;;;  / _| __ _| | _____/ |
;;; | |_ / _` | |/ / _ \ |
;;; |  _| (_| |   <  __/ |
;;; |_|  \__,_|_|\_\___|_|
;;;                       
;; «eepitch-emlua-fake1»  (to ".eepitch-emlua-fake1")

(defun eepitch-line-emlua-fake1 (line)
  (eepitch-eval-at-target-window
   `(progn (emlua-insert-user-input ,line)
	   (emlua-insert-output "(emlua-fake1 output)\n")
	   (emlua-insert-prompt ">-> "))))

(defun eepitch-emlua-fake1 ()
  (interactive)
  (defalias 'emlua-do 'emlua-do-b)
  (prog1 (eepitch '(find-emluabuffer))
    (setq eepitch-line 'eepitch-line-emlua-fake1)))


'("This is a test block:
 (eepitch-emlua-fake1)
 (eepitch-kill)
 (eepitch-emlua-fake1)
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
      (emlua-insert-error (concat eepitch-emlua-out "\n"))
    (if (= 0 (length eepitch-emlua-out))
	"eepitch-emlua-out is []: do nothing"
      (emlua-insert-output (aref eepitch-emlua-out 0)))))

(defun eepitch-emlua-eprompt ()
  "Insert the result of REPL:eprompt() at the end of the *emlua* buffer."
  (emlua-insert-prompt
   (aref (emlua-dostring "return REPL:eprompt()") 0)))


'("This is a test block:
 (defalias 'emlua-do 'emlua-do-w)
 (emlua-buffer-kill)
 (find-2a nil '(find-emluabuffer)))
 (emlua-insert-user-input "= 22+33")
 (eepitch-emlua-esend0    "= 22+33")
 (eepitch-emlua-esend1)
 (eepitch-emlua-eprompt)

--")








;;;                  _ _       _                          _             
;;;   ___  ___ _ __ (_) |_ ___| |__         ___ _ __ ___ | |_   _  __ _ 
;;;  / _ \/ _ \ '_ \| | __/ __| '_ \ _____ / _ \ '_ ` _ \| | | | |/ _` |
;;; |  __/  __/ |_) | | || (__| | | |_____|  __/ | | | | | | |_| | (_| |
;;;  \___|\___| .__/|_|\__\___|_| |_|      \___|_| |_| |_|_|\__,_|\__,_|
;;;           |_|                                                       
;;
;; «eepitch-emlua»  (to ".eepitch-emlua")

(defun eepitch-line-emlua (line)
  (eepitch-eval-at-target-window
   `(progn (emlua-insert-user-input ,line)
	   (eepitch-emlua-esend0    ,line)
	   (eepitch-emlua-esend1)
	   (eepitch-emlua-eprompt))))

(defun eepitch-emlua ()
  "Setup eepitch-ing to an inferior Lua.
The \"inferior Lua\" is not a process associated to the *emlua*
buffer - it is a Lua interpreter. We exchange data with it using
`emlua-dostring', and we use the *emlua* buffer as a log of our
communications with it. See the source of `eepitch-line-emlua' to
understand what happens when we send a line to the inferior Lua."
  (interactive)
  (defalias 'emlua-do 'emlua-do-b)
  (prog1 (eepitch '(find-emluabuffer))
    (setq eepitch-line 'eepitch-line-emlua)))



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
