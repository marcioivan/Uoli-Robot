#include "bico.h"

void _start(void)
{
    unsigned int distance[16];
    
    distance[3] = read_sonar(3);
    distance[4] = read_sonar(4);
    
//    printf("DISTANCIA 3: %d\n", distance[3]);
//    printf("DISTANCIA 4: %d\n", distance[4]);
}
