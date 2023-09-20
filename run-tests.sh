echo ""
echo "The main.sh script will be run in host A from the local prototype."
echo "------------------------------------------------------------------"
echo WARNING: Note that if you run this script, you will have to change the IP of the remote host.
echo ""

# Define the variables
username="antonio"
prototype_ip="161.67.133.94"
prototype_switch="161.67.133.92"
remote_home="/home/${username}"
remote_results_dir="${remote_home}/results"
remote_scripts_dir="${remote_home}/scripts"
results_dir="../local/results/corundum"
current_time=$(date "+%Y.%m.%d-%H.%M.%S")

# Set default values for the prototype and the configuration
prototype=2
configuration=1

# Send the scripts that perform the measurments to the prototype
ssh ${username}@${prototype_ip} "mkdir scripts"
ssh ${username}@${prototype_ip} "mkdir results"
scp *.tcl *.sh ${username}@${prototype_ip}:${remote_scripts_dir}
ssh ${username}@${prototype_switch} "mkdir scripts"
scp *.tcl *.sh ${username}@${prototype_switch}:${remote_scripts_dir}

#read -p $'What prototype are you going to run the tests into?\n1. CELLIA prototype \n2. Local prototype\n' prototype

# CELLIA
if [ "$prototype" -eq 1 ]; then
    echo ""
    echo "The tests will be run in the CELLIA prototype"
    echo "---------------------------------------------"
    read -p $'What is the prototype configuration?\n1. Host A - Switch - Host B. \n2. Host A - Host B\n' configuration
    if [ "$configuration" -eq 1  ]; then
        echo "TODO" 
    fi
    if [ "$configuration" -eq 2  ]; then
        echo "TODO"
    fi
    if [ "$configuration" != "1" ] && [ "$configuration" != "2" ]; then
        echo $'You selected the wrong configuration. Please, type 1 (Host A - switch - Host B) or 2 (Host B - Host B).'
    fi
fi

# Local
if [ "$prototype" -eq 2 ]; then
    echo ""
    echo "The tests will be run in the local prototype"
    echo "---------------------------------------------"
    #read -p $'What is the prototype configuration?\n1. Host A - Switch - Host B. \n2. Host A - Host B\n' configuration
    # Host A - Switch - Host B
    if [ "$configuration" -eq 1  ]; then
        # We save the previous results or otherwise they will be overwritten
        mv ${results_dir}/con-switch ${results_dir}/con-switch.$current_time
        mkdir ${results_dir}/con-switch
        ssh ${username}@${prototype_switch} "cd ${remote_scripts_dir} && /tools/Xilinx/Vitis/2022.2/bin/xsct reference-switch.tcl"
        ssh ${username}@${prototype_ip} "cd ${remote_scripts_dir} && sudo ./main.sh" && scp -r ${username}@${prototype_ip}:${remote_results_dir}/* ${results_dir}/con-switch/
    fi
    if [ "$configuration" -eq 2  ]; then
        mv ${results_dir}/sin-switch ${results_dir}/sin-switch.$current_time
        mkdir ${results_dir}/sin-switch
        ssh ${username}@${prototype_ip} "cd ${remote_scripts_dir} && sudo ./main.sh" && scp -r ${username}@${prototype_ip}:${remote_results_dir}/*/ ${results_dir}/sin-switch/
    fi
    if [ "$configuration" != "1" ] && [ "$configuration" != "2" ]; then
        echo "You selected the wrong prototype. Please, type '1' (local prototype) or '2' (CELLIA prototype)."
    fi
fi

if [ "$prototype" != "1" ] && [ "$prototype" != "2" ]; then
    echo $'You selected the wrong prototype. Please, type '1' (local prototype) or '2' (CELLIA prototype).'
fi

