from pynq import Overlay, GPIO, MMIO
import time
import os
import subprocess
import tebrfclk
import numpy as np

class tebMTS(Overlay):
    def __init__(self, bitfile_name='teb0835_top.bit', reload=False, **kwargs):
        output = subprocess.check_output(['lsmod'])
        if b'zocl' in output:
            if reload == False:
                rmmod_output = subprocess.run(['rmmod', 'zocl'])
                assert rmmod_output.returncode == 0, "Could not restart zocl. Please Shutdown All Kernels and then restart"
                modprobe_output = subprocess.run(['modprobe','zocl'])
                assert modprobe_output.returncode == 0, "Could not restart zocl. It did not restart as expected"
        else:
            modprobe_output = subprocess.run(['modprobe','zocl'])
            assert modprobe_output.returncode == 0, "Could not restart ZOCL!"

        tebrfclk.set_rf_clks('Si5395-RevA-B835PUEO-Registers.txt')

        self.gpio_trig = GPIO(GPIO.get_gpio_pin(0), 'out')
        self.gpio_done = [ GPIO(GPIO.get_gpio_pin(8), 'in'),
                           GPIO(GPIO.get_gpio_pin(9), 'in'),
                           GPIO(GPIO.get_gpio_pin(10), 'in'),
                           GPIO(GPIO.get_gpio_pin(11), 'in'),
                           GPIO(GPIO.get_gpio_pin(12), 'in'),
                           GPIO(GPIO.get_gpio_pin(13), 'in'),
                           GPIO(GPIO.get_gpio_pin(14), 'in'),
                           GPIO(GPIO.get_gpio_pin(15), 'in') ]

        super().__init__(resolve_binary_path(bitfile_name), **kwargs)

        self.dbg = self.debug_bridge_0
        # DON'T ACCESS THESE DIRECTLY THE MEMVIEWS ARE KER-EFFED
        self.adcmem = [ self.memdict_to_view("adc_cap_0/axi_bram_ctrl_0"),
                        self.memdict_to_view("adc_cap_1/axi_bram_ctrl_0"),
                        self.memdict_to_view("adc_cap_2/axi_bram_ctrl_0"),
                        self.memdict_to_view("adc_cap_3/axi_bram_ctrl_0") ]
        
    def memdict_to_view(self, ip, dtype='int16'):
        """ Configures access to internal memory via MMIO"""
        baseAddress = self.mem_dict[ip]["phys_addr"]
        mem_range = self.mem_dict[ip]["addr_range"]
        ipmmio = MMIO(baseAddress, mem_range)
        # this is WRONG how the hell did this work
        return ipmmio.array[0:ipmmio.length].view(dtype)
    
    # pointless
    def verify_clock_tree(self):
        return True

    # THIS DOES NOTHING FOR NOW
    def sync_tiles(self, dacTarget=-1, adcTarget=-1):
        return

    # THIS DOES NOTHING FOR NOW
    def init_tile_sync(self):
        return
        
    # the default here is 3 to match the MTS workbooks
    def internal_capture(self, buf, num_chan=3):
        if not np.issubdtype(buf.dtype, np.int16):
            raise Exception("buffer not defined or np.int16")
        if not buf.shape[0] == num_chan:
            raise Exception("buffer must be of shape(num_chan, N)!")
        
        self.gpio_trig.write(1)
        self.gpio_trig.write(0)
        for i in range(num_chan):
            buf[i] = np.copy(self.adcmem[i][0:len(buf[i])])
            
        
def resolve_binary_path(bitfile_name):
    """ this helper function is necessary to locate the bit file during overlay loading"""
    if os.path.isfile(bitfile_name):
        return bitfile_name
    elif os.path.isfile(os.path.join(MODULE_PATH, bitfile_name)):
        return os.path.join(MODULE_PATH, bitfile_name)
    else:
        raise FileNotFoundError(f'Cannot find {bitfile_name}.')
    


