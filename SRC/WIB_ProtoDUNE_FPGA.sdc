
# Clock constraints
#set altera_reserved_tck { altera_reserved_tck }
#
#
#create_clock -period 20.00 -name clkin_50  [ get_ports CLK_IN_50MHz ]
#create_clock -period 8.0   -name SFP_CLK_125MHz  [ get_ports SFP_CLK]
#
#create_clock -period 8.0   -name refclk1_125MHz  [ get_ports refclk1]
#create_clock -period 8.0   -name refclk2_125MHz  [ get_ports refclk2]
#create_clock -period 8.0   -name refclk3_125MHz  [ get_ports refclk3]
#
#create_clock -period 100.0   -name tst_pulse  [ get_ports LEMO_IN2]
#create_clock -name SFL_CLK -period 50.000 [get_registers {AV_sfl_epcq:AV_sfl_epcq_inst|CLK_CNT[2]}]
# set_clock_groups \
#    -exclusive \
#    -group [get_clocks {clkin_50}] \
#
#
#
## Automatically constrain PLL and other generated clocks
#derive_pll_clocks -create_base_clocks
#
## Automatically calculate clock uncertainty to jitter and other effects.
#derive_clock_uncertainty




# tsu/th constraints

# tco constraints

# tpd constraints

#-----------------------new clock constraints--------------#
set altera_reserved_tck { altera_reserved_tck }

create_clock -name clkin_50 -period 20.00 [get_ports CLK_IN_50MHz]

create_clock -name FEMB_GXB_refclk_L -period 7.8125 [get_ports refclk_L1]
create_clock -name FEMB_GXB_refclk_R -period 7.8125 [get_ports refclk_R0]

create_clock -name FELIX_PCS_refclk  -period 8.317  [get_ports refclk_L0]
create_clock -name SFP_CLK_125MHz    -period 8.000  [get_ports refclk_L3]
create_clock -name ProtoDUNE_CLK_100MHz -period 10.00 [get_ports ProtoDUNE_CLK]
#-------unconstrained clocks--------#
#create_clock -period 100.0   -name tst_pulse  [ get_ports LEMO_IN2]
#create_clock -name SFL_CLK -period 50.000 [get_registers {AV_sfl_epcq:AV_sfl_epcq_inst|CLK_CNT[2]}]

#generated pll clocks
create_generated_clock -name clk_40MHz -source {SYS_PLL_WIB_inst|sys_pll_wib_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|vco1ph[0]} -divide_by 10 -multiply_by 1 -duty_cycle 50.00 { SYS_PLL_WIB_inst|sys_pll_wib_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk }
create_generated_clock -name clk_50MHz -source {SYS_PLL_WIB_inst|sys_pll_wib_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|vco1ph[0]} -divide_by 8 -multiply_by 1 -duty_cycle 50.00 { SYS_PLL_WIB_inst|sys_pll_wib_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk }
create_generated_clock -name clk_100MHz -source {SYS_PLL_WIB_inst|sys_pll_wib_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco1ph[0]} -divide_by 4 -multiply_by 1 -duty_cycle 50.00 { SYS_PLL_WIB_inst|sys_pll_wib_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk }

create_generated_clock -name GXB_1  -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:0:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:0:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_2  -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:0:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:0:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_3  -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:0:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:0:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_4  -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:0:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:0:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_5  -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:1:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:1:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_6  -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:1:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:1:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_7  -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:1:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:1:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_8  -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:1:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:1:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_9  -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:2:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:2:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_10 -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:2:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:2:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_11 -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:2:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:2:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_12 -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:2:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:2:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_13 -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:3:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:3:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_14 -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:3:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:3:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_15 -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:3:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:3:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }
create_generated_clock -name GXB_16 -source {ProtoDUNE_FEMB_HSRX_inst|\CHK_1:3:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_rx_pcs_pma_interface|wys|clockoutto8gpcs} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { ProtoDUNE_FEMB_HSRX_inst|\CHK_1:3:ProtoDUNE_4_HSRX_inst1|GXB_RX_INST1|gxb_4_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma }

#FELIX clock
create_generated_clock -name felix_pcs_clk1 -source {FELIX_EventBuilder_inst|FELIX_PCS_inst|FELIX_LINK_1|felix_link_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pma|av_tx_pma|tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.tx_cgb|clkcdr1t} -divide_by 40 -multiply_by 1 -duty_cycle 50.00 { FELIX_EventBuilder_inst|FELIX_PCS_inst|FELIX_LINK_1|felix_link_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pma|av_tx_pma|tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.tx_cgb|pclk[2] }
create_generated_clock -name felix_pcs_clk2 -source {FELIX_EventBuilder_inst|FELIX_PCS_inst|FELIX_LINK_1|felix_link_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pma|av_tx_pma|tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.tx_cgb|clkcdrloc} -divide_by 40 -multiply_by 1 -duty_cycle 50.00 { FELIX_EventBuilder_inst|FELIX_PCS_inst|FELIX_LINK_1|felix_link_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pma|av_tx_pma|tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.tx_cgb|pclk[2] }
#create_generated_clock -name felix_event_clk1 -source {FELIX_EventBuilder_inst|\ProtoDUNE_PACK:0:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco1ph[0]} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { FELIX_EventBuilder_inst|\ProtoDUNE_PACK:0:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk }
#create_generated_clock -name felix_event_clk2 -source {FELIX_EventBuilder_inst|\ProtoDUNE_PACK:1:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { FELIX_EventBuilder_inst|\ProtoDUNE_PACK:1:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk }
#create_generated_clock -name felix_event_clk1 -source {FELIX_EventBuilder_inst|\ProtoDUNE_PACK:0:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { FELIX_EventBuilder_inst|\ProtoDUNE_PACK:0:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk }
#create_generated_clock -name felix_event_clk2 -source {FELIX_EventBuilder_inst|\ProtoDUNE_PACK:1:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco1ph[0]} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { FELIX_EventBuilder_inst|\ProtoDUNE_PACK:1:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk }
create_generated_clock -name felix_event_clk1 -source {FELIX_EventBuilder_inst|\ProtoDUNE_PACK:0:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco1ph[0]} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { FELIX_EventBuilder_inst|\ProtoDUNE_PACK:0:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk }
create_generated_clock -name felix_event_clk2 -source {FELIX_EventBuilder_inst|\ProtoDUNE_PACK:1:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 2 -multiply_by 1 -duty_cycle 50.00 { FELIX_EventBuilder_inst|\ProtoDUNE_PACK:1:FELIX_EventBuilder_Link_inst|felix_clk|felix_240m_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk }
set_clock_groups \
	 -exclusive \
	 -group [get_clocks {clkin_50}] \
	 -group [get_clocks {SFP_CLK_125MHz}] \
	 -group [get_clocks {FEMB_GXB_refclk_L}] \
	 -group [get_clocks {FEMB_GXB_refclk_R}] \
	 -group [get_clocks {ProtoDUNE_CLK_100MHz}] \
	 -group [get_clocks {FELIX_PCS_refclk}] \
	 -group [get_clocks {clk_40MHz}] \
	 -group [get_clocks {clk_50MHz}] \
	 -group [get_clocks {clk_100MHz}] \
    -group [get_clocks {GXB_1}] \
    -group [get_clocks {GXB_2}] \
    -group [get_clocks {GXB_3}] \
    -group [get_clocks {GXB_4}] \
    -group [get_clocks {GXB_5}] \
    -group [get_clocks {GXB_6}] \
    -group [get_clocks {GXB_7}] \
    -group [get_clocks {GXB_8}] \
    -group [get_clocks {GXB_9}] \
    -group [get_clocks {GXB_10}] \
    -group [get_clocks {GXB_11}] \
    -group [get_clocks {GXB_12}] \
    -group [get_clocks {GXB_13}] \
    -group [get_clocks {GXB_14}] \
    -group [get_clocks {GXB_15}] \
    -group [get_clocks {GXB_16}] \
	 -group [get_clocks {felix_pcs_clk1 felix_pcs_clk2}] \
	 -group [get_clocks {felix_event_clk1}] \
	 -group [get_clocks {felix_event_clk2}] \

set_false_path -from * -to  [get_ports {SI5344_*}]	  
#set_false_path -from * -to  [get_ports {P_POD_RST}]	 	 
#set_false_path -from * -to  [get_ports {P_POD_SCL}]	 	 
#set_false_path -from * -to  [get_ports {P_POD_SDA}] 
set_false_path -from * -to  [get_ports {PWR_EN_*}] 
set_false_path -from * -to  [get_ports {PWR_SCL_*}] 	
set_false_path -from * -to  [get_ports {PWR_SDA_*}] 	 
set_false_path -from * -to  [get_ports {WIB_LED*}] 	
set_false_path -from * -to  [get_ports {FEMB_CLK_SEL}] 
set_false_path -from * -to  [get_ports {FEMB_CMD_SEL}] 
set_false_path -from * -to  [get_ports {FEMB_SCL*}] 
set_false_path -from * -to  [get_ports {FEMB_SDA*}] 

set_false_path -from * -to  [get_ports {FLASH_SCL}] 
set_false_path -from * -to  [get_ports {FLASH_SDA}] 
set_false_path -from * -to  [get_ports {LEMO2}] 
set_false_path -from * -to  [get_ports {PWR_CLK_IN[1]}] 
#set_false_path -from * -to  [get_ports {SBND_CLK_FPGA_*}] 
set_false_path -from * -to  [get_ports {SYS_CMD_FPGA*}] 
set_false_path -from * -to  [get_ports {LEMO_IN2}] 
set_false_path -from * -to  [get_ports {altera_*}] 



set_false_path -from {UDP_IO:udp_io_inst1|tx_frame_v2:tx_frame_inst|TX_REG:TX_REG_inst|REG_address_S*} -to {UDP_IO:udp_io_inst1|tx_frame_v2:tx_frame_inst|TX_REG:TX_REG_inst|REG_data_s*} 	 
# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty
