((odin-mode . ((eval . (with-eval-after-load 'dape
                         (add-to-list 'dape-configs
                                      '(odin-codelldb
                                        modes (odin-mode)
                                        command "codelldb"
                                        command-args ("--port" :autoport)
                                        port :autoport
                                        compile (lambda () (concat "make -C " (project-root (project-current)) " debug"))
                                        :type "lldb"
                                        :request "launch"
                                        :program (lambda () (concat (project-root (project-current)) "nbody"))
                                        :cwd (lambda () (project-root (project-current))))))))))
