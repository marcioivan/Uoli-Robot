.org 0x0
.section .iv,"a"

_start:

interrupt_vector:

@org 0x00
    b RESET_HANDLER
.org 0x08
    b SVC_HANDLER
.org 0x18
    b IRQ_HANDLER

.org 0x100
.text

RESET_HANDLER:

    @ Set interrupt table base address on coprocessor 15.
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0

    @ Constantes para os enderecos do GPT
    .set GPT_CR,             	 0x53FA0000
    .set GPT_PR,       		   	 0x4
    .set GPT_OCR1,				 0x10
    .set GPT_IR,				 0xC
    .set GPT_CNT,				 0x24

    @ Constante para a velocidade com que o tempo do sistema passa
    .set TIME_SZ,                107

    ldr	r1, =GPT_CR

    mov r0, #0x00000041
    str r0, [r1]
    mov r0, #0
    str r0, [r1, #GPT_PR]
    mov r0, #TIME_SZ
    str r0, [r1, #GPT_OCR1]
    mov r0, #1
    str	r0, [r1, #GPT_IR]

    @ Zera o contador
    ldr r1, =SYSTEM_TIME
    mov r0, #0
    str r0, [r1]

SET_TZIC:

    @ Constantes para os enderecos do TZIC
    .set TZIC_BASE,              0x0FFFC000
    .set TZIC_INTCTRL,           0x0
    .set TZIC_INTSEC1,           0x84
    .set TZIC_ENSET1,            0x104
    .set TZIC_PRIOMASK,          0xC
    .set TZIC_PRIORITY9,         0x424

    @ Liga o controlador de interrupcoes
    @ R1 <= TZIC_BASE

    ldr	r1, =TZIC_BASE

    @ Configura interrupcao 39 do GPT como nao segura
    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_INTSEC1]

    @ Habilita interrupcao 39 (GPT)
    @ reg1 bit 7 (gpt)

    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_ENSET1]

    @ Configure interrupt39 priority as 1
    @ reg9, byte 3

    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000
    mov r2, #1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    @ Configure PRIOMASK as 0
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Habilita o controlador de interrupcoes
    mov	r0, #1
    str	r0, [r1, #TZIC_INTCTRL]

    @instrucao msr - habilita interrupcoes
    msr  CPSR_c, #0x13           @ SUPERVISOR mode, IRQ/FIQ enabled

SET_GPIO:

    @ Constantes para os enderecos do GPIO
    .set GPIO_BASE,              0x53F84000
    .set GPIO_DR,                0x0
    .set GPIO_GDIR,              0x4
    .set GPIO_PSR,               0x8

    @ Liga o controlador de entradas e saidas
    @ R1 <= GPIO_BASE

    ldr	r1, =GPIO_BASE

    @ Indica pinos de entrada e saida em GDIR
    ldr r0, =0b11111111111111000000000000111110
    str r0, [r1, #GPIO_GDIR]

SVC_HANDLER:
/*
    @ Salva r12 antes de usa-lo para salvar SPSR que sera perdido ao mudar para o modo System
    stmfd sp!, {r12}
    mrs r12, SPSR_svc

    @ Muda para modo System para poder acessar a pilha do User nas funcoes da syscall
    msr CPSR_c, #0x1F

    @ Salva r4-r11 para uso posterior. Dever do callee-save
    stmfd sp!, {r4-r11, lr}

    @ Analisa valor da syscall armazenado em r7
    cmp r7, #16
    beq read_sonar

    cmp r7, #17
    beq register_proximity_callback

    cmp r7, #18
    beq set_motor_speed

    cmp r7, #19
    beq set_motors_speed

    cmp r7, #20
    beq get_time

    cmp r7, #21
    beq set_time

    cmp r7, #22
    beq add_alarm

    @ Funcoes do syscall @

    read_sonar:

        @ Acessa parametro empilhado em user
        ldr r1, [sp]

        @ Verifica se ID do sonar eh valido. Se ID > 15, retorna -1
        cmp r1, #15
        bhi return_one_neg

        @ Primeiro o ID eh escrito em um formato de 4 bits, e apos isso este ID eh deslocado para os pinos em que deveriam estar (SONAR_MUX)em DR . Ao mesmo tempo, ja se esta sendo setado Trigger para 0.
        and r1, r1 , #0b1111
        mov r1, r1, lsl #2

        @ Carrega base do GPIO
        ldr r2, =GPIO_BASE

        @ SONAR_MUX <- Sonar ID e Trigger <- 0
        str r1, [r2, #GPIO_DR]

        @ Gera delay de 15ms
        mov r0, #150
        bl delay

        @ Trigger <- 1
        ldr r1, [r2, #GPIO_DR]
        orr r1, r1, #0b10
        str r1, [r2, #GPIO_DR]

        @ Delay de 15ms
        mov r0, #150
        bl delay

        @ Trigger <- 0
        ldr r1, [r2, #GPIO_DR]
        eor r1, r1, #0b10
        str r1, [r2, #GPIO_DR]

        check_flag:
            ldr r1, [r2, #GPIO_DR]
            and r1, r1, #0b1            @ Pega apenas valor do bit correspondente a Flag
            cmp r1, #1
            beq get_dist                @ Flag == 1 , entao distancia esta em SONAR_DATA
            mov r0, #100                @ Se nao, realiza delay de 10ms e repete a verificacao
            bl delay
            b check_flag

        @ Armazena valor salvo em SONAR_DATA, no registrador r0 (Local de retorno)
        get_dist:
            ldr r1, [r2, #GPIO_DR]
            ldr r0, =0b111111111111000000
            and r1, r1, r0              @ Considera apenas pinos referentes ao SONAR_DATA
            mov r0, r1, lsr #6
            b end_svc                   @ Encerra read sonar

    register_proximity_callback:

        ldr r3, [sp]
        ldr r2, [sp, #4]
        ldr r1, [sp, #8]



    set_motor_speed:

        ldr r2, [sp]
        ldr r1, [sp, #4]



    set_motors_speed:

        ldr r2, [sp]
        ldr r1, [sp, #4]

    get_time:


    set_time:

        ldr r0, [sp]

    add_alarm:

        ldr r2, [sp]
        ldr r1, [sp, #4]

    @ Funcoes auxiliares usadas na implementacao das Syscall @

    return_one_neg:
        mov r0, #-1
        b end_svc

    return_two_neg:
        mov r0, #-2
        b end_svc

    delay:
        sub r0, r0, #1                  @ Contador que vai de N ate 0 para gerar um delay no sistema
        cmp r0, #0
        bhi delay
        mov pc, lr

    

    @ Encerra o SVC_HANDLER
    end_svc:
        ldmfd sp!, {r4-r11, lr}         @ Recupera registradores empilhados antes da implementacao
        msr CPSR_c, #0x13               @ Volta para modo supervisor
        msr SPSR_svc, r12               @ Recupera valor do modo user (SPSR salvo em r12)
        ldmfd sp!, {r12}                @ Recupera registrador salvo
    */    movs pc, lr                     @ Retorna para modo User

IRQ_HANDLER:

    @ Constante para o endereco de GPT_SR
    .set GPT_SR,                        0x53FA0008

    ldr r1, =GPT_SR

    mov r0, #0x1
    str r0, [r1]
    ldr r1, =SYSTEM_TIME
    ldr r0, [r1]
    add r0, r0, #1
    str r0, [r1]
    sub lr, lr, #4

    movs pc, lr

@ Sessao de dados
.data

.set SYSTEM_TIME,                       0x77801800

