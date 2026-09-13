bits 16
org 100h

COLOR_BORDE equ 15

; medidas del tablero
COLS  equ 10         
ROWS  equ 20          
CELL  equ 8           
X0    equ 121         ; donde empieza la columna 
Y0    equ 21          ; donde empieza la fila 


inicio:
    call iniciar_video
    call dibujar_tablero
    call limpiar_tablero

    call nueva_pieza
    call actualizar_pieza


.bucle:
    call leer_tecla

    cmp al, 27
    je .salir

    cmp ah, 4Bh
    je .izquierda

    cmp ah, 4Dh
    je .derecha

    cmp ah, 50h
    je .abajo

    jmp .bucle


.izquierda:
    dec byte [pieza_col]

    call validar_posicion
    cmp al, 1
    je .actualizar

    inc byte [pieza_col]

    jmp .bucle


.derecha:
    inc byte [pieza_col]

    call validar_posicion
    cmp al, 1
    je .actualizar

    dec byte [pieza_col]

    jmp .bucle


.abajo:
    inc byte [pieza_row]

    call validar_posicion
    cmp al, 1
    je .actualizar

    dec byte [pieza_row]

    call fijar_pieza
    call nueva_pieza

    call actualizar_pieza
    jmp .bucle


.actualizar:
    call actualizar_pieza
    jmp .bucle


.salir:
    call restaurar_video
    call salir_programa



iniciar_video:
    mov ax, 0013h
    int 10h

    mov ax, 0A000h
    mov es, ax
    ret



; limpiar la matriz 
limpiar_tablero:
    push ax
    push cx
    push di

    mov di, tablero
    mov cx, COLS*ROWS
    xor al, al

.lt:
    mov [di], al
    inc di
    loop .lt

    pop di
    pop cx
    pop ax
    ret



; actualiza lo que se ve en pantalla
actualizar_pieza:
    call dibujar_matriz
    call dibujar_pieza_activa
    ret



; validar que la pieza no salga de los bordes
; y que no choque con una posicion ocupada
; AL = 1 si la posicion es valida
; AL = 0 si la posicion es invalida
validar_posicion:
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov al, [pieza_id]
    mov ah, 0

    mov si, ax
    shl si, 3
    add si, formas

    mov cx, 4


.vp:
    ; validar columna

    xor ax, ax
    mov al, [pieza_col]

    xor bx, bx
    mov bl, [si]

    add ax, bx

    cmp ax, COLS
    jae .invalida

    mov bp, ax

    inc si


    ; validar fila

    xor ax, ax
    mov al, [pieza_row]

    xor bx, bx
    mov bl, [si]

    add ax, bx

    cmp ax, ROWS
    jae .invalida

    inc si


    ; calcular posicion dentro de la matriz
    ; posicion = fila * 10 + columna

    mov dx, COLS
    mul dx

    add ax, bp

    mov di, ax


    ; revisar si esa posicion ya esta ocupada

    cmp byte [tablero + di], 0
    jne .invalida


    loop .vp


    mov al, 1
    jmp .fin


.invalida:
    mov al, 0


.fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret



; guardar la pieza actual en la matriz
fijar_pieza:
    mov al, [pieza_id]
    call colocar_pieza
    ret



; crear una nueva pieza
nueva_pieza:
    mov byte [pieza_col], 3
    mov byte [pieza_row], 0

    call pieza_aleatoria

    ret



; generar una pieza aleatoria entre 0 y 4
pieza_aleatoria:
    push ax
    push bx
    push cx
    push dx

    mov ah, 00h
    int 1Ah

    mov ax, dx

    xor dx, dx

    mov bx, 5
    div bx

    mov [pieza_id], dl

    pop dx
    pop cx
    pop bx
    pop ax
    ret



; colocar la pieza en la posicion inicial
; AL es el id de la pieza 0=O 1=T 2=I 3=L 4=Z
colocar_pieza:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov ah, 0
    mov bp, ax                 

    mov bx, bp
    mov dh, [colores + bx]     ; color de la puieza

    mov si, bp
    shl si, 3                  ; id * 8
    add si, formas             

    mov cx, 4                 


.cp:
    mov al, [si]               
    add al, [pieza_col]          
    mov bl, al
    inc si

    mov al, [si]              
    add al, [pieza_row]         
    inc si

    mov ah, 0                  

    push dx                   

    mov dx, COLS
    mul dx                    

    mov bh, 0
    add ax, bx                 

    mov di, ax

    pop dx                   

    mov [tablero + di], dh     ; gaurdar el color en la matriz

    loop .cp


    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; dibujar la pieza que se esta moviendo
dibujar_pieza_activa:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp


    mov al, [pieza_id]
    mov ah, 0


    mov bx, ax
    mov dh, [colores + bx]


    mov si, ax
    shl si, 3
    add si, formas


    mov cx, 4


.dpa:
    ; calcular X

    xor ax, ax
    mov al, [si]

    add al, [pieza_col]

    shl ax, 3
    add ax, X0

    mov di, ax

    inc si


    ; calcular Y

    xor ax, ax
    mov al, [si]

    add al, [pieza_row]

    shl ax, 3
    add ax, Y0

    mov bx, ax

    inc si


    mov ax, di
    mov dl, dh

    call dibujar_bloque


    loop .dpa


    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; dibujar toda la matriz 
dibujar_matriz:
    push ax
    push bx
    push cx
    push dx
    push si

    xor si, si


.dm:
    mov ax, si
    xor dx, dx

    mov cx, COLS
    div cx                     


    push ax                    


    mov ax, dx                
    shl ax, 3                 
    add ax, X0                 


    pop cx                    


    push ax                   


    mov ax, cx
    shl ax, 3                  
    add ax, Y0                 


    mov bx, ax


    pop ax                     


    mov dl, [tablero + si]     


    call dibujar_bloque


    inc si

    cmp si, COLS*ROWS
    jl .dm


    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



dibujar_bloque:

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bp, ax
    mov si, bx
    mov bl, dl

    mov cx, 8


.fila:;Aqui se hace un calculo para la posicion del pixel por como se guarda vga 67*320+100 con nuestros datos arriba

    push cx

    mov ax, si
    mov cx, 320
    mul cx

    add ax, bp
    mov di, ax

    mov cx, 8


.pixel:
    ;esto pinta hacia la derecha desde los 100 pixeles 8 pixeles hacia la derecha

    mov [es:di], bl
    inc di
    loop .pixel

    inc si ;baja linea

    pop cx
    loop .fila


    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



dibujar_tablero:;se definen los bordes del tablero y luego se dibuja desde el borde al pixel definido

    mov ax, 120
    mov bx, 20
    mov cx, 82; mide 82 pixeles
    mov dl, COLOR_BORDE
    call linea_horizontal


    mov ax, 120
    mov bx, 181
    mov cx, 82
    mov dl, COLOR_BORDE
    call linea_horizontal


    mov ax, 120
    mov bx, 20
    mov cx, 162;mide 162 pixeles
    mov dl, COLOR_BORDE
    call linea_vertical


    mov ax, 201
    mov bx, 20
    mov cx, 162
    mov dl, COLOR_BORDE
    call linea_vertical

    ret



linea_horizontal:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bp, ax
    mov si, bx
    mov bl, dl

    mov ax, si
    mov di, 320
    mul di

    add ax, bp
    mov di, ax


.ph:
    mov [es:di], bl
    inc di
    loop .ph


    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



linea_vertical:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bp, ax
    mov si, bx
    mov bl, dl


.pv:
    mov ax, si
    mov di, 320
    mul di

    add ax, bp
    mov di, ax

    mov [es:di], bl

    inc si
    loop .pv


    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



leer_tecla:
    mov ah, 00h
    int 16h
    ret



restaurar_video:
    mov ax, 0003h
    int 10h
    ret



salir_programa:
    mov ax, 4C00h
    int 21h



; el color de cada pieza
colores:
    db 14      ; O
    db 13      ; T
    db 11      ; I
    db 12      ; L
    db 4       ; Z



; las 5 piezas cada una con sus 4 bloques en pares 
formas:
    db 0,0, 1,0, 0,1, 1,1      ; O
    db 1,0, 0,1, 1,1, 2,1      ; T
    db 0,1, 1,1, 2,1, 3,1      ; I
    db 2,0, 0,1, 1,1, 2,1      ; L
    db 0,0, 1,0, 1,1, 2,1      ; Z



; posicion y tipo de la pieza actual
pieza_col db 3
pieza_row db 0
pieza_id  db 0



; la matriz del tablero 
tablero: times COLS*ROWS db 0