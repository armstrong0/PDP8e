`define RK8E
//`define up5k

// state machine encoding
localparam F0 = 5'd0,  // 0
FW = 5'd1,  // 1
F1 = 5'd2,  // 2
F2 = 5'd3,  // 3
F3 = 5'd4,  // 4

D0 = 5'd5,  // 5
DW = 5'd6,  // 6
D1 = 5'd7,  // 7 
D2 = 5'd8,  // 8
D3 = 5'd10,  // 10

E0 = 5'd11,  // 11
EW = 5'd12,  // 12
E1 = 5'd13,  // 13
E2 = 5'd14,  // 14
E3 = 5'd15,  // 15

H0 = 5'd16,  // 16
HW = 5'd17,  // 17
H1 = 5'd18,  // 18
H2 = 5'd19,  // 19
H3 = 5'd20,  // 20
EAE0 = 5'd21,  // 21
EAE1 = 5'd22,  // 22
F2A = 5'd27,  // 27
F2B = 5'd28,  // 28
DB0 = 5'd29,  // data break states 29
DB1 = 5'd30,  // 30
DB2 = 5'd31;  // 31
//DW1 = 5'd9,  // 9
//EAE2 = 5'd23, // 23
//EAE3 = 5'd24, // 24 
//EAE4 = 5'd25, // 25
//EAE5 = 5'd26, // 26


// instruction encodings
localparam SAM=12'o7457,
DAD  = 12'o7443,
DST  = 12'o7445, 
DPIC = 12'o7773,
DCM  = 12'o7575,
DPSZ = 12'o7451,
DLD  = 12'o7763,
CAMDAD = 12'o7663, 
SHL = 12'o7413,
ASR = 12'o7415,
LSR = 12'o7417,
MUL = 12'o7405,
DIV = 12'o7407,
NMI = 12'o7411;


`ifdef RK8E
localparam CAF = 12'o6007,  // clear all flags
DSKP = 12'o6741,  // skip if error or done
DCLC = 12'o6742,  // DCLC disk clear
DLAG = 12'o6743,  // DLAG load and go
DCLA = 12'o6744,  // DLCA load current address
DRST = 12'o6745,  // DRST read status
DLDC = 12'o6746;  // DLDC load command register
`endif
localparam  AND = 3'b000, 
TAD = 3'b001,
ISZ = 3'b010,
DCA = 3'b011,
JMS = 3'b100,
JMP = 3'b101,
OPR = 3'b111,
IOT = 3'b110,
JMPD =4'b1010,
JMPI = 4'b1011,
JM = 2'b10 ;
// clock_frequency is defined in the top level verilog file 
// or in an included file..


`ifdef SIM
// calculate in nanoseconds
localparam real clock_frequency = 84000000;
parameter real baud_rate = 115200;
`elsif TSIM
// calculate in nanoseconds
parameter real clock_frequency = 5000000;
parameter real baud_rate = 1200;
`else
parameter real baud_rate = 9600;
`endif

//    parameter real clock_period = 1/clock_frequency*1e9;

// define the slow and fast clocks of the sd card
// the counts here have to be for 1/2 clock.
// Error on the low side, especially for 4 MHz
// frequencies will not be exact.
//`ifdef RK8E
parameter real slow_spi = 10000;
parameter real fast_spi = 50000;
// go too high and the state machines don't work!
//`endif



parameter MAX_FIELD = 3'b001;

`define ONESTOP // one stop bit for all baud rates greater than 110



