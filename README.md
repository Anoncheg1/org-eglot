# org-eglot
Allow to edit "Org source block" with Eglot and TRAMP on remote LSP server.

Eglot+TRAMP require block to be tangled/exported to file, we use “/tmp/tmp.py” by default.

# Example of usage
```Elisp
(add-to-list 'load-path "~/.emacs.d/") ; directory with file org-eglot.el
(require 'org-eglot)

(defun my/eglot-starter()
  ;; shutdown all connections
  (eglot-shutdown-all) ; two connection to the same file is not allowed
  ;; Eglot configuration
  (setq eglot-workspace-configuration
                '(:pylsp (:plugins (:jedi_completion (:include_params t
                                                      :fuzzy t)
                                    :pylint (:enabled :json-false)))
                  :gopls (:usePlaceholders t)))
  (setq eglot-server-programs
          '((python-ts-mode . ("pylsp"))
            (python-mode . ("pylsp"))
            ))
  ;; start Eglot
  (eglot-ensure))

(setq 'org-eglot-starter #'my/eglot-starter)
```

Now you can use “C-c '” key to edit source block, which is org-edit-special command.

# Source
This package is a little extension of this function from https://github.com/joaotavora/eglot/issues/216#issuecomment-1052931508
```Elisp
(defun mb/org-babel-edit:python ()
  "Edit python src block with lsp support by tangling the block and
then setting the org-edit-special buffer-file-name to the
absolute path. Finally load eglot."
  (interactive)

  ;; org-babel-get-src-block-info returns lang, code_src, and header
  ;; params; Use nth 2 to get the params and then retrieve the :tangle
  ;; to get the filename
  (setq mb/tangled-file-name (expand-file-name (assoc-default :tangle (nth 2 (org-babel-get-src-block-info)))))

  ;; tangle the src block at point
  (org-babel-tangle '(4))
  (org-edit-special)

  ;; Now we should be in the special edit buffer with python-mode. Set
  ;; the buffer-file-name to the tangled file so that pylsp and
  ;; plugins can see an actual file.
  (setq-local buffer-file-name mb/tangled-file-name)
  (eglot-ensure)
  )
```
