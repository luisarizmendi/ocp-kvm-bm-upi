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

## Creating or destroying the OpenShift environment

Once you completed the pre-requisites, just run `./create.sh` to deploy OpenShift or `./destroy.sh` to clean up the node.


# Enjoy

That's all, make responsible use of these playbooks (remember that this is just for LABs).