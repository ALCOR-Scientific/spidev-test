#!/bin/bash
set -u

if [ ! -d /sys/class/gpio/gpio62/ ]; then
  echo "Run /home/`whoami`/start_server.sh script then kill it to expose external SPI GPIO pins"
  exit 1
fi;

echo "# Testing time to do ${NUM_BENCHMARK_SPI_READS} reads of sw_version SPI table register"
TOTAL_READ_ATTEMPTS=0
echo "external SPI clock: ${SPI_CLOCK} hz"
while [ true ]; do
	while [ ${TOTAL_READ_ATTEMPTS} != ${NUM_BENCHMARK_SPI_READS} ]; do
		TOTAL_READ_ATTEMPTS=$((TOTAL_READ_ATTEMPTS+1))
		echo 0 > /sys/class/gpio/gpio62/value
		SPIDEV_TEST_OUTPUT=`./spidev_test -D /dev/spidev2.0 -b 8 -p "R\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" -v -s ${SPI_CLOCK}`
		echo 1 > /sys/class/gpio/gpio62/value
		
		if [ $TOTAL_READ_ATTEMPTS = ${NUM_BENCHMARK_SPI_READS} ]; then
			exit 0
		fi
	done;
done;