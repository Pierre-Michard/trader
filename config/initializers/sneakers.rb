Sneakers.configure  daemonize: false,
                    amqp: "amqp://localhost",
                    log: "log/sneakers.log",
                    pid_path: "tmp/pids/sneakers.pid",
                    threads: 1,
                    workers: 1
Sneakers.logger.level = Logger::INFO