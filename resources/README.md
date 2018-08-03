# Resources

This folder contains files related to controlling the behavior of the BCM deployment script. You can load enviornment variables into your BASH shell by sourcing .env files. `source ./defaults.env` will load the environment variables defined in `defaults.env` into your current shell. 

By convention, you can create a directory at ~/.bcm. This is your BCM home directory; everything related to your LXD endpoints, multipass VMs, runtime files, etc., will be stored in this directory. Since it contains 