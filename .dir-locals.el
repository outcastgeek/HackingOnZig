;; https://projectile.readthedocs.io/en/latest/configuration/
;; Projectile Configuration
((nil . ((eval . (setq projectile-project-root
                       (locate-dominating-file buffer-file-name
                                               ".dir-locals.el")))
         (eval . (setq home-dir (getenv "HOME")))
         (eval . (progn
                   (require 'lsp)
                   (add-to-list 'lsp-language-id-configuration '(zig-mode . "zig"))
                   (lsp-register-client
                    (make-lsp-client
                     :new-connection (lsp-stdio-connection (concat home-dir "/.local/bin/zls")) ;; "<path to zls>"
                     :major-modes '(zig-mode)
                     :server-id 'zls))))
         )))

