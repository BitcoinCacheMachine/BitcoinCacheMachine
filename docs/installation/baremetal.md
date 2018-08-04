
# Run BCM on bare-metal Ubuntu 18.04

If you're already running Linux on a computer, you can probably run BCM directly as a kind of LXD-based background application. This is preferred from a performance perspective since we can avoid hardware virtualization.

To run BCM on bare metal, you need to install LXD and some other dependencies.  Consult [LXD Host Prep Instructions](./docs/installation/lxd_host_prep.md) for details on preparing an arbitrary bare-metal Linux machine for BCM. The instructions are pretty easy and replicate what occurs with cloud-init files with [multipass](./multipass/multipass_cloud-init.yml) or when using [Amazon Web Services (AWS)](https://aws.amazon.com/), or Digital Ocean, or whatever.

> REMINDER! BCM is intended for home and office settings. Using BCM "in the cloud" kind of defeats the purpose of the thing.

