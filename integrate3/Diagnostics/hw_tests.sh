#!/bin/bash
echo "Set Switch Register (SR) to 7777, press Addr Load press Clear then Cont"
read -p "Press any key"
sendtape MAINDEC-8E-D0AB-InstTest-1.pt
echo "Set SR to 0200, press addr load, clear, cont"
echo "CPU should stop at 0147.  AC should be 0000"
read -p "Press any key to continue"
echo "Set SR to 7777, press continue"
wait (1)

