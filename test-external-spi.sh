#!/bin/bash
set -u

EXTERNAL_SPI_INTERFACE='/dev/spidev2.0'
EXTERNAL_SPI_CS_PIN='/sys/class/gpio/gpio62'

if [[ ! -e ${EXTERNAL_SPI_INTERFACE} ]]; then 
	echo "ERROR: ${EXTERNAL_SPI_INTERFACE} not found!  Check DTBs installed to /dev/mmcblk2p1"
	exit 1
fi

if [[ ! -e ${EXTERNAL_SPI_CS_PIN} ]]; then
	echo "ERROR: ${EXTERNAL_SPI_CS_PIN} not found! Exporting GPIO pin 62 and setting pin 62 direction to out."
	echo 62 > /sys/class/gpio/export
	# set direction of GPIO pin
	echo 'out' > ${EXTERNAL_SPI_CS_PIN}/direction

	echo 'Please re-run script.'
	exit 1
fi

echo '# Testing integrity of external SPI communications with MCU by reading sw_version SPI table register'
TOTAL_READ_ATTEMPTS=0
SPI_READ_FAILURES=0
echo "external SPI clock: ${SPI_CLOCK} hz"
echo "expected output: ${EXPECTED_SW_VERSION}"
while [ true ]; do
	READ_ATTEMPTS=0
	VALID_SW_VERSION=true
	while [ "${VALID_SW_VERSION}" != '' ]; do
		TOTAL_READ_ATTEMPTS=$((TOTAL_READ_ATTEMPTS+1))
		READ_ATTEMPTS=$((READ_ATTEMPTS+1))
		echo 0 > ${EXTERNAL_SPI_CS_PIN}/value
		SPIDEV_TEST_OUTPUT=`./spidev_test -D ${EXTERNAL_SPI_INTERFACE} -b 8 -p "R\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" -v -s ${SPI_CLOCK}`
		echo 1 > ${EXTERNAL_SPI_CS_PIN}/value
		VALID_SW_VERSION=`echo ${SPIDEV_TEST_OUTPUT} | grep ${EXPECTED_SW_VERSION}`
		
		if [ `expr $TOTAL_READ_ATTEMPTS % 1000` = 0 ]; then
			echo "external SPI clock: ${SPI_CLOCK} hz"
			echo "Total sw_version register read attempts: ${TOTAL_READ_ATTEMPTS}"
			echo "Failures to correctly read sw_version register: ${SPI_READ_FAILURES}"
			printf "Failure rate: %.4f\n" $((10**4 * ${SPI_READ_FAILURES}/${TOTAL_READ_ATTEMPTS}))e-4
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