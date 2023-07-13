#!/bin/bash

# Constants
SERVER_IP=192.168.0.20
CLIENT_IP=192.168.0.10
TESTS=100

# Variables
success=0
qp=0

part_latency_tcp=0
total_latency_tcp=0
avg_latency_tcp=0
part_latency_udp=0
total_latency_udp=0
avg_latency_udp=0

if [ -f "latency.txt" ]; then
	rm latency.txt
fi

# We check that there is connectivity with the server
ping -c 1 $SERVER_IP > /dev/null 2>&1 && success=1
qperf $SERVER_IP tcp_lat > /dev/null 2>&1 && qp=1

if [ $success -eq 1 ] && [ $qp -eq 1 ]
then
# We run the TCP iperf3 test with the default options
	for i in $(seq 1 $TESTS); do
		echo "RUN $i"
		echo "------"
		echo ""

		# Latency for TCP
		result_tcp=$(qperf $SERVER_IP tcp_lat | grep latency)
		part_latency_tcp=$(echo $result_tcp | awk '{print $3}')
		total_latency_tcp=$(echo $total_latency_tcp + $part_latency_tcp | bc)

		# Latency for UDP
		result_udp=$(qperf $SERVER_IP udp_lat | grep latency)
		part_latency_udp=$(echo $result_udp | awk '{print $3}')
		total_latency_udp=$(echo $total_latency_udp + $part_latency_udp | bc)
	done

	# We calculate the average latency for TCP
	echo "-------------"
	echo "TCP - LATENCY"
	echo "-------------"
	avg_latency_tcp=$(echo "scale=3; $total_latency_tcp / $TESTS" | bc -l)
	echo "The average latency for TCP in $TESTS runs is $avg_latency_tcp us"

	echo "$avg_latency_tcp " >> latency.txt

	# We calculate the average latency for UDP
	echo "-------------"
	echo "UDP - LATENCY"
	echo "-------------"
	avg_latency_udp=$(echo "scale=3; $total_latency_udp / $TESTS" | bc -l)
	echo "The average latency for UDP in $TESTS runs is $avg_latency_udp us"

	echo "$avg_latency_udp " >> latency.txt

else
	echo "---------------------------------"
	echo "El servidor qperf no esta activo"
	echo "---------------------------------"
	echo ""
	echo "* Para activarlo, ejecuta el comando 'qperf' en el servidor y asegurese de que hay conexion haciendo ping"
	echo ""
fi

