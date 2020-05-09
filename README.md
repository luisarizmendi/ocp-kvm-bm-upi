# What is this repo doing?

You can install OpenShift in a KVM in multiple ways, for example making use of [OpenShift libvirt IPI deployment](https://github.com/luisarizmendi/ocp-libvirt-ipi) or injecting the ignition files using variables of the VM XML definition on libvirt, as [this repo](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4) is doing, but this repo automates emulates a complete OpenShift Baremetal UPI deployment (but using VMs on top of a KVM node), including the PXE booting on the nodes.

# How can I use it?

You need to complete the pre-requisites and launch the script...easy.

## Pre-requisites

* You need to have your system ready to use ansible, so ansible installed, password-less access to the node and a user with sudo privileges

* You need to create a `inventory` file. There is already an inventory.EXAMPLE that you can use as a template

* You need to create a `install-config.yaml` file with the OpenShift configuration. You can find an install-config.EXAMPLE that can used as a template

* You need to create a `var.yaml` file with the variable values. This repo is using the [ocp-prereq ansible role](https://github.com/luisarizmendi/ocp-prereq-role) so you can check in its README file other variables related to that role and that are not described here and that could be useful if you need to customize your deployment. You can find an vars.yaml.EXAMPLE that can used as a template.

This is the desciption of some of the variables that you can find in that vars.yaml.EXAMPLE file:


* ocp_release: The OCP release name in the format "4.x.x". You can check releases in https://mirror.openshift.com/pub/openshift-v4/clients/ocp/  


* kvm_public_interface: KVM interface name (as appears in 'nmcli con show' command) that will be used to access the OpenShift environment


* ocp_create_users: If set to "true" additional users will be created in OpenShift after the deployment. One cluster-wide admin (clusteradmin), 25 users (user1 - user25) included in a group ´developers´ and one cluster wide read only user (viewuser) included in a group called `reviewers`. You can disable it by configuring `ocp_create_users` to `false` or change the usernames or passwords modifying the `ocp_users_password` and `ocp_clusteradmin_password` variables


* libvirt_net_l2: Is set to "true" a bridge with L2 connection to the `kvm_public_interface` is setup. This could be useful to attach "real" phisical worker nodes (maybe with GPUs ;-) ) to the cluster by L2 (so you could use services like DHCP, PXE boot, etc). The ip addressing for this network could be configured using the variable `libvirt_net_subnet24`, for example to configure the 192.168.36.0/24 network you can setup the `libvirt_net_subnet24` to "192.168.36". If you want to configure a network that is not /24 you can use the procedure mentioned in the section below "Pre-required service configurations" to configure the DHCP service. The gateway of this L2 network is by default the .1 address and is setup in the bridge (so the KVM is acting as router). If you want to use an external router and its IP conflicts it (.1) you can setup a different IP for the bridge using the variable `libvirt_net_br_ip`. If that external router has an IP that is not the .1 and you want to use it as default gatway you could need to modify the DHCP service as explained below.


## Pre-required service configurations

You can find all the options in the [ocp-prereq role README file](https://github.com/luisarizmendi/ocp-prereq-role). You should setup the variables in the `ocp-kvm-bm-upi.yaml` file, in the "OCP PREREQUISITES" section.

Let's show an example. Imagine that you want to create a L2 network (192.168.72.0/24) that is extended to a physical network where there is already a physical router (192.168.72.1), you could use that router instead of routing with the KVM node, so you should first add in the `vars.yaml` file some variables as `libvirt_net_subnet24: "true"`, `libvirt_net_subnet24: "192.168.72"` and, since the default gateway conflicts with the default IP setup in that bridge the `libvirt_net_br_ip: "192.168.72.254"`.

After that, you should change the setup of the configured DHCP service by changing the values of the variables in the `ocp-kvm-bm-upi.yaml` file (remember that the DNS service is running on the KVM so we setup the DNS to the `libvirt_net_br_ip` IP that is the IP setup in the L2 bridge):

```
...
- hosts: all
  vars_files:
    - "vars.yaml"
  roles:
    - role: luisarizmendi.ocp_prereq_role
      vars:
        srv_interface: "{{ metadata.name }}"
        nodes_subnet24: "{{ libvirt_net_subnet24 | default('192.168.126') }}"
        ocp_install_config_path: "{{ ocp_install_config_file }}"
        ocp_inject_user_ignition: "true"
        dhcp:
            router: "192.168.72.1"
            bcast: "192.168.72.255"
            netmask: "255.255.255.0"
            poolstart: "192.168.72.10"
            poolend: "192.168.72.30"
            ipid: "192.168.72.0"
            netmaskid: "255.255.255.0"
            dns: "192.168.72.254"
            domainname: "ocp.mydomain.com"
...
```



## Creating or destroying the OpenShift environment

Once you completed the pre-requisites, just run `./create.sh` to deploy OpenShift or `./destroy.sh` to clean up the node.


# Enjoy

That's all, make responsible use of these playbooks (remember that this is just for LABs).