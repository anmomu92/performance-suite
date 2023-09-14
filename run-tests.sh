echo ""
echo "The main.sh script will be run in host A from the local prototype."
echo "------------------------------------------------------------------"
echo WARNING: Note that if you run this script, you will have to change the IP of the remote host.
echo ""

username="antonio"
prototype_ip="161.67.132.94"
remote_results_dir=/home/${username}/Documents/repo/results/corundum
remote_scripts_dir=/home/${username}/Documents/repo/scripts
results_dir="../local/results/corundum"
current_time=$(date "+%Y.%m.%d-%H.%M.%S")

read -p $'What prototype are you going to run the tests into?\n1. CELLIA prototype \n2. Local prototype\n' prototype

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
        echo $'You selected the wrong configuration. Please, type '1' (Host A - switch - Host B) or '2' (Host B - Host B).'
    fi
fi

# Local
if [ "$prototype" -eq 2 ]; then
    echo ""
    echo "The tests will be run in the local prototype"
    echo "---------------------------------------------"
    read -p $'What is the prototype configuration?\n1. Host A - Switch - Host B. \n2. Host A - Host B\n' configuration
    if [ "$configuration" -eq 1  ]; then
        mv ${results_dir}/con-switch ${results_dir}/con-switch.$current_time.txt
        ssh ${username}@{prototype_ip} "sudo ${remote_scripts_dir}/main.sh"
        scp ${username}@{prototype_ip}:${remote_results_dir}/con-switch/* ${results_dir}/con-switch
    fi
    if [ "$configuration" -eq 2  ]; then
        mv ${results_dir}/sin-switch ${results_dir}/sin-switch.$current_time.txt
        ssh ${username}@{prototype_ip} "sudo ${remote_scripts_dir}/main.sh"
        scp ${username}@{prototype_ip}:${remote_results_dir}/sin-switch/* ${results_dir}/sin-switch
    fi
    if [ "$configuration" != "1" ] && [ "$configuration" != "2" ]; then
        echo "You selected the wrong prototype. Please, type '1' (local prototype) or '2' (CELLIA prototype)."
    fi
fi

if [ "$prototype" != "1" ] && [ "$prototype" != "2" ]; then
    echo $'You selected the wrong prototype. Please, type '1' (local prototype) or '2' (CELLIA prototype).'
fi

touch filename.txt


echo $current_time

