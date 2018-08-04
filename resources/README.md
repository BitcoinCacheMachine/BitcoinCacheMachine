# Resources

This folder contains files related to controlling the behavior of the BCM deployment script. You can load environment variables into your BASH shell by sourcing one or more .env files. `source ~/.bcom/defaults.env` will load the default BCM environment variables into your shell. You shouldn't modify `defaults.env`.  Instead, override the variables defined in `defaults.env` by creating a .env file under ~/.bcm/endpoints

By convention, you can create a directory at ~/.bcm. This is your BCM home directory; everything related to your LXD endpoints, multipass VMs, runtime files, etc., will be stored in this directory. Since it contains 