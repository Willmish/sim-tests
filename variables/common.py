from os import environ
from robot.libraries.BuiltIn import BuiltIn

# This variable is set to be 0 by default, and should be overridden on
# the CLI to test debug builds. Ie:
# sim/tests/test.sh --debug sim/tests/shodan_boot.robot
RUN_DEBUG = 0

# This variable is set to be 'release' by default, and should be
# overridden on the CLI to test debug builds. Ie:
# sim/tests/test.sh --debug sim/tests/shodan_boot.robot
# Because we use this variable later in this file we must check to see if
# it was passed, else any changes are only local to this file
_BUILD_TYPE = BuiltIn().get_variable_value("${BUILD_TYPE}")
if _BUILD_TYPE:
  BUILD_TYPE = _BUILD_TYPE
else:
  BUILD_TYPE = 'release'

# Whether or not to wait for echoed back characters and validate those characters.
WAIT_ECHO = True

# How long to wait for a read to time out.
LOG_TIMEOUT = 2

# Default Cantrip prompt string.
PROMPT = 'CANTRIP>'

# The sysbus name for the UART connected to the SMC.
SMC_UART = 'sysbus.uart5'

ROOTDIR  = environ['ROOTDIR']
PLATFORM = environ['PLATFORM']

CANTRIP_OUTDIR = f'{ROOTDIR}/out/cantrip/{PLATFORM}/{BUILD_TYPE}'

SCRIPT             = f'{ROOTDIR}/sim/config/{PLATFORM}.resc'
MATCHA_BUNDLE_PATH = f'{ROOTDIR}/out/matcha-bundle-{BUILD_TYPE}.elf'
CANTRIP_KERNEL     = f'{CANTRIP_OUTDIR}/kernel/kernel.elf'
CANTRIP_ROOTSERVER = f'{CANTRIP_OUTDIR}/capdl-loader'
FLASH_TAR          = f'{CANTRIP_OUTDIR}/ext_flash.tar'
CPIO               = f'{CANTRIP_OUTDIR}/ext_builtins.cpio'
