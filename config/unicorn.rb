# Set your full path to application.
app_path = "/home/bubblevine/current"

# Set unicorn options
worker_processes 2
preload_app true
timeout 180
listen "127.0.0.1:9010"

# Spawn unicorn master worker for user apps (group: apps)
user 'bubblevine', 'bubblevine'

# Fill path to your app
working_directory app_path

# Should be 'production' by default, otherwise use other env
rack_env = ENV['RACK_ENV'] || 'production'

# Log everything to one file
stderr_path "log/unicorn.log"
stdout_path "log/unicorn.log"
