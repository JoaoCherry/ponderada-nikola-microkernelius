; compilar com: nasm -f bin boot.asm -o boot.bin

org 0x7c00              ; define o endereço de origem do código, onde a bios o carrega.

start:
    ; configuração dos segmentos e pilha 
    cli                 ; desabilita interrupções durante a configuração crítica.
    xor ax, ax          ; zera o registrador ax.
    mov ds, ax          ; define o data segment (ds) para 0.
    mov es, ax          ; define o extra segment (es) para 0.
    mov ss, ax          ; define o stack segment (ss) para 0.
    mov sp, 0x7c00      ; configura o ponteiro da pilha (stack pointer) para o início do código.
    sti                 ; habilita as interrupções novamente.

    ; leitura do kernel do disco
    mov ah, 0x02        ; função da bios: 0x02 = ler setores do disco.
    mov al, 3           ; número de setores para ler (o nosso kernel).
    mov ch, 0           ; cilindro 0.
    mov cl, 2           ; começa a ler a partir do setor 2 (setor 1 é o bootloader).
    mov dh, 0           ; cabeça de leitura 0.
    mov bx, 0x8000      ; endereço de memória (buffer) para onde carregar o kernel.
    int 0x13            ; chama a interrupção de disco da bios para executar a leitura.

    jc disk_error       ; se a leitura falhou (carry flag = 1), pula para o tratamento de erro.

    ; pulo para o kernel
    jmp 0x0000:0x8000   ; se a leitura deu certo, pula para o kernel em 0x0000:8000.

; tratamento de erro
disk_error:
    mov si, disk_error_msg  ; carrega o endereço da mensagem de erro em si.
.error_loop:
    mov ah, 0x0e        ; função da bios: 0x0e = escrever caractere.
    lodsb               ; carrega o caractere de [si] em al e incrementa si.
    cmp al, 0           ; verifica se é o fim da string (caractere nulo).
    je .hang            ; se for, para de imprimir.
    int 0x10            ; chama a bios para imprimir o caractere na tela.
    jmp .error_loop     ; loop para o próximo caractere.
.hang:
    jmp $               ; trava o sistema em um loop infinito.

disk_error_msg db "Erro ao carregar kernel.", 0

; preenchimento e assinatura de boot
; um setor de boot precisa ter 512 bytes e terminar com 0xaa55.
times 510-($-$$) db 0   ; preenche o resto do setor com zeros até o byte 510.
dw 0xaa55               ; assinatura de boot obrigatória. identifica o setor como inicializável.