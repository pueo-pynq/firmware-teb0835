# Tcl script to create a ZynqMP processor
# for a TE0835 module in a block diagram.


startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.4 zynq_ultra_ps_e_0
endgroup
set_property -dict [list \
  CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
  CONFIG.PSU__DDRC__CL {17} \
  CONFIG.PSU__DDRC__CWL {16} \
  CONFIG.PSU__DDRC__DDR4_T_REF_MODE {0} \
  CONFIG.PSU__DDRC__DEVICE_CAPACITY {8192 MBits} \
  CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
  CONFIG.PSU__DDRC__FGRM {4X} \
  CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16} \
  CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2400P} \
  CONFIG.PSU__DDRC__T_RC {50} \
  CONFIG.PSU__DDRC__T_RCD {50} \
  CONFIG.PSU__DDRC__T_RP {17} \
  CONFIG.PSU__ENET3__GRP_MDIO__ENABLE {1} \
  CONFIG.PSU__ENET3__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__I2C0__PERIPHERAL__IO {MIO 14 .. 15} \
  CONFIG.PSU__I2C1__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__I2C1__PERIPHERAL__IO {MIO 32 .. 33} \
  CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {0} \
  CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__QSPI__PERIPHERAL__MODE {Dual Parallel} \
  CONFIG.PSU__SD1__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__SD1__PERIPHERAL__IO {MIO 46 .. 51} \
  CONFIG.PSU__SD1__SLOT_TYPE {SD 2.0} \
  CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 42 .. 43} \
  CONFIG.PSU__USB0__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__USB0__RESET__ENABLE {1} \
  CONFIG.PSU__USB0__RESET__IO {MIO 37} \
  CONFIG.PSU__USB__RESET__MODE {Separate MIO Pin} \
] [get_bd_cells zynq_ultra_ps_e_0]