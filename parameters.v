`define RK8E
`define EAE
`define FAST_SHIFTS
//`define up5k

// state machine encoding
localparam F0 = 5'd0,  // 0
FW = 5'd1,  // 1
F1 = 5'd2,  // 2
F2 = 5'd3,  // 3
F2A = 5'd4,  // 4
F2B = 5'd5,  // 5
F3 = 5'd6,  // 6

D0 = 5'd7,  // 7
DW = 5'd8,  // 8
D1 = 5'd9,  // 9 
D2 = 5'd10,  // 10
D3 = 5'd11,  // 11

E0 = 5'd12,  // 12
EW = 5'd13,  // 13
E1 = 5'd14,  // 14
E2 = 5'd15,  // 15
E3 = 5'd16,  // 16

`ifdef EAE
EAE0 = 5'd17,  // 17
EAE1 = 5'd18,  // 18
`endif

`ifdef RK8E
DB0 = 5'd22,  // 22
DB1 = 5'd23,  // 23
DB2 = 5'd24,  // 24
DB3 = 5'd25,  // 25
`endif
HW = 5'd26,  // 26
H1 = 5'd19,  // 19
H2 = 5'd20,  // 20
H3 = 5'd21;  // 21

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
//localparam real clock_frequency = 84000000;
localparam real clock_frequency = 73500000;
localparam real clock_period = 1/clock_frequency*1e9;
parameter real baud_rate = 115200; //10 clocks per output 
`elsif TSIM
// calculate in nanoseconds
parameter real clock_frequency = 5000000;
localparam real clock_period = 1/clock_frequency*1e9;
parameter real baud_rate = 1200;
`else
//parameter real baud_rate = 9600;
//parameter real baud_rate = 38400;
parameter real baud_rate = 115200; //10 clocks per output 
`endif

// define the slow and fast clocks of the sd card
// Error on the low side, especially for 4 MHz
// frequencies will not be exact.  Frequencies are in Hz
//`ifdef RK8E
// NOTE that these frequencies influence the initialization time
// there is a timeout in sd.sv that may come into play
parameter real slow_spi = 1000000;
parameter real fast_spi = 1000000;
// go too high and the state machines don't work!

// define the startup delay allowed for the sd card
// units of milliseconds

`ifdef SIM
parameter sd_delay = 2;
`else
parameter sd_delay = 10'd500;
`endif

// two diagnostic tests will not pass with partial fields so change to 8k
// 2 fields when running those tests

parameter MAX_ADDRESS = 15'o23777; // 10k 2.5 fields
//parameter MAX_ADDRESS = 15'o17777;  // 8k 2 fields

`define ONESTOP // one stop bit for all baud rates greater than 110



