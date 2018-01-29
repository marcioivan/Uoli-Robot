.global set_motor_speed
.global set_motors_speed
.global read_sonar
.global read_sonars
.global register_proximity_callback
.global add_alarm
.global get_time
.global set_time

.align 4

set_motor_speed:

    stmfd sp!, {r7, lr}
    ldrb r1, [r0]                   @ acesso a motor.id
    ldrb r2, [r0, #1]               @ acesso a motor.speed
    stmfd sp!, {r1-r2}
    mov r7, #18
    svc 0x0
    add sp, sp, #8
    ldmfd sp!, {r7, pc}

set_motors_speed:

    stmfd sp!, {r7, lr}
    ldrb r2, [r0, #1]               @ Acesso a motor0.speed
    ldrb r3, [r1, #1]               @ Acesso a motor1.speed
    stmfd sp!, {r2-r3}
    mov r7, #19
    svc 0x0
    add sp, sp, #8
    ldmfd sp!, {r7, pc}

read_sonar:

    stmfd sp!, {r0, r7, lr}
    mov r7, #16
    svc 0x0
    add sp, sp, #4
    ldmfd sp!, {r7, pc}

read_sonars:

    stmfd sp!, {r7, lr}
    mov r0, r3                      @ i = start (r0)

    for:
        cmp r3, r1                  @ Se i > end
        bhi exit                    @ Sai do laco
        stmfd sp!, {r3}             @ Empilha sonar id atual
        mov r7, #16
        svc 0x0
        str r0, [r2, r3, LSL #2]    @ distances[i] = r0. Para se 'chegar' na posicao i do endereco de distances, desloca-se duas vezes 'i', para assim somar ao endereco r2 o valor i*4
        add sp, sp, #4              @ Desempilha sonar id
        add r3, r3, #1              @ i++
        b for

    exit:
        ldmfd sp!, {r7, pc}

register_proximity_callback:

    stmfd sp!, {r0-r2, r7, lr}
    mov r7, #17
    svc 0x0
    add sp, sp, #12
    ldmfd sp!, {r7, pc}

add_alarm:

    stmfd sp!, {r0-r1, r7, lr}
    mov r7, #22
    svc 0x0
    add sp, sp, #8
    ldmfd sp!, {r7, pc}

get_time:

    stmfd sp!, {r7, lr}
    mov r1, r0                      @ Salva endereco de *t em outro registrador para depois salvar retorno (r0 'novo') nele
    mov r7, #20
    svc 0x0
    str r0, [r1]                    @ Armazena retorno em *t
    ldmfd sp!, {r7, pc}

set_time:

    stmfd sp!, {r0, r7, lr}
    mov r7, #21
    svc 0x0
    add sp, sp, #4
    ldmfd sp!, {r7, pc}
