#!/bin/bash
set -u

if [ ! -d /sys/class/gpio/gpio62/ ]; then
  echo 'Run /home/miniised/start_server.sh script then kill it to expose external SPI GPIO pins'
  exit 1
fi;

echo '# Testing integrity of external SPI communications with MCU by reading sw_version SPI table register'
TOTAL_READ_ATTEMPTS=0
SPI_READ_FAILURES=0
echo "external SPI clock: ${SPI_CLOCK}hz"
echo "expected output: ${EXPECTED_SW_VERSION}"
while [ true ]; do
	READ_ATTEMPTS=0
	VALID_SW_VERSION=true
	while [ "${VALID_SW_VERSION}" != '' ]; do
		TOTAL_READ_ATTEMPTS=$((TOTAL_READ_ATTEMPTS+1))
		READ_ATTEMPTS=$((READ_ATTEMPTS+1))
		echo 0 > /sys/class/gpio/gpio62/value
		SPIDEV_TEST_OUTPUT=`./spidev_test -D /dev/spidev2.0 -b 8 -p "R\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" -v -s ${SPI_CLOCK}`
		echo 1 > /sys/class/gpio/gpio62/value
		VALID_SW_VERSION=`echo $SPIDEV_TEST_OUTPUT | grep ${EXPECTED_SW_VERSION}`
		
		if [ `expr $TOTAL_READ_ATTEMPTS % 1000` = 0 ]; then
			echo "external SPI clock: ${SPI_CLOCK}hz"
			echo "Total sw_version register read attempts: ${TOTAL_READ_ATTEMPTS}"
			echo "Failures to correctly read sw_version register: ${SPI_READ_FAILURES}"
			echo "Failure rate: `echo ${SPI_READ_FAILURES}/${TOTAL_READ_ATTEMPTS} | bc -l`"
		fi
		
		if [ $TOTAL_READ_ATTEMPTS = 10000 ]; then
			exit 0
		fi
	done;
	SPI_READ_FAILURES=$((SPI_READ_FAILURES+1))
	echo 'SPI READ FAILURE!'
	echo "Successful consecutive reads of sw_version register since last failure: $((READ_ATTEMPTS-1))"
	echo -e "RX buffer when it failed:\n${SPIDEV_TEST_OUTPUT:184}"
done;