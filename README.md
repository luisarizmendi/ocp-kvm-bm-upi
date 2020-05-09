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

* libvirt_net_subnet24: The ip addressing for this network could be configured using the variable `libvirt_net_subnet24`, for example to configure the 192.168.36.0/24 network you can setup the `libvirt_net_subnet24` to "192.168.36" (no other network masks are supported using this variable). Let's show an example. Imagine that you want to chenge the address of the libvirt network, from 192.168.126.0/24 that is the default to 192.168.72.0/24.In that case you should first add in the `vars.yaml` file some variables as `libvirt_net_subnet24: "true"` and `libvirt_net_subnet24: "192.168.72"`, then the network will be created with that addressing. When using the `libvirt_net_subnet24` then DHCP configured by the `ocp-prereq` role is automatically re-configured.



## Pre-required service configurations

You can find all the options in the [ocp-prereq role README file](https://github.com/luisarizmendi/ocp-prereq-role). You should setup the variables in the `ocp-kvm-bm-upi.yaml` file, in the "OCP PREREQUISITES" section.

Imagine that you want to change the local users created to provided to permite easy troubleshooting, you should then include the `ocp_local_username` and `ocp_local_userpass` variables in this way:

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
        ocp_local_username: "newuser"
        ocp_local_userpass: "newpassword"

...
```


## Including external physical servers

Imaging that you have a server with "only" 8GB and 4 cores... but with a GPU. That would be great to include it to your OpenShift cluster running in the KVM. By default, the ansible playbooks configure a libvirt virtual network (using NAT to allowing access to external resources), so there is no direct connection between physical networks and that virtual network, but there is a variable that can change that behavior:

* libvirt_net_l2: Is set to "true" a bridge with L2 connection to the `kvm_public_interface` is setup. The gateway of this L2 network is by default the .1 address and it is setup in the bridge (so the KVM is acting as router). In case that you would need to change this IP you could use the variable `libvirt_net_br_ip` but in this case you would need to configure the DHCP server to change the default gateway value, check the [ocp-prereq role README file](https://github.com/luisarizmendi/ocp-prereq-role).

When configured, the L2 connection makes possible to even use the services configured by the `ocp-prereq` role, but in that case remember to include the physical node MAC address in the `nodes` variable list (you can keep the other nodes values as default, but you need to include them in the variable definition, otherwise only the configured nodes in the overwritten variable will be enforced).

### My physical servers must use L3 connection

If your physical server is not attached to the same L2 network the easiest way to do it is by configuring an external physical gateway and change the value of the default gateway in the dhcp `ocp-prepreq` role variable, imagine that the router is located at 192.168.72.254, then you have to setup in `ocp-kvm-bm-upi.yaml` file (DNS is .1 that is the ip configured by default in the KVM bridge):

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
            router: "192.168.72.254"
            bcast: "192.168.72.255"
            netmask: "255.255.255.0"
            poolstart: "192.168.72.10"
            poolend: "192.168.72.30"
            ipid: "192.168.72.0"
            netmaskid: "255.255.255.0"
            dns: "192.168.72.1"
            domainname: "ocp.mydomain.com"
...
```

If you cannot add that gateway, the playbooks won't do it automatically but you could reconfigure the behavior of the firewalld service to not perform source NATing and to allow incomming packects to be forwarded to the internal libvirt network (and you should configure a route for the libvirt network in the router that points to the KVM). I didn't have a chance to test this setup but probably it will work.


## Creating or destroying the OpenShift environment

Once you completed the pre-requisites, just run `./create.sh` to deploy OpenShift or `./destroy.sh` to clean up the node.


# Enjoy

That's all, make responsible use of these playbooks (remember that this is just for LABs).
