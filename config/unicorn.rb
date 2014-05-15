require 'fileutils'

# Log location
FileUtils.mkdir('./logs') unless File.exists?('./logs')
stderr_path './logs/waylon.log'
stdout_path './logs/waylon.log'

# Number of worker processes to launch.
# Generally speaking, launching two per CPU core is fine.
worker_processes 4

# Timeout, in seconds.
# This should be less than Waylon's `refresh_interval`
timeout 55

