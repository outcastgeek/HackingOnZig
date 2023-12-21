
((nil . ((eval . (progn
                   ;; Enable C++20 support
                   (setq flycheck-clang-language-standard "c++20")
                   (setq lsp-clients-clangd-args '("-j=3" "--background-index" "--clang-tidy"
                                                   "--completion-style=detailed" "--header-insertion=never"
                                                   "--header-insertion-decorators=0"))
                   (after! lsp-clangd (set-lsp-priority! 'clangd 2))
                   ;; Set the OpenAI key
                   (setq org-ai-openai-api-token
                         (or
                          (getenv "OPENAI_KEY") "OPENAI_KEY not set"))
                   ;; (setq org-ai-default-chat-model "gpt-4-0613")
                   (setq org-ai-default-chat-model "gpt-4-1106-preview")
                   ;; PlantUML
                   (setq plantuml-default-exec-mode 'jar)))
               ))
      ))
