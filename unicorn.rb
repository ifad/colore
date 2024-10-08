# frozen_string_literal: true

# set path to app that will be used to configure unicorn,
# note the trailing slash in this example
require 'pathname'
@dir = Pathname.new(__FILE__).realpath.parent

worker_processes 2
working_directory @dir

timeout 30

# Specify path to socket unicorn listens to,
# we will use this in our nginx.conf later
listen @dir + '.unicorn.sock', backlog: 64

# Set process id path
pid @dir + 'tmp' + 'pids' + 'unicorn.pid'

# Set log file paths
stderr_path @dir + 'log' + 'unicorn.stderr.log'
stdout_path @dir + 'log' + 'unicorn.stdout.log'
