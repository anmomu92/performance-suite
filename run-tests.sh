#!/bin/bash

source settings.sh

echo ""
echo "The main.sh script will be run in host A from the local prototype."
echo "------------------------------------------------------------------"
echo WARNING: Note that if you run this script, you will have to change the IP of the remote host.
echo ""

# Variables
prototype=2
configuration=1
current_time=$(date "+%Y.%m.%d-%H.%M.%S")

# Create the remote directories where the scripts and results will be stored
ssh ${USERNAME}@${HOST_A} "mkdir scripts"
ssh ${USERNAME}@${HOST_A} "mkdir results"
ssh ${USERNAME}@${SWITCH} "mkdir scripts"

# Send the scripts that perform the measurments to the prototype
scp *.tcl *.sh ${USERNAME}@${HOST_A}:${REMOTE_SCRIPTS_DIR}
scp *.tcl *.sh ${USERNAME}@${SWITCH}:${REMOTE_SCRIPTS_DIR}

read -t 10 -p $'What prototype are you going to run the tests into?\n1. CELLIA prototype \n2. Local prototype\n' prototype

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

# Local prototype
if [ "$prototype" -eq 2 ]; then
    echo ""
    echo "The tests will be run in the local prototype"
    echo "---------------------------------------------"

    # Request the user which configuration is going to be tested
    read -t 10 -p $'What is the prototype configuration?\n1. Host A - Switch - Host B. \n2. Host A - Host B\n' configuration

    # Configuration #1: Host A - Switch - Host B
    if [ "$configuration" -eq 1  ]; then
        # Check if the results directory exists
        if [ ! -d "$RESULTS_DIR/con-switch" ]; then
            mkdir -p $RESULTS_DIR/con-switch
        else 
            # Save the previous results or otherwise they will be overwritten
            mv ${RESULTS_DIR}/con-switch ${RESULTS_DIR}/con-switch.$current_time

            # Program the switch
            ssh ${USERNAME}@${SWITCH} "cd ${REMOTE_SCRIPTS_DIR} && /tools/Xilinx/Vitis/2022.2/bin/xsct reference-switch.tcl"

            # Launch the tests remotely and send the results back
            ssh ${USERNAME}@${HOST_A} "cd ${REMOTE_SCRIPTS_DIR} && sudo ./main.sh" && scp -r ${USERNAME}@${HOST_A}:${REMOTE_RESULTS_DIR}/* ${RESULTS_DIR}/con-switch/
        fi
    fi

    # Configuraion #2: Host A - Host B
    if [ "$configuration" -eq 2  ]; then
        # Check if the results directory exists
        if [ ! -d "$RESULTS_DIR/con-switch" ]; then
            mkdir ${RESULTS_DIR}/sin-switch
        else 
            # Save the previous results or otherwise they will be overwritten
            mv ${RESULTS_DIR}/sin-switch ${RESULTS_DIR}/sin-switch.$current_time

            # Launch the tests remotely and send the results back
            ssh ${USERNAME}@${HOST_A} "cd ${REMOTE_SCRIPTS_DIR} && sudo ./main.sh" && scp -r ${USERNAME}@${HOST_A}:${REMOTE_RESULTS_DIR}/*/ ${RESULTS_DIR}/sin-switch/
        fi
    fi

    # Wrong configuration selection
    if [ "$configuration" != "1" ] && [ "$configuration" != "2" ]; then
        echo "You selected the wrong prototype. Please, type '1' (local prototype) or '2' (CELLIA prototype)."
    fi
fi

# Wrong prototype selection
if [ "$prototype" != "1" ] && [ "$prototype" != "2" ]; then
    echo $'You selected the wrong prototype. Please, type '1' (local prototype) or '2' (CELLIA prototype).'
fi

