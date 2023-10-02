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
ssh ${USERNAME}@${HOST_A} "sudo rm -r results"
ssh ${USERNAME}@${HOST_A} "sudo rm -r logs"
ssh ${USERNAME}@${HOST_A} "mkdir results"
ssh ${USERNAME}@${HOST_A} "mkdir logs"
ssh ${USERNAME}@${SWITCH} "mkdir scripts"

# Send the scripts that perform the measurments to the prototype
scp *.tcl *.sh ${USERNAME}@${HOST_A}:${REMOTE_SCRIPTS_DIR} && echo ""; echo "FILES COPIED SUCCESSFULLY TO HOST A"; echo "-----------------------------------------"
echo ""
scp *.tcl *.sh ${USERNAME}@${SWITCH}:${REMOTE_SCRIPTS_DIR} && echo ""; echo "FILES COPIED SUCCESSFULLY TO SWITCH"; echo "-----------------------------------------"
echo ""

read -t 10 -p $'What prototype are you going to run the tests into?\n1. CELLIA prototype \n2. Local prototype\n' prototype

# Default value
if [ $? != 0 ]; then
    prototype=2
fi

# CELLIA
if [ "$prototype" -eq 1 ]; then
    echo ""
    echo "The tests will be run in the CELLIA prototype"
    echo "---------------------------------------------"
    echo ""
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
    echo ""

    # Request the user which configuration is going to be tested
    read -t 10 -p $'What is the prototype configuration?\n1. Host A - Host B. \n2. Host A - Switch - Host B\n' configuration
    
    # Default value
    if [ $? != 0 ]; then
        configuration=1
    fi

    # Configuration #1: Host A - Host B
    if [ "$configuration" -eq 1  ]; then
        echo ""
        echo "The tests will be run using configuration 1: HA - HB"
        echo "----------------------------------------------------"
        echo ""
        # Check if the results directory exists
        if [ ! -d "$RESULTS_DIR/sin-switch" ]; then
            mkdir ${RESULTS_DIR}/sin-switch
        else
            mkdir ${RESULTS_DIR}/archive
            # Save the previous results or otherwise they will be overwritten
            mv ${RESULTS_DIR}/sin-switch ${RESULTS_DIR}/archive/sin-switch.$current_time
            mkdir -p $RESULTS_DIR/sin-switch
        fi

        # Launch the tests remotely and send the results back
        ssh ${USERNAME}@${HOST_A} "cd ${REMOTE_SCRIPTS_DIR} && source settings.sh && sudo ./main.sh" && scp -r ${USERNAME}@${HOST_A}:${REMOTE_RESULTS_DIR}/*/ ${RESULTS_DIR}/sin-switch/
    fi

    # Configuraion #2: Host A - Switch - Host B
    if [ "$configuration" -eq 2  ]; then
        echo ""
        echo "The tests will be run using configuration 2: HA - SW - HB"
        echo "---------------------------------------------------------"
        echo ""
        ssh ${USERNAME}@${SWITCH} "cd ${REMOTE_SCRIPTS_DIR} && /tools/Xilinx/Vitis/2022.2/bin/xsct reference-switch.tcl"
        # Check if the results directory exists
        if [ ! -d "$RESULTS_DIR/con-switch" ]; then
            mkdir -p $RESULTS_DIR/con-switch
        else
            mkdir ${RESULTS_DIR}/archive
            # Save the previous results or otherwise they will be overwritten
            mv ${RESULTS_DIR}/con-switch ${RESULTS_DIR}/archive/con-switch.$current_time
            mkdir -p $RESULTS_DIR/con-switch
        fi

        # Launch the tests remotely and send the results back
        ssh ${USERNAME}@${HOST_A} "cd ${REMOTE_SCRIPTS_DIR} && source settings.sh && sudo ./main.sh" && scp -r ${USERNAME}@${HOST_A}:${REMOTE_RESULTS_DIR}/* ${RESULTS_DIR}/con-switch/
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

