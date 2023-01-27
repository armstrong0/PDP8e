#!/bin/bash

diag_dir=$(pwd)/Diagnostics

function prompt ()
{
echo "If CPU is running: Switch Halt to ON and then OFF"
echo "Set Switch Register (SR) to 7777, press Addr Load, press Clear then Cont."
echo "IF USING the SW to set the bootloader start address MAKE SURE sr bit 0 is up"
read -p "Press any key"
echo "Set SR to 0200, press Addr Load"

}

function term_hex()
{
echo "Starting Minicom Terminal program, in HEX mode, it will start centered on the screen"
sleep 1
mate-terminal -e "minicom --displayhex" &

}

echo "Select a test to run"
echo "1) Instruction Test Part 1"
echo "2) Instruction Test Part 2"
echo "3) Adder test"
echo "4) Basic-JMP-JMS"
echo "5) Random-TAD"
echo "6) Random-AND"
echo "7) Random-ISZ"
echo "8) Random-DCA"
echo "9) Random-JMP"
echo "10) Random-JMP-JMS"
echo "11) Memory Extension / Time share control"
echo "12) EAE test 1 - all but multiply and divide"
echo "13) EAE multiply and divide"
echo "14) EAE with extended memory"

echo -n "Enter the number of a test: "
read selection

case $selection in

1) prompt
sendtape $diag_dir/dhkaf-a-pb 
#sendtape $diag_dir/MAINDEC-8E-D0AB-InstTest-1.pdf 
echo "Set SR=7777, press Addr Load, then press Clear, Cont"
echo "Once loading is complete set SR=0200,"
echo "press Addr Load"
echo "Set SR=7777, then press Clear and Cont"
read -p "Press any key to continue"
echo "CPU should stop at 0147.  AC should be 0000"
echo "Press Cont"
term_hex
echo "A bell charactor 87 (07) is typed every 1440 passes of the test"
read -p "Press any key to continue"
sleep 1
;;

2) prompt
 sendtape $diag_dir/maindec-08-dhkag-a-pb 
echo "Set SR=7777, then press Clear, Cont"
read -p "Press any key"
echo "Set SR=0200 Press AL,CL,CO"
term_hex
echo "A bell charactor 87 (07) is typed every 1500 passes of the test"
read -p "Press any key to continue"
sleep 1
;;
3) prompt
echo "Starting Adder Tests requires about 4 minutes to run, examine terminal for errors"
 sendtape $diag_dir/MAINDEC-8E-D0CC-AddTest.pt  
sleep 1
echo "Starting Minicom Terminal program"
sleep 1
mate-terminal -e minicom  &
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 0210,(one extended bank) press Clear, then Cont"
echo "Once RANDOM is typed in the terminal, the Adder test is complete, close the terminal"
echo "The adder test clobbers the boot loader, to restore set address to 7600,"
echo "Address Load, Clear, Cont"

;;

4) prompt
echo "Starting Basic JMP - JMS tests"
 sendtape $diag_dir/MAINDEC-8E-D0IB-Basic-JMP-JMS.pt 
echo "Set SR=0200 Press Addr Load"
echo "Press Clear, then COnt"
term_hex
echo "A bell charactor 07/87 will be typed ever few seconds."
echo "To restore the bootloader, halt the CPU, set the SR to 704, press Addr Load"
echo "Press Clear and then continue, if it stops at 736 the bootloader is restored"
 ;;
5) prompt
echo "Starting Random TAD Tests"
 sendtape $diag_dir/MAINDEC-8E-D0EB-Random-TAD.pt sleep 1
echo "Starting Minicom Terminal program, it will start centered on the screen"
sleep 1
mate-terminal -e minicom  &
echo "T will typed every 4096 TAD's"
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 0000, press Clear, then Cont"
echo "Stop the test once satisfied, close minicom"
;;

6) prompt
echo "Starting Random AND Tests"
echo "alternates between two memory regions"
 sendtape $diag_dir/MAINDEC-8E-D0DB-Random-AND.pt
echo "Starting Minicom Terminal program, it will start centered on the screen"
sleep 1
mate-terminal -e minicom  &
echo "A will typed every 4096 ANDs"
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 0000, press Clear, then Cont"
echo "Stop the test once satisfied, at least two, close minicom"
 ;;
7) prompt
echo "Starting Random ISZ Tests"
 sendtape $diag_dir/MAINDEC-8E-D0FC-Random-ISZ.pt
 echo "Starting Minicom Terminal program, it will start centered on the screen"
sleep 1
mate-terminal -e minicom  &
echo "FC will typed 32000 tests"
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 0000, press Clear, then Cont"
echo "Stop the test once satisfied, at least two, close minicom"

 ;;
8) prompt
echo "Starting Random DCA Tests"
 sendtape $diag_dir/MAINDEC-8E-D0GC-Random-DCA.pt 
echo "Starting Minicom Terminal program, in HEX mode, it will start centered on the screen"
sleep 1
mate-terminal -e "minicom --displayhex" &
echo "07 will be printed every 27000 passes"
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 0000, press Clear, then Cont"
echo "Minicom will show 87 - each is a bell which signifies ~27000 tests, close minicom"


 ;;
9)  prompt
echo "Starting Random JMP tests"
sendtape $diag_dir/MAINDEC-8E-D0HC-Random-JMP.pt 
echo "Starting Minicom Terminal program, it will start centered on the screen"
sleep 1
mate-terminal -e minicom  &
echo "HC will be typed every 72000 tests"
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 0000, press Clear, then Cont"

;;
10)  prompt
echo "Starting Random JMP JMS tests"
sendtape $diag_dir/MAINDEC-8E-D0JB-Random-JMP-JMS.pt
echo "Starting Minicom Terminal program, it will start centered on the screen"
sleep 1
mate-terminal -e minicom  &
echo "JB will be typed every 61000 tests"
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 0000, press Clear, then Cont"


;;
11) prompt
echo "Starting Memory Extension / Time Share Control"
sendtape $diag_dir/maindec-08-dhmca-b-pb 
echo "Starting Minicom Terminal program, in HEX mode, it will start centered on the screen"
sleep 1
mate-terminal -e "minicom --displayhex" &
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 0001, (one extended bank)  press Clear, then Cont"
echo "Minicom will show 87 (or 07) - each is a bell which signifies one complete pass, close minicom"
;;

12) prompt
echo "Testing EAE mode A and B except multiply and divide"
sendtape $diag_dir/MAINDEC-8E-D0LB-PB
#sendtape $diag_dir/MAINDEC-8E-D0LA-EAE-Test1.pt
echo "Starting Minicom Terminal program, it will start centered on the screen"
sleep 1
mate-terminal -e minicom  &
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 5000, press Clear, then Cont"
echo "Test B only with SR = 5003"
echo "Test A only with SR = 5002"
echo "Test both modes with SR=5000"
echo "If doing a partial test a CR LF is printed at the end of each pass"
echo "If doing a full A/B test KE8 is printed at the end of each pass"
echo "All tests should run in less than one minute"
echo "Stop the test once satisfied, close minicom"

;;
13) prompt
echo "Testing EAE mode A and B multiply and divide"
sendtape $diag_dir/MAINDEC-8E-D0MB-PB
echo "Starting Minicom Terminal program, it will start centered on the screen"
sleep 1
mate-terminal -e minicom  &
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 0000, press Clear, then Cont"
echo "Program will halt at 0201, press Cont"
echo "Test B only with SR = 0003"
echo "Test A only with SR = 0002"
echo "Test both modes with SR=0000"
echo "Full test with printout set SR3=1"
echo "If doing a partial test a CR LF is printed at the end of each pass"
echo "If doing a full A/B test KE8 2 is printed at the end of each pass"
echo "All tests should run in less than one minute"
echo "Program end halt is at 0251"
echo "Stop the test once satisfied, close minicom"

;;

14) prompt
echo "Testing EAE Extended Memory"
echo "Exercises B mode instructions that use extended memory"
sendtape $diag_dir/maindec-08-dhkea-e-pb
echo "Starting Minicom Terminal program, it will start centered on the screen"
sleep 1
mate-terminal -e minicom  &
echo "Set SR=0200 Press Addr Load"
echo "Set SR to 0000, press Clear, then Cont"
echo "Program will prompt for the highest field available"
echo "answer the number of extended fields, i.e. 1 for 8k"
echo "All tests should run in less than one minute"
echo "Stop the test once satisfied, close minicom"

;;

15) prompt
;;
 *) echo "Invalid response enter a number between 1 and 13"

esac
 

