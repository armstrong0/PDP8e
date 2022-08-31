12'o7431 SWAB
12'o7447 SWBA
// mode A
12'o7441 SCA
12'o7641 SCA CLA
12'o7403 SCL  // m
12'o7405 MUY  // m
12'o7407 DVI  // m
12'o7411 NMI
12'o7413 SHL  // m
12'o7415 ASR  // m
12'o7417 LSR  // m

// mode B
12'o7403 ASC
12'o7405 MUL  // I
12'o7407 DVI  // I 
12'o7411 NMI 
12'o7413 SHL  // I
12'o7415 ASR  // I
12'o7417 LSR  // I
12'o7441 SCA
12'o7641 SCA CLA
12'o7457 SAM
12'o7763 DLD  // I  double load
12'o7443 DAD  // I  double add
12'o7445 DST  // I  double store
12'o7573 DPIC
12'o7575 DCM
12'o7451 DPSZ

// not necessary to code these as they are microcoded operations
//12'o7621 CAM (CLA MQL)
//12'o7663 DLD (CLA MQL DAD)
//12'o7671 SKB (DPSZ CLA MQL ) skip if mode B ?
//
// MQ instructions
12'o7401 NOP
12'o7601 CLA
12'o7421 MQL  // AC => MQ  0 => AC
12'o7501 MQA  // AC | MQ >= AC
12'o7621 CAM  // Clear AC and MA
12'o7521 SWP  // swap AC and MQ
12'o7701 ACL  // MQ => AC
12'o7721 CLA SWP // MA => AC clear MQ

bit 6 is SCA  in mode A 
bits 8-10
000 NOP
001 SCL
010 MUY
011 DVI
100 NMI   7411 *** cant't be combined
101 SHL
110 ASR
111 LSR

mode B 
bits 6,8-10
0000 NOP
0001 ACS AC => SC
0010 MUY
0011 DVI
0100 NMI *** 7411
0101 SHL
0110 ASR
0111 LSR
1000 SCA
1001 DAD
1010 DST
1011 SWBA
1100 DPSZ
1101 DPIC bits 5 and 7 must be 1 bit 4 can change 7573  7773 (CLA)
1110 DCM  bits 5 and 7 must be 1                  7575  7775  
1111 SAM
