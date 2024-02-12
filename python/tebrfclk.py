# programming clock on TEB0835
# This uses pyelectronics, but the fork at
# https://github.com/barawn/pyElectronics

from electronics.gateways import LinuxDevice
from electronics.devices import Si5395

def set_rf_clks(filename='Si5395-RevA-B835PUEO-Registers.txt'):
    gw = LinuxDevice(5)
    clock = Si5395(gw, 0x68)
    clock.loadconfig(filename)
    clock.status()
    
