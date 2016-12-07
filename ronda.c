#include "bico.h"

void _start (void)
{
    unsigned int distance[16];
    motor_cfg_t left, right;
    
    // Seta IDs dos 'alteradores de velocidade'
    left.id = 0;
    left.speed = 0;
    right.id = 1;
    right.speed = 0;
    
    set_motors_speed(&left, &right); // Liga o robo
    
}
