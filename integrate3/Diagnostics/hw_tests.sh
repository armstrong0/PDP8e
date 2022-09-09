#!/bin/bash
echo "Set Switch Register (SR) to 7777, press Addr Load(AL) press Clear(CL) then Cont (CO)"
read -p "Press any key"
sendtape MAINDEC-8E-D0AB-InstTest-1.pt
echo "Set SR to 0200, press addr load"
echo "Set SR=7777, then press clear, cont"
echo "CPU should stop at 0147.  AC should be 0000"
echo "Press Cont"
read -p "Press any key to continue"
sleep 1
echo " if the CPU is not stopped we have run many passes of the whole test"
echo " moving to the next one"
echo "Set SR=7777 press AL,CL,CO"
read -p "Press any key"
sendtape dhkaf-a-pb 
echo "Set SR=0200 Press AL"
echo "Set SR=7777,press CL,CO"
echo "CPU should stop at 0147.  AC should be 0000"
echo "Press Cont"
read -p "Press any key to continue"
sleep 1
echo " if the CPU is not stopped we have run many passes of the whole test"
echo " moving to the next one"
echo "Set SR=7777 press AL,CL,CO"
read -p "Press any key"
 sendtape MAINDEC-8E-D0BB-InstTest-2.pt
echo "Set SR=0200 Press AL,CL,CO"
sleep 1
echo " if the CPU is not stopped we have run many passes of the whole test"
echo " moving to the next one"
echo "Set SR=7777 press AL,CL,CO"
 sendtape maindec-08-dhkag-a-pb 
read -p "Press any key"
echo "Set SR=0200 Press AL,CL,CO"
sleep 1
echo " if the CPU is not stopped we have run many passes of the whole test"
echo " moving to the next one"
echo "Set SR=7777 press AL,CL,CO"
echo "Starting Adder Tests requires about 4 minutes to run, examine terminal for errors"
echo "Set SR=7777 press AL,CL,CO"
 sendtape MAINDEC-8E-D0CC-AddTest.pt  
sleep 1
 mate-terminal -e minicom &
echo "Set SR=0200 Press AL,CL,CO"



 sendtape MAINDEC-8E-D0IB-Basic-JMP-JMS.pt
 sendtape MAINDEC-8E-D0EB-Random-TAD.pt 
 sendtape MAINDEC-8E-D0DB-Random-AND.pt 
 sendtape MAINDEC-8E-D0FC-Random-ISZ.pt
 sendtape MAINDEC-8E-D0GC-Random-DCA.pt
 sendtape MAINDEC-8E-D0HC-Random-JMP.pt
 sendtape MAINDEC-8E-D0JB-Random-JMP-JMS.pt
 sendtape maindec-08-dhmca-a-pb 

 mate-terminal -e minicom &
