from common import *

# Override the common LOG_TIMEOUT, since the FPGA is slower.
LOG_TIMEOUT = 60

# This variable is set to be 0 for renode tests, and should be
# overridden on CLI to test on the FPGA. Ie:
# sim/tests/fpga_test.sh 02 sim/tests/shodan_boot.robot
FPGA_BOARD_ID = 0

# Tunable. Can be overridden, but this is the default number of seconds
# to wait between quiesce reads. Essentially, if we don't have any data
# on the UART within this time, we consider the UART to be "quiesced"
# and can then proceed with doing writes and readbacks.
FPGA_QUIESCE_DELAY_SECONDS = 1

