((odin-mode . ((eval . (with-eval-after-load 'dape
                         (add-to-list 'dape-configs
                                      '(odin-codelldb
                                        modes (odin-mode)
                                        command "codelldb"
                                        command-args ("--port" :autoport)
                                        port :autoport
                                        :type "lldb"
                                        :request "launch"
                                        :program "nbody"
                                        :cwd "."
                                        :fn (lambda (config)
                                              (dape-compile config "make debug")))))))))
