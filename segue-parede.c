#include "bico.h"

// Teste: void turn_left(motor_cfg_t *left, motor_cfg_t *right)

void turn_right()
{
    unsigned int lateral_front, lateral_rear;
    motor_cfg_t motor;
    
    motor.id = 1;
    motor.speed = 0;
    set_motor_speed(&motor); // Desliga motor direito para o robo girar em sentido horario
    do
    {
        lateral_front = read_sonar(0);
        lateral_rear = read_sonar(15);
        
        if(lateral_front == lateral_rear)
        {
            motor.id = 0;
            motor.speed = 0;
            set_motor_speed(&motor); // Robo para de girar se estiver paralelo a parede
        }
    } while (lateral_front != lateral_rear);
}

void _start(void)
{
    unsigned int distance[16];
    motor_cfg_t left, right;
    
    // Seta IDs dos 'alteradores de velocidade'
    left.id = 0;
    left.speed = 25;
    right.id = 1;
    right.speed = 25;
    
    set_motors_speed(&left, &right); // Liga o robo
    
    // MODO: BUSCA PAREDE
    do
    {
        distance[3] = read_sonar(3);
        distance[4] = read_sonar(4);
    } while (distance[4] > 1200 && distance[3] > 1200 ); // Quando se aproximar da parede
    
    turn_right(); // Fica com a parede a esquerda do robo
    
    // MODO: SEGUE PAREDE
    set_motors_speed(&left, &right); // Apos paralelo a parede, robo volta a andar
    do
    {
        distance[0] = read_sonar(0);
        distance[3] = read_sonar(3);
        distance[4] = read_sonar(4);
        distance[15] = read_sonar(15);
        
        if(distance[0] == distance[15])
        {
            if(distance[4] < 1200 && distance[3] < 1200) // Robo devera virar a direita
            {
                turn_right();
                left.speed = 25;
                right.speed = 25;
                set_motors_speed(&left, &right);
                
                // Questao: Se eh um objeto, como verificar se 'esta paralelo?'
            }
        }
        else // Robo devera virar a esquerda
        {
            // Falta implementar este caso.
        }
    } while(1);
}
