#!/usr/bin/env python3
#
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import time

from robot.api.logger import info

import serial


# Ensure this class gets re-instantiated for every test.
ROBOT_LIBRARY_SCOPE = "TEST"


def OpenSerialPort(device, baudrate, timeout, write_timeout) -> serial.Serial:
    """
    Helper function to open a pyserial device using the given settings.

    Throws an AssertionError if it could not open the given device.
    """
    info(f"OpenSerialPort(dev={device}, baud={baudrate}, timeout={timeout}, wrtimeout={write_timeout}")
    ser = serial.Serial(port=device,
                        timeout=timeout,
                        write_timeout=write_timeout,
                        baudrate=baudrate)
    if not ser.is_open:
        raise AssertionError(f"Could not open {device}!")
    return ser


class FPGALibrary:
    """
    Class to extend the Robot test framework

    Adds Renode-compatible faked keywords as well as serial input and
    output for the various tests.
    """

    # Ensure this class gets re-instantiated for every test.
    ROBOT_LIBRARY_SCOPE = "TEST"

    def __init__(self, *args, **kwargs) -> None:
        """
        Initialize the class library.

        On construction, opens the serial ports for the given FPGA
        board ID. Throws an AssertionError if it fails.

        Arguments expected in kwargs:
          board_id: string. Required. The FPGA board ID to test. Used to
            construct path names to the UARTs.
          timeout: string. The amount of time in seconds to wait in a read
            or write to the serial ports.
        """
        info(f"FPGALibrary installed ({args}, {kwargs})")

        self.board_id = kwargs['board_id']

        self.timeout = None
        if kwargs.get('timeout'):
            self.timeout = float(kwargs['timeout'])
        if kwargs.get('quiesce_delay_seconds'):
            self.quiesce_delay_seconds = float(kwargs['quiesce_delay_seconds'])

        self.smc_uart = f"/dev/Nexus-CP210-FPGA-UART-{self.board_id}"
        self.sc_uart = f"/dev/Nexus-FTDI-{self.board_id}-FPGA-UART"

        self.uarts = {}
        self.default_uart = None

        self.open_serial_ports()

    def _quiesce_input(self, port) -> None:
        """
        Drains a given port of all incoming data.

        Because serial has no actual "end state", it's possible for
        a device to continually send data. The best we can do to sync
        up with the output is delay a second each time we drain to
        really wait for the output to stop.

        Essentially, if no character is sent for at least one second,
        we consider the port to be "quiesced". It's a bad heuristic,
        but since there is no actual command and control protocol,
        this is the best we get for synchronizing I/O to a command
        line.

        Arguments:
          port: serial.Serial instance. The port to drain of data.
        """
        # Loop while there is data available on the port, then delay
        # for a second to make sure we've actually caught all of the
        # incoming data.
        result = ''
        while True:
            info(f"_quiesce_input: port.read({port.in_waiting})")
            result += port.read(port.in_waiting).decode()
            info(f"_quiesce_input: sleep({self.quiesce_delay_seconds})")
            time.sleep(self.quiesce_delay_seconds)
            if port.in_waiting == 0:
                break
        info(f"_quiesce_input read: [{result}]")

    def _write_string_to_uart(self, port, s, wait_for_echo=True) -> None:
        """
        Writes a given string to the given port.

        Throws AssertionError if the echoed back data doesn't match, or a
        read timeout occurs.

        Arguments:
          port: serial.Serial instance. The port to write data to.
          s: string. The string to write to the port.
          wait_for_echo: boolean. Whether or not to wait for echoed
            data back from the port.
        """
        # Flush the write buffers and drain inputs -- might not be
        # needed, but do it anyway to ensure we're synced up.
        port.flush()
        self._quiesce_input(port)

        port.write(s.encode('utf-8'))
        port.flush()
        info(f"wrote [{s}]")

        if wait_for_echo:
            result = port.read(len(s)).decode()
            info(f"read [{result}]")

            # We didn't get the same length string back -- likely caused by a timeout.
            if len(result) < len(s):
                raise AssertionError(
                    "Timeout when reading from UART -- did not read " +
                    f"{s}]({len(result)})! " +
                    f"Got: [{result}]({len(result)})")

            if s != result:
                raise AssertionError(
                    "Write String to UART: Echo back: Did not read " +
                    f"[{s}]({len(result)}) from port! " +
                    f"Got: [{result}]({len(result)})")

    def _write_line_to_uart(self, port, line, wait_for_echo=True) -> None:
        """
        Writes the given string with a newline to the given port.

        Throws AssertionError if the echoed back data doesn't match, or
        a read timeout occurs.

        Arguments:
          port: serial.Serial instance. The port to write data to.
          s: string. The string to write to the port.
          wait_for_echo: boolean. Whether or not to wait for echoed
            data back from the port.
        """
        self._write_string_to_uart(port, line + '\n', wait_for_echo)

    def _wait_for_string_on_uart(self, port, s) -> None:
        """
        Waits until the given string is found in the port buffer.

        Throws AssertionError if a timeout occurs, or if the buffer
        doesn't match up with the string to wait for.

        Arguments:
          port: serial.Serial instance. The port to wait for data from.
          s: string. The string to look for on the port.
        """
        if not port.is_open:
          raise AssertionError(f"Port [{port}] not open!")
        result = port.read_until(expected=s.encode('utf-8')).decode()
        info(f"_wait_for_string_on_uart read: [{result}]({len(result)})")

        # Short read likely resulting from a timeout.
        if len(result) < len(s):
            raise AssertionError(
                f"Timeout while reading on UART: Did not find string [{s}]!")

        if not result.endswith(s):
            raise AssertionError(
                "Wait for String on UART: " +
                f"Did not get string [{s}] from port! Got [{result}]")

    def set_timeout(self, timeout) -> None:
        """
        Sets the read/write timeouts for serial operations.

        Robot keyword. Can be called as Set Timeout.

        Arguments:
          timeout: float. The amount of time in seconds to wait for a
            read or write to complete.
        """
        self.timeout = float(timeout)
        if self.uarts['sc']:
            self.uarts['sc'].timeout = self.timeout
            self.uarts['sc'].write_timeout = self.timeout
        if self.uarts['smc']:
            self.uarts['smc'].timeout = self.timeout
            self.uarts['smc'].write_timeout = self.timeout

    def open_serial_ports(self) -> None:
        """
        Opens the UART ports to the FPGA and sets the default UART.

        For now, sets the default UART to the SMC side only.

        Robot keyword. Can be called as Open Serial Ports.
        """
        self.uarts['sc'] = OpenSerialPort(self.sc_uart,
                                          timeout=self.timeout,
                                          write_timeout=self.timeout,
                                          baudrate=115200)
        self.uarts['smc'] = OpenSerialPort(self.smc_uart,
                                           timeout=self.timeout,
                                           write_timeout=self.timeout,
                                           baudrate=115200)
        self.default_uart = self.uarts['smc']

    def close_serial_ports(self) -> None:
        """
        Closes previously opened UARTs to the FPGA.

        Robot keyword. Can be called as Close Serial Ports.

        Throws AssertionError if it was unable to close a port.
        """
        for name, port in self.uarts.items():
            port.close()
            if port.is_open:
                raise AssertionError(f"Port {name} did not close.")

    def write_line_to_uart(self, line, **kwargs) -> None:
        """
        Writes a given string to the default UART.

        Throws AssertionError if a timeout occurs, or if the echoed back
        characters don't match the given string.

        Robot keyword. Can be called as Write Line To UART.

        Arguments expected in kwargs:
          waitForEcho: boolean. Deafults to True. Whether or not to check
            echoed back characters against the given string.
        """
        if kwargs.get('waitForEcho'):
            self._write_line_to_uart(self.default_uart,
                                     line,
                                     wait_for_echo=kwargs['waitForEcho'])
        else:
            self._write_line_to_uart(self.default_uart, line)

    def wait_for_line_on_uart(self, s, **kwargs) -> None:
        """
        Waits for a given string on the default UART.

        This does not actually look for a newline in the output. The
        name is a misnomer and holdover from Renode terms.

        Throws AssertionError if a timeout occurs, or if the read
        characters don't match the given string.

        Robot keyword. Used as Wait For Line On UART.
        """
        self._wait_for_string_on_uart(self.default_uart, s)

    def wait_for_prompt_on_uart(self, prompt, *args) -> None:
        """
        Waits for the given prompt on the default UART.

        Robot keyword. Can be called as Wait For Prompt On UART.
        """
        self._wait_for_string_on_uart(self.default_uart, prompt)

    def execute_command(self, *args) -> None:
        """Renode-compatible do nothing keyword."""
        info(f"Eliding command `{args}`")

    def execute_script(self, *args) -> None:
        """Renode-compatible do nothing keyword."""
        info(f"Eliding script `{args}`")

    def set_default_uart_timeout(self, timeout, *args) -> None:
        """Renode-compatible do nothing keyword."""
        info(f"Eliding set default uart timeout `{args}`")

    def create_log_tester(self, *args) -> None:
        """Renode-compatible do nothing keyword."""
        info(f"Eliding log tester `{args}`")

    def run_process(self, *args) -> None:
        """Renode-compatible do nothing keyword."""
        info(f"Eliding run process `{args}`")

    def requires(self, *args) -> None:
        """Renode-compatible do nothing keyword."""
        info(f"Eliding requires `{args}`")

    def provides(self, *args) -> None:
        """Renode-compatible do nothing keyword."""
        info(f"Eliding provides `{args}`")

    def start_emulation(self, *args) -> None:
        """Renode-compatible do nothing keyword."""
        info(f"Eliding start emulation `{args}`")

    def create_terminal_tester(self, *args) -> None:
        """Renode-compatible do nothing keyword."""
        info(f"Eliding create terminal tester `{args}`")

    def wait_for_logentry(self, *args) -> None:
        """Renode-compatible do nothing keyword."""
        info(f"Eliding wait for logentry `{args}`")
