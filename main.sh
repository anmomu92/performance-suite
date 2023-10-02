#!/bin/bash

source settings.sh

# We check that there is connectivity with the server
ping -c 1 $SERVER_IP > /dev/null 2>&1 && success=1

# There is connectivity between the hosts
if [ $success -eq 1 ]; then

    # We ask the user which tests they want to perform
    echo ""
    echo "Hello user, it looks like there is connectivity with the host..."
    echo "Now I will ask you which tests you want to run"
    echo "----------------------------------------------"
    echo ""

    # iperf3
    echo "Do you want to run iperf3 tests? (1=yes | 0=no)"
    read -t 10 -p "Enter your input: " test_iperf3

    # Default value
    if [ $? != 0 ]; then
        test_iperf3=1
    fi

    echo ""

    # netperf
    echo "Do you want to run netperf tests? (1=yes | 0=no)"
    read -t 10 -p "Enter your input: " test_netperf

    # Default value
    if [ $? != 0 ]; then
        test_netperf=1
    fi

    echo ""

    # nuttcp
    echo "Do you want to run nuttcp tests? (1=yes | 0=no)"
    read -t 10 -p "Enter your input: " test_nuttcp

    # Default value
    if [ $? != 0 ]; then
        test_nuttcp=1
    fi

    echo ""

    # iperf3
    if [ "$test_iperf3" -eq 1 ]; then

        #echo "$configuration"
        # Check configuration
        #if [ $configuration -eq 1 ]; then
            # Program the switch
            ssh -i "${SSH_KEY_SWITCH}" "${USERNAME}"@"${SWITCH}" "cd ${REMOTE_SCRIPTS_DIR} && /tools/Xilinx/Vitis/2022.2/bin/xsct reference-switch.tcl" 
        #fi

        # Launch the iperf3 server in the prototype
        ssh -i "${SSH_KEY_HOSTB}" "${USERNAME}"@"${HOST_B}" "iperf3 -s -B ${SERVER_IP} &"
        ./throughput-iperf3.sh
    fi

    # netperf
    if [ "$test_netperf" -eq 1 ]; then

        # Check configuration
        #if [ $configuration -eq 1 ]; then
            # Program the switch
            #ssh -i "${SSH_KEY_SWITCH}" "${USERNAME}"@"${SWITCH}" "cd ${REMOTE_SCRIPTS_DIR} && /tools/Xilinx/Vitis/2022.2/bin/xsct reference-switch.tcl" 
        #fi

        # Launch the netperf server in the prototype
        ssh -i ${SSH_KEY_HOSTB} ${USERNAME}@${HOST_B} "netserver"
        ./throughput-netperf.sh
    fi

    # nuttcp
    if [ "$test_nuttcp" -eq 1 ]; then

        # Check configuration
        #if [ $configuration -eq 1 ]; then
            # Program the switch
            #ssh -i "${SSH_KEY_SWITCH}" "${USERNAME}"@"${SWITCH}" "cd ${REMOTE_SCRIPTS_DIR} && /tools/Xilinx/Vitis/2022.2/bin/xsct reference-switch.tcl" 
        #fi

        # Launch the nuttcp server in the prototype
        ssh -i ${SSH_KEY_HOSTB} ${USERNAME}@${HOST_B} "nuttcp -S"
        ./throughput-nuttcp.sh
    fi

# No connectivity
else
	echo "----------------------------------------------"
	echo "| There is no connectivity with the server |"
	echo "----------------------------------------------"
	echo ""
	echo " Check ping against the server is successfull"
	echo ""
fi
