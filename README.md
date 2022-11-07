# spidev-test

A copy of https://github.com/torvalds/linux/blob/master/tools/spi/spidev_test.c
(becasue I can never find it when I need it), with the following changes:

 * The default device was changed from `/dev/spidev1.1` to `/dev/spidev0.0`
 * The SPI modes were changed from `SPI_IOC_WR_MODE32` and `SPI_IOC_RD_MODE32` to
   `SPI_IOC_WR_MODE` and `SPI_IOC_RD_MODE` respectively.

**Forked by Jason Klas on 11/7/22 to the Alcor-Scientific organization.**

## What is this for?

If you are experiencing issues with the [SPI](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus)
bus on Raspberry Pi or other Linux-based single-board computers, this program
(plus a single jumper or wire) will confirm whether SPI is working properly.

## Building on miniiSED

Download the code from github and compile with:

    $ git clone https://github.com/rm-hull/spidev-test
    $ cd spidev-test
    $ gcc spidev_test.c -o spidev_test

## Enabling external SPI on the miniiSED

You need to have a DTB file (`imx7d-sbc-imx7.dts` by default) installed in `/dev/mmcblk2p1` that wires up ecSPI3 as following:

```
&ecspi3 {
	fsl,spi-num-chipselects = <1>;
	pinctrl-names = "default";
	pinctrl-0 = <&pinctrl_ecspi3 &pinctrl_ecspi3_cs>;
	cs-gpios = <&gpio4 11 0>;
	status = "okay";

	spidev@0 {
		reg = <0x0>;
		compatible = "rohm,dh2228fv", "spidev";
		spi-max-frequency = <10000000>;
	};
};

&iomuxc {
	pinctrl-names = "default";

    ...

	pinctrl_ecspi3: ecspi3grp {
		fsl,pins = <
			MX7D_PAD_I2C1_SDA__ECSPI3_MOSI          0xf /* P7-7 */
			MX7D_PAD_I2C1_SCL__ECSPI3_MISO          0xf /* P7-8 */
			MX7D_PAD_I2C2_SCL__ECSPI3_SCLK          0xf /* P7-6 */
		>;
	};

	pinctrl_ecspi3_cs: ecspi3_cs_grp {
		fsl,pins = <
			MX7D_PAD_I2C2_SDA__GPIO4_IO11           0x34 /* P7-9 */
		>;
	};
```

You also need a `zImage` Linux kernel installed in `/dev/mmcblk2p1` built with these configuration options:

```
CONFIG_SPI=y
CONFIG_SPI_IMX=y
CONFIG_SPI_SPIDEV=y
```

## Testing the external SPI bus

You need to run the server code to expose the CS GPIO pin for the `benchmark-external-spi.sh` and `test-external-spi.sh` scripts to work.

To test integrity of the external SPI bus, `cd` into this repo:

```bash
export EXPECTED_SW_VERSION=RBT0100H
export SPI_CLOCK=500000
time bash ./test-external-spi.sh
```

To test the speed of reading the external SPI bus, `cd` into this repo:

```bash
export NUM_BENCHMARK_SPI_READS=10000
export SPI_CLOCK=500000
time bash ./benchmark-external-spi.sh
```

## Interpretting the results

With the MOSI _(master out, slave in)_ pin connected to the MISO _(master in,
slave out)_, the received data should be exactly the same as the transmitted data,
as in the above example.

If received data is all zero as below:

    $ ./spidev_test -v
    spi mode: 0x0
    bits per word: 8
    max speed: 500000 Hz (500 KHz)
    TX | FF FF FF FF FF FF 40 00 00 00 00 95 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF F0 0D  | ......@....?..................?.
    RX | 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  | ................................

This implies the pins MOSI and MISO aren't connected.

## Program options

Use the `-?` flag to show all the available options:

    $ ./spidev_test -?
    usage: ./spidev_test [-DsbdlHOLC3]
    -D --device   device to use (default /dev/spidev1.1)
    -s --speed    max speed (Hz)
    -d --delay    delay (usec)
    -b --bpw      bits per word
    -i --input    input data from a file (e.g. "test.bin")
    -o --output   output data to a file (e.g. "results.bin")
    -l --loop     loopback
    -H --cpha     clock phase
    -O --cpol     clock polarity
    -L --lsb      least significant bit first
    -C --cs-high  chip select active high
    -3 --3wire    SI/SO signals shared
    -v --verbose  Verbose (show tx buffer)
    -p            Send data (e.g. "1234\xde\xad")
    -N --no-cs    no chip select
    -R --ready    slave pulls low to pause
    -2 --dual     dual transfer
    -4 --quad     quad transfer
