  
  // JK: this requires custom MIZAR1 FW with these lines in external_SPI_DRIVER.c's spi_initTable(void) function:
  // int i = 0;
  // while (i < 12000) {
  //     kineticBuffer[i] = i;
  //     i++;
  // }

  // add code below to lib/robotics/<instrument>/index.js here:
  
  // Initialize node access to linux system interfaces
  Server.initInterfaces(ibcrConfigureCallback)
  
  let totalSpiReads = 0;
  let spiReadFailures = 0;
  while (true) {
    let currentSpiReadAttempts = 0;
	  let validKineticBufferReading = true;

    while (validKineticBufferReading === true) {
      totalSpiReads++;
      currentSpiReadAttempts++;

      let kineticBuffer = Server.transferSync('read', 'kineticBuffer')

      let adcBufferValues = [];
      for (let i = 0; i < 12000; i += 2) {
        let adcBufferValue = (kineticBuffer[i + 1] * 256) + kineticBuffer[i];
        adcBufferValues.push(adcBufferValue);
      }

      for (let i = 0; i < 6000; i++) {
        if (adcBufferValues[i] != i) {
          console.log('SPI READ FAILURE!')
          console.log('Successful consecutive reads of sw_version register since last failure:', currentSpiReadAttempts)
          console.log('i:', i, 'adcBufferValues[i]:', adcBufferValues[i])
          spiReadFailures++
          validKineticBufferReading = false;
          break;
        }
      }

      if (totalSpiReads % 1000 === 0) {
        console.log('external SPI clock: 1,500,000 hz');
        console.log('Total kineticBuffer register read attempts:', totalSpiReads)
        console.log('Failures to correctly read sw_version register:', spiReadFailures)
        console.log('Failure rate: ', spiReadFailures/totalSpiReads)
      }
    }
  }