; Compilar com: nasm -f bin kernelius.asm -o kernelius.bin

org 0x8000              ; define o endereço de origem

start:
    ; Configuração Inicial

    mov ax, 0x0003      ; usa a função da BIOS para definir o modo de vídeo texto (80x25)
    int 0x10            ; equivalente a limpar a tela

password_prompt:
    ; interface com o Usuário

    mov si, prompt_msg  ; carrega o endereço da mensagem de prompt em SI
    call print_string   ; chama a sub-rotina para imprimir a mensagem na tela

    mov di, input_buffer ; aponta DI para o buffer que vai armazenar a entrada do usuário

read_loop:
    ; Loop de Leitura do Teclado

    mov ah, 0x00        ; função da BIOS: 0x00 = Ler caractere do teclado
    int 0x16            ; espera o usuário pressionar uma tecla. O caractere fica em AL.

    cmp al, 0x0D        ; compara o caractere com 0x0D (código ASCII para a tecla Enter)
    je check_passwords  ; se for Enter, pula para a lógica de verificação de senhas

    mov ah, 0x0E        ; função da BIOS: 0x0E = Escrever caractere na tela
    int 0x10            ; imprime o caractere digitado

    stosb               ; armazena o caractere de AL no buffer [ES:DI] e incrementa DI
    jmp read_loop       ; volta ao início do loop para ler o próximo caractere


; lógica de verificação de senhas diferentes

check_passwords:
    mov byte [di], 0    ; adiciona um caractere nulo no final da entrada do usuário para formar uma string

    ; verifica se foi coelho
    mov si, password_coelho ; aponta SI para a string da senha "coelho"
    mov di, input_buffer    ; aponta DI para a string de entrada do usuário
    mov cx, 6               ; define o contador CX para o tamanho de "coelho"
    repe cmpsb              ; compara byte a byte enquanto forem iguais
    je success_coelho       ; se for igual, mostra o coelho

    ; verifica se foi gato
    mov si, password_gato   ; aponta SI para a string da senha "gato".
    mov di, input_buffer    ; IMPORTANTE: Reseta DI para o início da entrada do usuário.
    mov cx, 4               ; define o contador CX para o tamanho de "gato".
    repe cmpsb              ; compara byte a byte
    je success_gato         ; se for igual, mostra o gato

    ; verifica se foi peixe
    mov si, password_peixe  ; aponta SI para a string da senha "peixe"
    mov di, input_buffer    ; reseta DI de novo
    mov cx, 5               ; define o contador CX para o tamanho de "peixe"
    repe cmpsb              ; compara byte a byte
    je success_peixe        ; se for igual, mostra o peixe

    ; se não era nenhuma das três, falha
    jmp failure             ; se a senha inserida não é uma das tres, pula para a rotina de falha

failure:
    mov si, error_msg       ; carrega o endereço da mensagem de erro
    call print_string       ; imprime a mensagem
    jmp password_prompt     ; volta para o início, pedindo a senha novamente


; o que rola se der certo e qual animal é mostrado

success_coelho:
    mov si, success_msg     ; carrega a mensagem de sucesso
    call print_string       ; imprime a mensagem
    mov si, msg_ptrs_coelho ; aponta SI para a lista de ponteiros da animação do coelho
    jmp start_animation     ; pula para o início da rotina de animação

success_gato:
    mov si, success_msg     ; carrega a mensagem de sucesso
    call print_string       ; imprime a mensagem
    mov si, msg_ptrs_gato   ; aponta SI para os ponteiros da animação do gato
    jmp start_animation     ; pula para a animação

success_peixe:
    mov si, success_msg     ; carrega a mensagem de sucesso
    call print_string       ; imprime
    mov si, msg_ptrs_peixe  ; aponta SI para os ponteiros da animação do peixe
    jmp start_animation     ; pula para a animação


; SUB-ROTINAS E DADOS

print_string:
.loop:
    lodsb               ; carrega o byte de [SI] em AL e incrementa SI
    or al, al           ; verifica se o byte carregado (AL) é zero
    jz .done            ; se for zero (fim da string), encerra a sub-rotina
    mov ah, 0x0E        ; prepara para imprimir o caractere em AL
    int 0x10            ; chama a BIOS para escrever o caractere
    jmp .loop           ; loop para o próximo caractere
.done:
    ret                 ; retorna da sub-rotina


; variáveis e mensagens

prompt_msg      db 'Bem vindo ao zoologico! Temos um gato, um coelho e um peixe! Escolha seu animal: ', 0
password_gato   db 'gato'
password_coelho db 'coelho'
password_peixe  db 'peixe'
error_msg       db 0x0D, 0x0A, 'Opa, nao temos esse animal. Tente de novo!', 0x0D, 0x0A, 0x0D, 0x0A, 0
success_msg     db 0x0D, 0x0A, 'Aqui, o animalzinho de sua escolha!', 0x0D, 0x0A, 0x0D, 0x0A, 0
input_buffer:   times 64 db 0   ; Reserva 64 bytes para a entrada do usuário


; código pra animação

start_animation:
next_msg:
    lodsw               ; carrega uma word (2 bytes, o ponteiro do desenho) de [SI] para AX e incrementa SI
    or ax, ax           ; verifica se o ponteiro carregado é zero
    jz done             ; se for zero, significa o fim da animação

    cmp ax, 1           ; compara se o valor é 1, nosso código para "delay"
    je do_delay         ; se for, pula para a rotina de delay

    push si             ; salva o ponteiro atual da lista de mensagens na pilha
    mov si, ax          ; move o ponteiro do desenho (que está em AX) para SI

print_loop:
    lodsb               ; carrega um caractere do desenho para AL
    or al, al           ; verifica se é o fim da linha (caractere nulo)
    jz print_end        ; se for, termina de imprimir a linha
    mov ah, 0x0E        ; prepara para imprimir o caractere
    int 0x10            ; imprime
    jmp print_loop      ; loop para o próximo caractere da linha

print_end:
    mov ah, 0x0E        ; prepara para imprimir
    mov al, 0x0D        ; imprime um Carriage Return
    int 0x10
    mov al, 0x0A        ; imprime um Line Feed (pula para a próxima linha na tela)
    int 0x10
    pop si              ; restaura o ponteiro da lista de mensagens da pilha
    jmp next_msg        ; pula para processar a próxima linha do desenho

do_delay:
    call delay          ; chama a sub-rotina de delay
    jmp next_msg        ; volta para processar o próximo item da lista

done:
    jmp $               ; trava o sistema em um loop infinito quando a animação termina

delay:
    ; sub-rotina de delay baseada em loops para pausar a execução.
    push dx
    push cx
    mov dx, 0x0FFF
delay_outer_loop:
    mov cx, 0xFFFF
delay_inner_loop:
    dec cx
    jnz delay_inner_loop
    dec dx
    jnz delay_outer_loop
    pop cx
    pop dx
    ret

; Dados da Animação
; listas de ponteiros: cada lista aponta para as strings que formam um desenho.
msg_ptrs_gato:
    dw msgAA, msgAB, msgAC, msgAD, msgAE, msgAF, msgAG, msgAH, msgAI, msgAJ, msgAK
    dw 0

msg_ptrs_coelho:
    dw msgAM, msgAN, msgAO, msgAP, msgAQ, msgAR, msgAS, msgAT, msgAU, msgAV, msgAW
    dw 0

msg_ptrs_peixe:
    dw msgAY, msgAZ, msgBA, msgBC, msgBD, msgBE, msgBF
    dw 0

; los animalitos super fofitos
msgAA db "   @          @      ", 0
msgAB db "  @@@        @@@     ", 0
msgAC db " @   @      @   @    ", 0
msgAD db " @    @@@@@@    @    ", 0
msgAE db " @  @        @  @    ", 0
msgAF db " @  @        @  @    ", 0
msgAG db " @              @    ", 0
msgAH db " @    @ @ @     @    ", 0
msgAI db " @     @ @      @    ", 0
msgAJ db "  @            @     ", 0
msgAK db "   @@@@@@@@@@@@      ", 0
msgAL db "                     ", 0
msgAM db "    @@  @@           ", 0
msgAN db "    @@  @@           ", 0
msgAO db "    @@  @@           ", 0
msgAP db "    @@  @@           ", 0
msgAQ db "  @@@@@@@@@@         ", 0
msgAR db " @  @    @  @        ", 0
msgAS db " @  @    @  @        ", 0
msgAT db " @          @        ", 0
msgAU db " @   @  @   @        ", 0
msgAV db " @    @@    @        ", 0
msgAW db "  @@@@@@@@@@         ", 0
msgAX db "                     ", 0
msgAY db " @@     @@@@@@@      ", 0
msgAZ db " @ @   @       @     ", 0
msgBA db " @  @  @     @  @    ", 0
msgBC db " @   @@    @     @   ", 0
msgBD db " @  @  @    @@  @    ", 0
msgBE db " @ @   @       @     ", 0
msgBF db " @@     @@@@@@@      ", 0
