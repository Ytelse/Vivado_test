## Clock signal

set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { ULPI_clk }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { ULPI_clk }];

##Quad SPI Flash

##set_property -dict { PACKAGE PIN E8    IOSTANDARD LVCMOS33 } [get ports { SPIsck}]; #CCLK_0 Sch=SPIsck
#set_property -dict { PACKAGE_PIN L12   IOSTANDARD LVCMOS33 } [get_ports { SPIcs }]; #IO_L6P_T0_FCS_B_14 Sch=SPIcs
#set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { SPId[0] }]; #IO_L1P_T0_D00_MOSI_14 Sch=SPId[0]
#set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { SPId[1] }]; #IO_L1N_T0_D01_DIN_14 Sch=SPId[1]
#set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { SPId[2] }]; #IO_L2P_T0_D02_14 Sch=SPId[2]
#set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { SPId[3] }]; #IO_L2N_T0_D03_14 Sch=SPId[3]

##FPGA_EP


#set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { EP[1] }]; #IO_L10P_T1_D14_14 Sch=EP[1]
#set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS33 } [get_ports { EP[2] }]; #IO_L10N_T1_D15_14 Sch=EP[2]
#set_property -dict { PACKAGE_PIN N13 IOSTANDARD LVCMOS33 } [get_ports { EP[3] }]; #IO_L11P_T1_SRCC_14 Sch=EP[3]
#set_property -dict { PACKAGE_PIN P13 IOSTANDARD LVCMOS33 } [get_ports { EP[4] }]; #IO_L11N_T1_SRCC_14 Sch=EP[4]
#set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports { EP[5] }]; #IO_L12P_T1_MRCC_14 Sch=EP[5]
#set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { EP[6] }]; #IO_L12N_T1_MRCC_14 Sch=EP[6]
#set_property -dict { PACKAGE_PIN N11 IOSTANDARD LVCMOS33 } [get_ports { EP[7] }]; #IO_L13P_T2_MRCC_14 Sch=EP[7]
#set_property -dict { PACKAGE_PIN N12 IOSTANDARD LVCMOS33 } [get_ports { EP[8] }]; #IO_L13N_T2_MRCC_14 Sch=EP[8]
#set_property -dict { PACKAGE_PIN P10 IOSTANDARD LVCMOS33 } [get_ports { EP[9] }]; #IO_L14P_T2_SRCC_14 Sch=EP[9]
#set_property -dict { PACKAGE_PIN P11 IOSTANDARD LVCMOS33 } [get_ports { EP[10] }]; #IO_L14N_T2_SRCC_14 Sch=EP[10]
#set_property -dict { PACKAGE_PIN R12 IOSTANDARD LVCMOS33 } [get_ports { EP[11] }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=EP[11]
#set_property -dict { PACKAGE_PIN T12 IOSTANDARD LVCMOS33 } [get_ports { EP[12] }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 Sch=EP[12]
#set_property -dict { PACKAGE_PIN R13 IOSTANDARD LVCMOS33 } [get_ports { EP[13] }]; #IO_L16P_T2_CSI_B_14 Sch=EP[13]
#set_property -dict { PACKAGE_PIN T13 IOSTANDARD LVCMOS33 } [get_ports { EP[14] }]; #IO_L16N_T2_A15_D31_14 Sch=EP[14]
#set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports { EP[15] }]; #IO_L17P_T2_A14_D30_14 Sch=EP[15]

##Reset Button

set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { ULPI_rst }]; #IO_L22N_T3_A04_D20_14 Sch=reset

## MCU CTRL

#set_property -dict { PACKAGE_PIN C8 IOSTANDARD LVCMOS33 } [get_ports { MCUctrl[0] }]; #IO_L1P_T0_AD0P_15 Sch=MCUctrl[0]
#set_property -dict { PACKAGE_PIN C9 IOSTANDARD LVCMOS33 } [get_ports { MCUctrl[1] }]; #IO_L1N_T0_AD0N_15 Sch=MCUctrl[1]
#set_property -dict { PACKAGE_PIN A8 IOSTANDARD LVCMOS33 } [get_ports { MCUctrl[2] }]; #IO_L2P_T0_AD8P_15 Sch=MCUctrl[2]
#set_property -dict { PACKAGE_PIN A9 IOSTANDARD LVCMOS33 } [get_ports { MCUctrl[3] }]; #IO_L2N_T0_AD8N_15 Sch=MCUctrl[3]
#set_property -dict { PACKAGE_PIN B9 IOSTANDARD LVCMOS33 } [get_ports { MCUctrl[4] }]; #IO_L3P_T0_DQS_AD1P_15 Sch=MCUctrl[4]
#set_property -dict { PACKAGE_PIN A10 IOSTANDARD LVCMOS33 } [get_ports { MCUctrl[5] }]; #IO_L3N_T0_DQS_AD1N_15 Sch=MCUctrl[5]
#set_property -dict { PACKAGE_PIN B10 IOSTANDARD LVCMOS33 } [get_ports { MCUctrl[6] }]; #IO_L4P_T0_15 Sch=MCUctrl[6]
#set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 } [get_ports { MCUctrl[7] }]; #IO_L4N_T0_15 Sch=MCUctrl[7]
#set_property -dict { PACKAGE_PIN B12 IOSTANDARD LVCMOS33 } [get_ports { MCUctrl[8] }]; #IO_L5P_T0_AD9P_15 Sch=MCUctrl[8]
#set_property -dict { PACKAGE_PIN A12 IOSTANDARD LVCMOS33 } [get_ports { MCUctrl[9] }]; #IO_L5N_T0_AD9N_15 Sch=MCUctrl[9]

##EBI-A BUS

#set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { EBIa[0] }]; #IO_L6N_T0_VREF_15 Sch=EBIa[0]
#set_property -dict { PACKAGE_PIN E12 IOSTANDARD LVCMOS33 } [get_ports { EBIa[1] }]; #IO_L13P_T2_MRCC_15 Sch=EBIa[1]
#set_property -dict { PACKAGE_PIN D13 IOSTANDARD LVCMOS33 } [get_ports { EBIa[2] }]; #IO_L12P_T1_MRCC_15 Sch=EBIa[2]
#set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { EBIa[3] }]; #IO_L11N_T1_SRCC_15 Sch=EBIa[3]
#set_property -dict { PACKAGE_PIN C14 IOSTANDARD LVCMOS33 } [get_ports { EBIa[4] }]; #IO_L8P_T1_AD10P_15 Sch=EBIa[4]
#set_property -dict { PACKAGE_PIN A13 IOSTANDARD LVCMOS33 } [get_ports { EBIa[5] }]; #IO_L7N_T1_AD2P_15 Sch=EBIa[5]
#set_property -dict { PACKAGE_PIN B14 IOSTANDARD LVCMOS33 } [get_ports { EBIa[6] }]; #IO_L8N_T1_AD10N_15 Sch=EBIa[6]
#set_property -dict { PACKAGE_PIN A15 IOSTANDARD LVCMOS33 } [get_ports { EBIa[7] }]; #IO_L9N_T1_DQS_AD3N_15 Sch=EBIa[7]
#set_property -dict { PACKAGE_PIN E11 IOSTANDARD LVCMOS33 } [get_ports { EBIa[8] }]; #IO_L14P_T2_SRCC_15 Sch=EBIa[8]
#set_property -dict { PACKAGE_PIN E13 IOSTANDARD LVCMOS33 } [get_ports { EBIa[9] }]; #IO_L13N_T2_MRCC_15 Sch=EBIa[9]
#set_property -dict { PACKAGE_PIN C11 IOSTANDARD LVCMOS33 } [get_ports { EBIa[10] }]; #IO_L11P_T1_SRCC_15 Sch=EBIa[10]
#set_property -dict { PACKAGE_PIN C13 IOSTANDARD LVCMOS33 } [get_ports { EBIa[11] }]; #IO_L12N_T1_MRCC_15 Sch=EBIa[11]
#set_property -dict { PACKAGE_PIN C16 IOSTANDARD LVCMOS33 } [get_ports { EBIa[12] }]; #IO_L10P_T1_AD11P_15 Sch=EBIa[12]
#set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports { EBIa[13] }]; #IO_L7N_T1_AD2N_15 Sch=EBIa[13]
#set_property -dict { PACKAGE_PIN B15 IOSTANDARD LVCMOS33 } [get_ports { EBIa[14] }]; #IO_L9P_T1_DQS_AD3P_15 Sch=EBIa[14]
#set_property -dict { PACKAGE_PIN B16 IOSTANDARD LVCMOS33 } [get_ports { EBIa[15] }]; #IO_L10N_T1_AD11N_15 Sch=EBIa[15]

##EBI-D BUS

#set_property -dict { PACKAGE_PIN H13 IOSTANDARD LVCMOS33 } [get_ports { EBId[0] }]; #IO_L20N_T3_A19_15 Sch=EBId[0]
#set_property -dict { PACKAGE PIN H11 IOSTANDARD LVCMOS33 } [get ports { EBId[1] }]; #IO_L19P_T3_A22_15 Sch=EBId[1]
#set_property -dict { PACKAGE PIN G14 IOSTANDARD LVCMOS33 } [get ports { EBId[2] }]; #IO_L21P_T3_DQS_15 Sch=EBId[2]
#set_property -dict { PACKAGE PIN F13 IOSTANDARD LVCMOS33 } [get ports { EBId[3] }]; #IO_L16N_T2_A27_15 Sch=EBId[3]
#set_property -dict { PACKAGE PIN H16 IOSTANDARD LVCMOS33 } [get ports { EBId[4] }]; #IO_L22P_T3_A17_15 Sch=EBId[4]
#set_property -dict { PACKAGE PIN D14 IOSTANDARD LVCMOS33 } [get ports { EBId[5] }]; #IO_L15P_T2_DQS_15 Sch=EBId[5]
#set_property -dict { PACKAGE PIN F15 IOSTANDARD LVCMOS33 } [get ports { EBId[6] }]; #IO_L18P_T2_A24_15 Sch=EBId[6]
#set_property -dict { PACKAGE PIN E16 IOSTANDARD LVCMOS33 } [get ports { EBId[7] }]; #IO_L17P_T2_A26_15 Sch=EBId[7]
#set_property -dict { PACKAGE PIN H12 IOSTANDARD LVCMOS33 } [get ports { EBId[8] }]; #IO_L20P_T3_A20_15 Sch=EBId[8]
#set_property -dict { PACKAGE PIN G12 IOSTANDARD LVCMOS33 } [get ports { EBId[9] }]; #IO_L19N_T3_A21_VREF_15 Sch=EBId[9]
#set_property -dict { PACKAGE PIN F12 IOSTANDARD LVCMOS33 } [get ports { EBId[10] }]; #IO_L16P_T2_A28_15 Sch=EBId[10]
#set_property -dict { PACKAGE PIN F14 IOSTANDARD LVCMOS33 } [get ports { EBId[11] }]; #IO_L21N_T3_DQS_A18_15 Sch=EBId[11]
#set_property -dict { PACKAGE PIN E15 IOSTANDARD LVCMOS33 } [get ports { EBId[12] }]; #IO_L18N_T2_A23_15 Sch=EBId[12]
#set_property -dict { PACKAGE PIN D15 IOSTANDARD LVCMOS33 } [get ports { EBId[13] }]; #IO_L15N_T2_DQS_ADV_B_15 Sch=EBId[13]
#set_property -dict { PACKAGE PIN G16 IOSTANDARD LVCMOS33 } [get ports { EBId[14} ]; #IO_L22N_T3_A16_15 Sch=EBId[14]
#set_property -dict { PACKAGE PIN D16 IOSTANDARD LVCMOS33 } [get ports { EBId[15] }]; #IO_L17N_T2_A25_15 Sch=EBId[15]

## EBI Control

#set_property -dict { PACKAGE PIN J15 IOSTANDARD LVCMOS33 } [get ports { EBIcs1 }]; #IO_L23P_T3_FOE_B_15 Sch=EBIcs1
#set_property -dict { PACKAGE PIN J16 IOSTANDARD LVCMOS33 } [get ports { EBIwen }]; #IO_L23N_T3_FWE_B_15 Sch=EBIwen
#set_property -dict { PACKAGE PIN H14 IOSTANDARD LVCMOS33 } [get ports { EBIren }]; #IO_L24P_T3_RS1_15 Sch=EBIren
#set_property -dict { PACKAGE PIN G15 IOSTANDARD LVCMOS33 } [get ports { EBIcs0 }]; #IO_L24N_T3_RS0_15 Sch=EBIcs0

## SD card

#set_property -dict { PACKAGE PIN P3 IOSTANDARD LVCMOS33 } [get ports { SDdat[0] }]; #IO_L5N_T0_34 Sch=SDdat[0]
#set_property -dict { PACKAGE PIN P4 IOSTANDARD LVCMOS33 } [get ports { SDdat[1] }]; #IO_L5P_T0_34 Sch=SDdat[1]
#set_property -dict { PACKAGE PIN M1 IOSTANDARD LVCMOS33 } [get ports { SDdat[2] }]; #IO_L2N_T0_34 Sch=SDdat[2]
#set_property -dict { PACKAGE PIN N1 IOSTANDARD LVCMOS33 } [get ports { SDdat[3] }]; #IO_L4P_T0_34 Sch=SDdat[3]
#set_property -dict { PACKAGE PIN N2 IOSTANDARD LVCMOS33 } [get ports { SDcmd }]; #IO_L3N_T0_DQS_34 Sch=SDcmd
#set_property -dict { PACKAGE PIN P1 IOSTANDARD LVCMOS33 } [get ports { SDclk }]; #IO_L4N_T0_34 Sch=SDclk
#set_property -dict { PACKAGE PIN M5 IOSTANDARD LVCMOS33 } [get ports { SDcd }]; #IO_L6P_T0_34 Sch=SDcd

## ULPI Bus

set_property -dict { PACKAGE_PIN A4 IOSTANDARD LVCMOS33 } [get_ports { ULPI_data[0] }]; #IO_L3N_T0_DQS_AD5N_35 Sch=ULPId[0]
set_property -dict { PACKAGE_PIN A5 IOSTANDARD LVCMOS33 } [get_ports { ULPI_data[1] }]; #IO_L3P_T0_DQS_AD5P_35 Sch=ULPId[1]
set_property -dict { PACKAGE_PIN A2 IOSTANDARD LVCMOS33 } [get_ports { ULPI_data[2] }]; #IO_L8N_T1_AD14N_35 Sch=ULPId[2]
set_property -dict { PACKAGE_PIN A3 IOSTANDARD LVCMOS33 } [get_ports { ULPI_data[3] }]; #IO_L4N_T0_35 Sch=ULPId[3]
set_property -dict { PACKAGE_PIN B4 IOSTANDARD LVCMOS33 } [get_ports { ULPI_data[4] }]; #IO_L4P_T0_35 Sch=ULPId[4]
set_property -dict { PACKAGE_PIN B2 IOSTANDARD LVCMOS33 } [get_ports { ULPI_data[5] }]; #IO_L8P_T1_AD14P_35 Sch=ULPId[5]
set_property -dict { PACKAGE_PIN C2 IOSTANDARD LVCMOS33 } [get_ports { ULPI_data[6] }]; #IO_L7N_T1_AD6N_35 Sch=ULPId[6]
set_property -dict { PACKAGE_PIN C1 IOSTANDARD LVCMOS33 } [get_ports { ULPI_data[7] }]; #IO_L9P_T1_DQS_AD7P_35 Sch=ULPId[7]
set_property -dict { PACKAGE_PIN B5 IOSTANDARD LVCMOS33 } [get_ports { ULPI_clk }]; #IO_L2N_T0_AD12N_35 Sch=ULPIclk
set_property -dict { PACKAGE_PIN C7 IOSTANDARD LVCMOS33 } [get_ports { ULPI_dir }]; #IO_L5P_T0_AD13P_35 Sch=ULPIdir
set_property -dict { PACKAGE_PIN C6 IOSTANDARD LVCMOS33 } [get_ports { ULPI_nxt }]; #IO_L5N_T0_AD13N_35 Sch=ULPInxt
set_property -dict { PACKAGE_PIN D6 IOSTANDARD LVCMOS33 } [get_ports { ULPI_rst }]; #IO_L6P_T0_35 Sch=ULPIrst
set_property -dict { PACKAGE_PIN C3 IOSTANDARD LVCMOS33 } [get_ports { ULPI_stp }]; #IO_L7P_T1_AD6P_35 Sch=ULPIstp

## USB1
#set_property -dict { PACKAGE PIN E1 IOSTANDARD LVCMOS33 } [get ports { USB1DnRes }]; #IO_L15N_T2_DQS_35 Sch=USB1DnRes
#set_property -dict { PACKAGE PIN G5 IOSTANDARD LVCMOS33 } [get ports { USB1Dn }]; #IO_L16P_T2_35 Sch=USB1Dn
#set_property -dict { PACKAGE PIN G4 IOSTANDARD LVCMOS33 } [get ports { USB1Dp }]; #IO_L16N_T2_35 Sch=USB1Dp
#set_property -dict { PACKAGE PIN G2 IOSTANDARD LVCMOS33 } [get ports { USP1susp }]; #IO_L17P_T2_35 Sch=USP1susp
#set_property -dict { PACKAGE PIN G1 IOSTANDARD LVCMOS33 } [get ports { USB1oe }]; #IO_L17N_T2_35 Sch=USB1oe
#set_property -dict { PACKAGE PIN H5 IOSTANDARD LVCMOS33 } [get ports { USB1vm }]; #IO_L18P_T2_35 Sch=USB1vm
#set_property -dict { PACKAGE PIN H4 IOSTANDARD LVCMOS33 } [get ports { USB1rcv }]; #IO_L18N_T2_35 Sch=USB1rcv
#set_property -dict { PACKAGE PIN J5 IOSTANDARD LVCMOS33 } [get ports { USB1softcon }]; #IO_L19P_T3_35 Sch=USB1softcon
#set_property -dict { PACKAGE PIN J4 IOSTANDARD LVCMOS33 } [get ports { USB1vp }]; #IO_L19N_T3_VREF_35 Sch=USB1vp
#set_property -dict { PACKAGE PIN H2 IOSTANDARD LVCMOS33 } [get ports { USB1speed }]; #IO_L20P_T3_35 Sch=USB1speed


## FPGA LED

set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 } [get_ports { LED_array[0] }]; #IO_L20N_T3_35 Sch=led[0]
set_property -dict { PACKAGE_PIN J3 IOSTANDARD LVCMOS33 } [get_ports { LED_array[1] }]; #IO_L21P_T3_DQS_35 Sch=led[1]
set_property -dict { PACKAGE_PIN H3 IOSTANDARD LVCMOS33 } [get_ports { LED_array[2] }]; #IO_L21N_T3_DQS_35 Sch=led[2]
set_property -dict { PACKAGE_PIN K1 IOSTANDARD LVCMOS33 } [get_ports { LED_array[3] }]; #IO_L22P_T3_35 Sch=led[3]
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports { LED_array[4] }]; #IO_L22N_T3_35 Sch=led[4]
set_property -dict { PACKAGE_PIN L3 IOSTANDARD LVCMOS33 } [get_ports { LED_array[5] }]; #IO_L23P_T3_35 Sch=led[5]
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports { LED_array[6] }]; #IO_L23N_T3_35 Sch=led[6]
set_property -dict { PACKAGE_PIN K3 IOSTANDARD LVCMOS33 } [get_ports { LED_array[7] }]; #IO_L24P_T3_35 Sch=led[7]

