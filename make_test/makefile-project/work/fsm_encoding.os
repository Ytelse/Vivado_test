
 add_fsm_encoding \
       {uartParser.mainSm} \
       { }  \
       {{0000 0000} {0001 0110} {0010 0111} {0011 1000} {0100 1001} {0101 1010} {1000 0001} {1001 0010} {1010 0011} {1011 0100} {1100 0101} }

 add_fsm_encoding \
       {uartParser.txSm} \
       { }  \
       {{000 000} {001 001} {100 010} {101 011} {110 100} }
