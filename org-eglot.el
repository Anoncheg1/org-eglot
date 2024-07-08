;;; org-eglot.el --- Traverse Dired buffer's history: back, forward -*- lexical-binding: t -*-
;; Copyright (C) 2024 github.com/Anoncheg1,codeberg.org/Anoncheg

;; Author: github.com/Anoncheg1,codeberg.org/Anoncheg
;; Version: 0.0.1
;; Keywords: literate programming, reproducible research
;; URL: https://github.com/Anoncheg1/org-eglot

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Allow to edit "Org source block" with Eglot and TRAMP on remote LSP
;; server.
;; Key "C-c '" bound to `org-edit-special' that we wrap with our code.
;; We solve following issues:

;; - tangling reguided for TRAMP

;; - default-directory and buffer-file-name required for Eglot

;; - if no :dir for src block was specified as remote we configure
;;   Eglot for remote connection.

;;; Code:

(defcustom org-eglot-starter #'eglot-ensure
  "`eglot-ensure' or wrap around it.
May check `default-directory' or `buffer-file-name and decide
what `eglot-server-programs' to use.  Check that variable `buffer-file-name'
is remote and call `eglot-ensure' function.
Consider `eglot-shutdown-all' for reconnection."
  :group 'org-eglot
  :type 'function)

(defcustom org-eglot-starter-local org-eglot-starter
  "`eglot-ensure' or wrap around it."
  :group 'org-eglot
  :type 'function)

(defun org-eglot--org-edit-special-advice (orig-fun &rest args)
  "Edit python src block with LSP support.
By tangling the block and then setting the `org-edit-special'
variable `buffer-file-name' to the absolute path.  Finally load
eglot.  By default tangle to /tmp/tmp.py.  Source block should
have :dir value /ssh:host:.
Argument ORIG-FUN is original `org-edit-special' function.
Optional argument ARGS ."
  (interactive)
  (let* ((info (org-babel-get-src-block-info)) ; available only here
         (dir (cdr (assq :dir (nth 2 info))))
         angled-file-name)
    ;; (print (list "dir" dir))
    ;; if dir specified and remote
    (if (and dir (file-remote-p dir))
        (progn
          (setq tang (assoc-default :tangle (nth 2 info)))
          (setq tangled-file-name (if (string-equal tang "no")
                                      (concat dir "/tmp/tmp.py")
                                    ;; else
                                    tang
                                    ))
          ;; (print (list "tang" tang tangled-file-name))
          ;; tangle the src block at point
          (org-babel-tangle '(4)) ; required by TRAMP

          (apply orig-fun args) ; (org-edit-special)
          ;; Now we should be in the special edit buffer with python-mode. Set
          ;; the buffer-file-name to the tangled file so that pylsp and
          ;; plugins can see an actual file.
          (setq-local default-directory dir) ; reqguired for Eglot
          (setq-local buffer-file-name tangled-file-name) ; requiered for Eglot
          (funcall org-eglot-starter))
      ;; else - local
      (apply orig-fun args)
      (funcall org-eglot-starter-local))))

(advice-add 'org-edit-special :around 'org-eglot--org-edit-special-advice)


(provide 'org-eglot)
;;; org-eglot.el ends here
