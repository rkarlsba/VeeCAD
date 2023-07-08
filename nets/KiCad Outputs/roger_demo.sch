EESchema Schematic File Version 1
LIBS:power,device,conn,linear,regul,74xx,cmos4000,adc-dac,memory,xilinx,special,microcontrollers,dsp,microchip,analog_switches,motorola,texas,intel,audio,interface,digital-audio,philips,display,cypress,siliconi,contrib,valves
EELAYER 23  0
EELAYER END
$Descr A4 11700 8267
Sheet 1 1
Title ""
Date "18 jul 2010"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Connection ~ 4250 3600
Wire Wire Line
	4650 3600 3850 3600
Wire Wire Line
	3350 3600 3000 3600
Wire Wire Line
	3000 3600 3000 3800
Wire Wire Line
	5500 4000 3000 4000
Connection ~ 4250 4000
Wire Wire Line
	5150 3600 5500 3600
Wire Wire Line
	5500 3600 5500 3800
$Comp
L C C1
U 1 1 4C4275B8
P 4250 3800
F 0 "C1" H 4300 3900 50  0000 L C
F 1 "47nF" H 4300 3700 50  0000 L C
F 2 "AX1_1N" H 4400 4000 60  0001 C C
	1    4250 3800
	1    0    0    -1  
$EndComp
$Comp
L CONN_2 P2
U 1 1 4C4275A9
P 5850 3900
F 0 "P2" H 5800 4250 40  0000 C C
F 1 "CONN_2" H 5900 4150 40  0000 C C
F 2 "SIP2" H 5900 4350 60  0001 C C
	1    5850 3900
	1    0    0    -1  
$EndComp
$Comp
L CONN_2 P1
U 1 1 4C4275A5
P 2650 3900
F 0 "P1" H 2750 4250 40  0000 C C
F 1 "CONN_2" H 2650 4150 40  0000 C C
F 2 "SIP2" H 2850 4350 60  0001 C C
	1    2650 3900
	-1   0    0    -1  
$EndComp
$Comp
L R R2
U 1 1 4C427592
P 4900 3600
F 0 "R2" V 4750 3600 50  0000 C C
F 1 "100K" V 4900 3600 50  0000 C C
F 2 "AX2_1" V 4850 3700 60  0001 C C
	1    4900 3600
	0    1    1    0   
$EndComp
$Comp
L R R1
U 1 1 4C427589
P 3600 3600
F 0 "R1" V 3450 3600 50  0000 C C
F 1 "22K" V 3600 3600 50  0000 C C
F 2 "AX2_1" V 3550 3700 60  0001 C C
	1    3600 3600
	0    1    1    0   
$EndComp
$EndSCHEMATC
