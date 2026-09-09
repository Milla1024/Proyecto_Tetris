bits 16
org 100h

COLOR_1 equ 13
COLOR_2 equ 14
COLOR_3 equ 2
COLOR_BORDE equ 15


inicio:;probando dibujar una forma en pantalla
    call iniciar_video
    mov ax, 120 
    mov bx, 99 
    call dibujar_bloque
    mov ax, 128 
    mov bx, 99 
    call dibujar_bloque
    mov ax, 120 
    mov bx, 91 
    call dibujar_bloque
    call dibujar_tablero

    call esperar_tecla
    call restaurar_video
    call salir_programa


iniciar_video:
    mov ax, 0013h
    int 10h

    mov ax, 0A000h
    mov es, ax
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

fila_bloque:;Aqui se hace un calculo para la posicion del pixel por como se guarda vga 60*320+100 con nuestros datos arriba
    push cx

    mov ax, si
    mov cx, 320
    mul cx

    add ax, bp
    mov di, ax

    mov cx, 8

pixel_bloque:
    ;esto pinta hacia la derecha desde los 100 pixeles 8 pixeles hacia la derecha
    mov [es:di], bl
    inc di
    loop pixel_bloque

    inc si ;baja linea

    pop cx
    loop fila_bloque

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
    mov cx, 81; mide 81 pixeles
    mov dl, COLOR_BORDE
    call linea_horizontal

    mov ax, 120
    mov bx, 180
    mov cx, 81
    mov dl, COLOR_BORDE
    call linea_horizontal

    mov ax, 120
    mov bx, 20
    mov cx, 161;mide 161 pixeles
    mov dl, COLOR_BORDE
    call linea_vertical

    mov ax, 200
    mov bx, 20
    mov cx, 161
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

pixel_horizontal:
    mov [es:di], bl
    inc di
    loop pixel_horizontal

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

pixel_vertical:
    mov ax, si
    mov di, 320
    mul di

    add ax, bp
    mov di, ax

    mov [es:di], bl

    inc si
    loop pixel_vertical

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


esperar_tecla:
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