  
  // add code below to lib/robotics/<instrument>/index.js here:

  // Initialize node access to linux system interfaces
  Server.initInterfaces(ibcrConfigureCallback)
  
  let totalSpiReads = 0;
  let spiReadFailures = 0;
  while (true) {
    let currentSpiReadAttempts = 0;
	  let validSoftwareVersion = true;

    while (validSoftwareVersion === true) {
      totalSpiReads++;
      currentSpiReadAttempts++;

      let swVersion = Server.transferSync('read', 'sw_version')
      if (swVersion !== 'RBT0100H') {
        console.log('SPI READ FAILURE!')
        console.log('Successful consecutive reads of sw_version register since last failure:', currentSpiReadAttempts)
        console.log('RX buffer when it failed:', swVersion)

        validSoftwareVersion = false;
        spiReadFailures++;
      }

      if (totalSpiReads % 10000 === 0) {
        console.log('external SPI clock: 2,000,000 hz');
        console.log('Total sw_version register read attempts:', totalSpiReads)
        console.log('Failures to correctly read sw_version register:', spiReadFailures)
        console.log('Failure rate: ', spiReadFailures/totalSpiReads)
      }
    }
  }