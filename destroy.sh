#!/bin/bash


echo ""
echo "Starting at $(date +%R)"
echo ""

sdate=$(date +%s)



#sudo yum install -y ansible


########################################
# REMOVING OPENSHIFT PREREQUISITES
########################################

#ansible-galaxy install luisarizmendi.ocp_prereq_role --force


ansible-playbook -vv -i inventory --tags remove ocp-kvm-bm-upi.yaml


########################################




cdate=$(date +%s)
duration=$(( $(($cdate-$sdate)) / 60))

echo ""
echo "Duration (mins): $duration"
echo ""
