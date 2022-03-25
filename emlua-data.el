;;; This file:
;;;   http://angg.twu.net/emacs-lua/emlua-data.el.html
;;;   http://angg.twu.net/emacs-lua/emlua-data.el
;;;           (find-angg "emacs-lua/emlua-data.el")
;;; Author: Eduardo Ochs <eduardoochs@gmail.com>
;;;
;;; (defun e () (interactive) (find-angg "emacs-lua/emlua-data.el"))

;; Some functions send data from Emacs to Lua.
;; In this file Lua programs are always considered as being strings,
;; and Lua numbers and Lua strings are considered as how they appear
;; in Lua programs. So:
;;
;;    Emacs       Lua
;;    -----   ----------
;;     2.34     "2.34"
;;    "foo"   "[=[foo]=]"
;;
;; The function `emlua-format' can be used to produce Lua programs
;; from templates. For example:
;;
;;   (emlua-format "a[%s] = %s"  2.34  "foo")
;;        -->    "a[2.34] = [=[foo]=]"



;; High-level functions.
;; Example:
;;      (emlua-format "a[%s] = %s"          2.34           "foo")
;;  -->       (format "a[%s] = %s" (emlua-q 2.34) (emlua-q "foo"))
;;  -->       (format "a[%s] = %s"         "2.34"       "[=[foo]=]")
;;  -->             "a[2.34] = [=[foo]=]"
;;
(defun emlua-format (fmt &rest rest)
  "This is like (apply 'format FMT REST), but it treats FMT as a
Lua program. The elements of REST are quoted with `emlua-q'."
  (apply 'format fmt (mapcar 'emlua-q rest)))

(defun emlua-q (o)
  "Transform the elisp object O to Lua."
  (if (stringp o)
      (emlua-q-string o)
    (format "%S" o)))


;; Low-level functions.
;; Tests: (find-ehashtable (emlua-q-string-hash-table "[==[]===]"))
;;        -->  2->t, 3->t
;;        (emlua-q-string-new-core "[==[]===]")
;;        (emlua-q-string-new-core "[=[  ]==]")
;;        (emlua-q-string          "[=[  ]==]")
;;        (emlua-q                 "[=[  ]==]")
;;
;;    (setq ht (emlua-q-hash-table "[==[]===]"))
;;    (setq ht (emlua-q-hash-table "[=[ ]===]"))
;;    (find-ehashtable ht)
;;    (gethash 1 ht)
;;    (gethash 2 ht)
;;    (emlua-q-hash-table-new-core ht)
;;
;; Based on: (find-efunction 'replace-regexp-in-string)
;;      See: (find-elnode "Creating Hash")
;;           (find-elnode "Hash Access")
;;
(defun emlua-q-string (string)
  "Transform the elisp string STRING to Lua."
  (let ((core (emlua-q-string-new-core string)))
    (format "[%s[%s]%s]" core string core)))

(defun emlua-q-string-hash-table (string)
  "Parse the elisp string STRING and return a hash table with the
cores of the delimiters of long comments found in the string. The
\"core\" of \"[===[\" is \"===\", that is converted to 3. If
STRING is \"[==[]===]\" then this function returns a hash table
whose entries 2 and 3 both have the value `t'."
  (let* ((regexp (rx (any "[]") (one-or-more "=") (any "[]")))
         (hash-table (make-hash-table))
         (l (length string))
	 (start 0)
         mb me)
    (save-match-data
      (while (and (< start l) (string-match regexp string start))
	(setq mb (match-beginning 0)
	      me (match-end 0))
        (puthash (- me mb 2) t hash-table)
	(setq start me))
      hash-table)))

(defun emlua-q-hash-table-new-core (hash-table)
  "Return a core that is not in HASH-TABLE. See `emlua-q-hash-table'."
  (cl-loop for k from 1
           do (if (not (gethash k hash-table))
		  (cl-return (make-string k ?=)))))

(defun emlua-q-string-new-core (string)
  "Return a core that is not in STRING. See `emlua-q-hash-table'."
  (emlua-q-hash-table-new-core (emlua-q-string-hash-table string)))



(provide 'emlua-data)


; Local Variables:
; coding:  utf-8-unix
; End:
