
# Prepare the `admin machine` by running ./setup.sh

`./setup.sh` prepares the `admin machine` for using BCM scripts. Here's what ./setup.sh does to the `admin machine`:

* Creates the `~/.bcm/` - BCM scripts store LXD cluster, endpoint, and runtime files in this directory. `setup.sh` initializes ~/.bcm as a git repository for versioning. BCM scripts make regular commits to the ~/.bcm repo as files are added or deleted. 
* (TODO:  ~/.bcm will be mounted using a encrypted [FUSE mount](https://github.com/netheril96/securefs) that can be unlocked interactively with a user-provided password or hardware wallet device).
* Generates the Root Certificate Authority cert at ~/.bcm/certs. Eventually, digital signatures associated with the public key will be relegated exclusively to hardware wallet operations.

`./setup.sh` then passes execution to the `./install_software.sh` script.

It also installs LXD on the `admin machine` so you can deploy BCM scripts locally for testing. docker-ce is also installed on the `admin machine` so you can run doccker containers locally. This allows the BCM admin machine to function without having to install a bunch of new software on your machine. `admin_machine/setup.sh` creates the directory ~/.bcm, which is where BCM scripts store and manage sensitive deployment options and runtime files. Click [here](./setup_README.md) for more information.


Once you have a properly configured LXD endpoint, delve into the [./lxd/](./lxd/) directory. This is where you can deploy BCM data center components. Scripts in this directory are executed against the `admin machine` active LXD remote (run `lxc remote get-default)`. By running BASH scripts on the `admin machine`, you can deploy software-defined components to the target LXD endpoint.




All BCM LXD scripts (any scripts with "_lxd_" in the name) ASSUME that BCM environment variables have been properly sourced PRIOR to being executed.

```REPEAT!!! All BCM '_lxd_' scripts are EXECUTED AGAINST THE ACTIVE LXD REMOTE!!!```

`./setup.sh` places the following lines in your `~/.bashrc` file so you can simply type `bcm` to load all relevant BCM environment variables. ('user' would be replaced with the active username on the `admin machine`)

```bash
### Start BCM
export BCM_LOCAL_GIT_REPO="/home/user/git/github/BitcoinCacheMachine"
alias bcm="source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh"
### END BCM
```

You can inspect `$BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh` to see what happens. That script starts by loading ALL BCM default environment variables, THEN loads the environment variables for the active LXD remote endpoint.











Decide where you want to run your BCM workload. You can deploy BCM to the `admin machine` for quick and convenient testing. You can consider running BCM in a [multipass-based VM](./multipass/) or in a [cloud provider via cloud-init](./cloud_providers/). `multipass` VMs use lower-level hardware-based virtualization which provide additional security guarantees. In the end, all you need to run BCM component is a LXD endpoint configured and controllable by your `admin machine`. Use the `lxc remote list`, `lxc remote get-default` and related commands.
