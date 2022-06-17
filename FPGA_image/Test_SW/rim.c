/****************************************************************
 *
 *		RIM File Generator, Version 0.2
 *		K. McQuiggin, July 1998
 *      mcquiggi@sfu.ca
 *
 *		Utility to create a RIM format file from a file containing
 *		ASCII format addresses and instructions.
 *
 *      Input should be a file with each line containing an
 *		octal address, followed by an octal instruction. Example:
 *
 *		7756 6032
 * 		7757 6031
 * 		7760 5357
 * 		7761 6036
 * 		7762 7106
 *		etc.
 *
 *		Output goes to the second file, in RIM format. You can then
 *		use the "send" utility to transmit the RIM code to the pdp-8.
 *
 *      This is alpha quality code, use and modify as required!
 *
 *      Kevin 
 *
 ****************************************************************/
#include <stdio.h>
#include <stdlib.h>
int main(int argc, char **argv) {
	char addr1, addr2, data1, data2;
	int addr, data;
	FILE *input, *output;

if(argc != 3) {
	fprintf(stderr, "Usage: %s inputfile outputfile\n", argv[0]);
	exit(1);
}
printf("PDP-8 RIM Code Generator, Version 0.2\n");

if((input=fopen(argv[1], "r")) == NULL) {
	perror(argv[1]);
	exit(1);
}

if((output=fopen(argv[2], "w")) == NULL) {
	perror(argv[2]);
	exit(1);
}

while(fscanf(input, "%o %o", &addr, &data) != EOF) {
	printf("(%04o) %04o:\t", addr, data);
	addr1=((addr & 0xfc0) >> 6) | 0x40;
	addr2=addr & 0x3f;
	data1=((data & 0xfc0) >> 6);
	data2=data & 0x3f;
	printf("%02o %02o %02o %02o\n", addr1, addr2, data1, data2);
	putc(addr1, output);
	putc(addr2, output);
	putc(data1, output);
	putc(data2, output);
}
fclose(input);
fclose(output);
printf("Conversion complete\n");
exit(0);
}
