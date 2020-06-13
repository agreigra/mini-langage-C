/* CODE GENERE PAR LE COMPILATEUR SIMPLE */

#include "../test/test.h"

#include<stdlib.h>
#include<stdbool.h>
#include<stdarg.h>
#include<stdio.h>
int main(void){
ri1 = 5;
a = ri1;
ri2 = 10;
b = ri2;
ri3 = a;
ri4 = b;
ri5 = ri3 < ri4;
if(!ri5) goto label1;
ri6 = a;
c = ri6;
goto label2;
label1:
ri7 = b;
c = ri7;
label2:
ri8 = a;
printf("a = %d\n",ri8);
ri9 = b;
printf("b = %d\n",ri9);
ri10 = c;
printf("c = %d\n",ri10);

return EXIT_SUCCESS;
}
