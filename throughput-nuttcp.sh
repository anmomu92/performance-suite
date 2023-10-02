#/bin/bash

source settings.sh

# Variables
TEST_NAME="nuttcp"
nuttcp=0

# Create results directory if it doesn't exist
if [ ! -d "../results/${TEST_NAME}" ]; then
	mkdir -p ../results/${TEST_NAME}
fi

# Create logs directory if it doesn't exist
if [ ! -d "../logs/${TEST_NAME}" ]; then
	mkdir -p ../logs/${TEST_NAME}
fi

# Print the test name
echo "----------------------------------------------------------  NUTTCP ----------------------------------------------------------"

# Check that there is connectivity with the server
nuttcp -i1 -T 2 $SERVER_IP > /dev/null 2>&1 && nuttcp=1

# Server is running
if [ $nuttcp -eq 1 ]; then

    for buffer in "${buffer_size[@]}"; do # buffer

        ##########################################################################
        # Set kernel buffer
        ##########################################################################
        echo ""
        echo "Setting the size of the kernel buffer"
        echo "-------------------------------------"

        # Convert the B in KB for better readability
        buffer_in_bytes=$(($buffer * 1024))

        rb_default="net.core.rmem_default"
        rb_max="net.core.rmem_max"

        wb_default="net.core.wmem_default"
        wb_max="net.core.wmem_max"

        sysctl -w "$rb_default"=$buffer_in_bytes
        sysctl -w "$rb_max"=$buffer_in_bytes

        sysctl -w "$wb_default"=$buffer_in_bytes
        sysctl -w "$wb_max"=$buffer_in_bytes

        echo ""
        echo "Kernel buffer size set to $buffer KB"

        ##########################################################################
        # nuttcp TCP test
        ##########################################################################
        echo ""
        echo "----------------------------------------"
        echo "| TCP - NUTTCP - BUFFER SIZE: $buffer KB |"
        echo "----------------------------------------"

        # Initialize the variables
        total_latency_tcp=0
        total_bitrate_tcp=0
        total_retransmissions_tcp=0

        for i in $(seq 1 $TESTS); do # TCP 50 runs

            # Save the output as a log file and extract the last line to get the results
            echo "nuttcp -i1 -T ${TEST_DURATION} $SERVER_IP" >> ../logs/${TEST_NAME}/${TEST_NAME}-tcp-log-${buffer}.txt
            nuttcp -i1 -T ${TEST_DURATION} $SERVER_IP >> ../logs/${TEST_NAME}/${TEST_NAME}-tcp-log-${buffer}.txt
            echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/${TEST_NAME}-tcp-log-${buffer}.txt
            echo "" >> ../logs/${TEST_NAME}/${TEST_NAME}-tcp-log-${buffer}.txt
            
            # Retrieve the output line with the data
            nuttcp_result_tcp=$(tail -1 ../logs/${TEST_NAME}/${TEST_NAME}-tcp-log-${buffer}.txt)

            ##########################################################################
            # Transfered bytes
            ##########################################################################
            part_transfer_tcp=$(echo $nuttcp_result_tcp | awk '{print $1}')
            units_transfer_tcp=$(echo $nuttcp_result_tcp | awk '{print $2}')
                total_transfer_tcp=$(echo $total_transfer_tcp + $part_transfer_tcp | bc)

            ##########################################################################
            # Throughput
            ##########################################################################
            part_bitrate_tcp=$(echo $nuttcp_result_tcp | awk '{print $7}')
            units_bitrate_tcp=$(echo $nuttcp_result_tcp | awk '{print $8}')
            total_bitrate_tcp=$(echo $total_bitrate_tcp + $part_bitrate_tcp | bc)

            # We check that, in case of error, no string is passed to the variable
            if [[ ! $part_bitrate_tcp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                part_bitrate_tcp=0
            fi

            # Save individual runs for boxplots
            echo "$part_bitrate_tcp " >> ../results/${TEST_NAME}/${TEST_NAME}-tcp-box-plot-${buffer}.txt


            ##########################################################################
            # Retransmissions
            ##########################################################################
            part_retransmissions_tcp=$(echo $nuttcp_result_tcp | awk '{print $13}')
            total_retransmissions_tcp=$(echo $total_retransmissions_tcp + $part_retransmissions_tcp | bc)

            # We check that, in case of error, no string is passed to the variable
            if [[ ! $part_retransmissions_tcp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                part_retransmissions_tcp=0
            fi

            ##########################################################################
            # Round-Trip Time
            ##########################################################################
            part_latency_tcp=$(echo $nuttcp_result_tcp | awk '{print $15}')
            units_latency_tcp=$(echo $nuttcp_result_tcp | awk '{print $16}')
            total_latency_tcp=$(echo $total_latency_tcp + $part_latency_tcp | bc)

            # We check that, in case of error, no string is passed to the variable
            if [[ ! $part_latency_tcp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                part_latency_tcp=0
            fi

            # Print summary of the run
            echo "${TEST_NAME} TCP RUN: $i ($buffer KB) - Partial transfer: $part_transfer_tcp $units_transfer_tcp - Partial throughput: $part_bitrate_tcp $units_bitrate_tcp - Partial retransmissions: $part_retransmissions_tcp - Partial RTT: $part_latency_tcp $units_latency_tcp"
        done # TCP 50 runs
        
        echo ""
        echo "-----------------------------------------------"

        # Calculate the average transfered bytes for TCP
        avg_transfer_tcp=$(echo "scale=3; $total_transfer_tcp / $TESTS" | bc -l)
        echo "The average transfer for TCP in $TESTS runs is $avg_transfer_tcp $units_transfer_tcp"
        echo "# The average transfer after $TESTS runs is the following: " >> ../results/${TEST_NAME}/${TEST_NAME}-tcp-transfer-${buffer}.txt
        echo "$avg_transfer_tcp" >> ../results/${TEST_NAME}/${TEST_NAME}-tcp-transfer-${buffer}.txt
        
        # Calculate the average throughput for TCP
        avg_bitrate_tcp=$(echo "scale=3; $total_bitrate_tcp / $TESTS" | bc -l)
        echo "The average bitrate for TCP in $TESTS runs is $avg_bitrate_tcp $units_bitrate_tcp"
        echo "# The average throughput after $TESTS runs is the following: " >> ../results/${TEST_NAME}/${TEST_NAME}-tcp-throughput-${buffer}.txt
        echo "$avg_bitrate_tcp" >> ../results/${TEST_NAME}/${TEST_NAME}-tcp-throughput-${buffer}.txt

        # Calculate the average retransmissions for TCP
        avg_retransmissions_tcp=$(echo "scale=3; $total_retransmissions_tcp / $TESTS" | bc -l)
        echo "The average retransmissions for TCP in $TESTS runs is $avg_retransmissions_tcp"
        echo "# The average number of retransmissions after $TESTS runs is the following: " >> ../results/${TEST_NAME}/${TEST_NAME}-tcp-retransmissions-${buffer}.txt
        echo "$avg_retransmissions_tcp" >> ../results/${TEST_NAME}/${TEST_NAME}-tcp-retransmissions-${buffer}.txt

        # Calculate the average latency for TCP
        avg_latency_tcp=$(echo "scale=3; $total_latency_tcp / $TESTS" | bc -l)
        echo "The average latency for TCP in $TESTS runs is $avg_latency_tcp $units_latency_tcp"
        echo "# The average latency after $TESTS runs is the following: " >> ../results/${TEST_NAME}/${TEST_NAME}-tcp-latency-${buffer}.txt
        echo "$avg_latency_tcp" >> ../results/${TEST_NAME}/${TEST_NAME}-tcp-latency-${buffer}.txt


        ##########################################################################
        # nuttcp TCP test
        ##########################################################################
        echo ""
        echo "----------------------------------------"
        echo "| UDP - NUTTCP - BUFFER SIZE: $buffer KB |"
        echo "----------------------------------------"

        for bitrate in "${injection_bitrate[@]}"; do # bitrate

            echo ""
            echo "Injection bitrate set to $bitrate Mbps"
            echo "-----------------------------------------"
            echo "Injection bitrate set to $bitrate" >> ../logs/${TEST_NAME}/${TEST_NAME}-udp-log-${buffer}.txt

            # THE VERSION INSTALLED IN THE PROTOYPE DOES NOT SUPPORT BURSTS, SO IT IS COMMENTED OUT
            #for burst in "${packet_burst[@]}"; do
            #  echo "Packet burst set to $burst"
            #  echo "Packet burst set to $burst" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
            echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/${TEST_NAME}-udp-log-${buffer}.txt
            echo "INJ BITRATE: $bitrate - BUFFER SIZE: $buffer" >> ../results/${TEST_NAME}/${TEST_NAME}-udp-throughput-${buffer}.txt
            echo "INJ BITRATE: $bitrate - BUFFER SIZE: $buffer" >> ../results/${TEST_NAME}/${TEST_NAME}-udp-error-${buffer}.txt

            # We initialize the variables
            total_transfer_udp=0
            total_bitrate_udp=0
            total_loss_udp=0

            for i in $(seq 1 $TESTS); do # 50 runs
                echo "RUN: $i INJ BITRATE: $bitrate BUFFER SIZE: $buffer" >> ../logs/${TEST_NAME}/${TEST_NAME}-udp-log-${buffer}.txt

                # We save the output as a log file and extract the last line to get the results
                echo "nuttcp -u -Ri${bitrate}m -i 1 -T ${TEST_DURATION} ${SERVER_IP}" >> ../logs/${TEST_NAME}/${TEST_NAME}-udp-log-${buffer}.txt
                nuttcp -u -Ri${bitrate}m -i 1 -T ${TEST_DURATION} ${SERVER_IP} >> ../logs/${TEST_NAME}/${TEST_NAME}-udp-log-${buffer}.txt
                nuttcp_result_udp=$(tail -1 ../logs/${TEST_NAME}/${TEST_NAME}-udp-log-${buffer}.txt)

                echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/${TEST_NAME}-udp-log-${buffer}.txt
                echo "" >> ../logs/${TEST_NAME}/${TEST_NAME}-udp-log-${buffer}.txt

                ##########################################################################
                # Transfered bytes
                ##########################################################################
                part_transfer_udp=$(echo $nuttcp_result_udp | awk '{print $1}')
                units_transfer_udp=$(echo $nuttcp_result_udp | awk '{print $2}')
                total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

                # Check that, in case of error, no string is passed to the variable
                if [[ ! $part_transfer_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    part_transfer_udp=0
                fi

                ##########################################################################
                # Throughput
                ##########################################################################
                part_bitrate_udp=$(echo $nuttcp_result_udp | awk '{print $7}')
                units_bitrate_udp=$(echo $nuttcp_result_udp | awk '{print $8}')
                total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

                # Check that, in case of error, no string is passed to the variable
                if [[ ! $part_bitrate_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    part_bitrate_udp=0
                fi

                # Save throughput to boxplot file
                echo "$part_bitrate_udp " >> ../results/${TEST_NAME}/${TEST_NAME}-udp-box-plot-${buffer}-${bitrate}.txt

                ##########################################################################
                # Errors 
                ##########################################################################
                part_loss_udp=$(echo $nuttcp_result_udp | awk '{print $17}')
                part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
                total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

                # Check that, in case of error, no string is passed to the variable
                if [[ ! $part_loss_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    part_loss_udp=0
                fi

                echo "${TEST_NAME} UDP RUN: $i - Partial transfer: $part_transfer_udp $units_transfer_udp - Partial throughput: $part_bitrate_udp $units_bitrate_udp - Partial error: $part_loss_udp"
            done # UDP 50 runs

            echo ""
            echo "-----------------------------------------------"

            # Calculate the average UDP transfer
            avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
            echo "The average transfer for UDP in $TESTS runs and injection bitrate of $bitrate Mbps is $avg_transfer_udp $units_transfer_udp"
            echo "$bitrate $avg_transfer_udp" >> ../results/${TEST_NAME}/${TEST_NAME}-udp-transfer-${buffer}.txt

            # Calculate the average throughput for UDP 
            avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
            echo "The average throughput for UDP in $TESTS runs, injection bitrate of $bitrate Mbps and a packet burst of $burst packets is $avg_bitrate_udp $units_bitrate_udp"
            echo "$bitrate $avg_bitrate_udp" >> ../results/${TEST_NAME}/${TEST_NAME}-udp-throughput-${buffer}.txt

            # Calculate the average errors for UDP 
            avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
            echo "The average errors for UDP in $TESTS runs, injection bitrate of $bitrate Mbps and a packet burst of $burst packets is $avg_loss_udp %"
            echo "$bitrate $avg_loss_udp" >> ../results/${TEST_NAME}/${TEST_NAME}-udp-error-${buffer}.txt
            echo ""

        done # bitrate
	done # buffer
else
	echo "---------------------------------"
	echo " The nuttcp server is not active"
	echo "---------------------------------"
	echo ""
	echo "* In order to activate it, run 'nuttcp -S' in the server side"
	echo ""
fi

