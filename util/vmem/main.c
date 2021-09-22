//
//  main.c
//  vmem
//
//                        Copyright (c) 2021 Kevin Lynch
//                This file is licensed under the MIT license
//
//  This simple program takes the binary output of a 6502 assembler/linker and converts it
//  to a verilog memory file.  Break Vectors are placed at the end of the file with
//  the default being:
//            @FFFA
//             00 90 //NMI Vector address 0x9000
//             00 00 //RESET vector address 0x0000
//             00 A0 //INTERRUPT Vector address 0xA000
//
//  The output name is the same as the input name but with a .vmem extension.
//  You can change where the code starts (RESET vector) with the option: --start-addr 0x0400
//  if your code starts at address 0x0400 for example.
//
//  Example:
//     ./vmem test.bin   ;will output test.vmem with a starting address of 0x0000
//     ./vmem test.bin --start-addr 0x0400 ;will output test.vmem with a starting address of 0x0400
//
// The NMI and INTERRUPT Vectors are currently fixed but you can always edit the *.vmem file to change them.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, const char * argv[]) {
    
    static const char* START_ADDR_OPTION = "--start-addr";
    uint DEFAULT_START_ADDR = 0x0000;
    static const char* NMI_VECTOR = "00 90"; //fixed for now
    static const char* INT_VECTOR = "00 A0"; //fixed for now
    static const char* VECTOR_HEADER = "@FFFA //Interrupt and Reset Vectors:\n";
    static const char* NMI_VECTOR_COMMENT = "//NMI Vector\n";
    static const char* RESET_VECTOR_COMMENT = "//RESET Vector\n";
    static const char* INT_VECTOR_COMMENT = "//INTERRUPT Vector\n";

    
    if (argc < 2) {
        printf("Usage: memv yourcode.bin\n");
        return 0;
    }
    
    //open the input file
    FILE* in_file = fopen(argv[1], "rb");
    if (in_file == 0) {
        printf("no such file as: %s\n", argv[1]);
        return 0;
    }
    
    //get start address
    char start_addr[5];
    sprintf(start_addr, "%04x", DEFAULT_START_ADDR);
    if (argc >= 4) {
        //get optional start address
        if (strcmp(argv[2], START_ADDR_OPTION) == 0) {
            //get start address
            uint start_addr_num;
            if (sscanf(argv[3], "%x", &start_addr_num) == 1) {
                sprintf(start_addr, "%04x", start_addr_num);
            } else {
                printf("Unable to convert start address: %s, using default 0x0000.\n", argv[3]);
            }
        }
    }
    
    //generate the output name from the input file name but with the extension ".vmem"
    char *output_file_name = malloc(strlen(argv[1] + 5)); //+5 to make sure we have room for our extension
    if (output_file_name == NULL) {
        printf("Error: unable to generate output file name.\n");
        fclose(in_file);
        return 0;
    }
    strcpy(output_file_name, argv[1]);
    sscanf(output_file_name, "%[^.]", output_file_name);
    sprintf(output_file_name, "%s.vmem", output_file_name);
    
    //open the output file
    FILE* out_file = fopen(output_file_name, "w");
    if (out_file == 0) {
        printf("unable to open output file for writing.\n");
        fclose(in_file);
        free(output_file_name);
        return 0;
    }
    
    //write the contents
    int num;
    do {
          num = fgetc(in_file);
          if( feof(in_file) ) {
             break ;
          }
        fprintf(out_file, "%02x\n", num);
       } while(1);
    
    //write the vectors at the end
    //we need to write the addresses in reverse order since the 6502 reads the low address first.
    //Hence 0400 needs to be writen as 00 04
    char high_addr[3];
    char low_addr[3];
    fprintf(out_file, "%s", VECTOR_HEADER);
    fprintf(out_file, "%s %s", NMI_VECTOR, NMI_VECTOR_COMMENT);
    //reset vector
    strncpy(high_addr, start_addr, 2);
    strncpy(low_addr, start_addr+2, 2);
    fprintf(out_file, "%s %s %s", low_addr, high_addr, RESET_VECTOR_COMMENT);
    //interrupt vector
    fprintf(out_file, "%s %s", INT_VECTOR, INT_VECTOR_COMMENT);
    
    //shutdown
    fclose(in_file);
    fclose(out_file);
    free(output_file_name);
    
    //we're done!
    printf("Finished writing %s\n", output_file_name);
    return 0;
}


