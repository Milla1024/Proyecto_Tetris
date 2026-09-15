bits 16
org 100h

COLOR_BORDE equ 15
COLOR_FONDO equ 0

; medidas del tablero
COLS  equ 10         
ROWS  equ 20          
CELL  equ 8           
X0    equ 121         ; donde empieza la columna 
Y0    equ 21          ; donde empieza la fila 

; medidas del titulo de la portada
TITULO_X equ 18
TITULO_Y equ 45

inicio:
    call portada
    call iniciar_video
    call dibujar_tablero

    mov si, txt_juego
    mov dh, 2
    mov dl, 27
    mov bl, 15
    call imprimir

    call limpiar_tablero
    call leer_ticks
    mov[ticks_previos], ax

    call nueva_pieza
    call actualizar_pieza


.bucle:
    call revisar_caida          ; la pieza baja sola con el tiempo

    mov ah, 01h                
    int 16h
    jz .bucle                  

    mov ah, 00h                
    int 16h

    cmp al, 27
    je .salir

    cmp ah, 48h                 ; flecha arriba es rotar
    je .rotar

    cmp ah, 4Bh
    je .izquierda

    cmp ah, 4Dh
    je .derecha

    cmp ah, 50h
    je .abajo

    jmp .bucle


.rotar:
    call rotar_pieza
    jmp .actualizar


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


portada:
    call iniciar_video            ;
    mov byte [opcion], 0

.redibujar:
    call limpiar_pantalla
    call dibujar_marco
    call dibujar_titulo
    call dibujar_menu
    call dibujar_ayuda

.tecla:
    call leer_tecla

    cmp ah, 48h                   ; arriba
    je .arriba
    cmp ah, 50h                   ; abajo
    je .abajo
    cmp al, 13                    ; ENTER
    je .enter
    cmp al, 27                    ; ESC
    je .salir
    jmp .tecla

.arriba:
    mov byte [opcion], 0
    jmp .redibujar
.abajo:
    mov byte [opcion], 1
    jmp .redibujar

.enter:
    cmp byte [opcion], 0
    je .jugar                     ; INICIAR
.salir:
    call restaurar_video
    call salir_programa

.jugar:
    ret



; llena toda la pantalla con el color de fondo
limpiar_pantalla:
    push ax
    push cx
    push di
    cld
    xor di, di
    mov cx, 64000
    mov al, COLOR_FONDO
    rep stosb
    pop di
    pop cx
    pop ax
    ret



; marco decorativo
dibujar_marco:
    mov ax, 8
    mov bx, 8
    mov cx, 304
    mov dl, 8
    call linea_horizontal

    mov ax, 8
    mov bx, 190
    mov cx, 304
    mov dl, 8
    call linea_horizontal

    mov ax, 8
    mov bx, 8
    mov cx, 183
    mov dl, 8
    call linea_vertical

    mov ax, 311
    mov bx, 8
    mov cx, 183
    mov dl, 8
    call linea_vertical
    ret



; dibuja tetris 67
dibujar_titulo:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, titulo_font
    mov byte [t_glifo], 0

.tg:                              
    mov bl, [t_glifo]
    mov bh, 0
    mov al, [titulo_colores + bx]
    mov [t_color], al

    mov byte [t_fila], 0

.tf:                              
    mov al, [si]
    mov [t_pat], al
    inc si

    mov byte [t_col], 0

.tc:                           
    mov cl, [t_col]
    mov al, 4
    shr al, cl                     
    and al, [t_pat]
    jz .sig_col                    


    mov al, [t_glifo]
    mov ah, 0
    mov bx, ax
    shl bx, 5
    mov al, [t_col]
    mov ah, 0
    shl ax, 3
    add bx, ax
    add bx, TITULO_X

    ; y = TITULO_Y + fila*8
    mov al, [t_fila]
    mov ah, 0
    shl ax, 3
    add ax, TITULO_Y

    xchg ax, bx                     
    mov dl, [t_color]
    call dibujar_bloque

.sig_col:
    inc byte [t_col]
    cmp byte [t_col], 3
    jl .tc

    inc byte [t_fila]
    cmp byte [t_fila], 5
    jl .tf

    inc byte [t_glifo]
    cmp byte [t_glifo], 9
    jl .tg

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; dibuja las dos opciones la elegida en amarillo
dibujar_menu:
    mov bl, 8
    cmp byte [opcion], 0
    jne .a
    mov bl, 14
.a:
    mov si, txt_iniciar
    mov dh, 15
    mov dl, 16
    call imprimir

    mov bl, 8
    cmp byte [opcion], 1
    jne .b
    mov bl, 14
.b:
    mov si, txt_salir
    mov dh, 17
    mov dl, 17
    call imprimir
    ret



dibujar_ayuda:
    mov si, txt_ayuda
    mov dh, 22
    mov dl, 5
    mov bl, 7
    call imprimir
    ret



; imprime texto con la fuente de la bios
imprimir:
    push ax
    push bx
    push cx
    push dx
    push si

    cld
    mov cl, bl                     

    mov ah, 02h                     ; posicionar cursor
    xor bh, bh
    int 10h

.pc:
    lodsb
    or al, al
    jz .fin
    mov ah, 0Eh
    mov bl, cl
    xor bh, bh
    int 10h
    jmp .pc
.fin:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


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


leer_ticks:
    push es 
    push bx
    mov bx, 0040h
    mov es, bx
    mov ax, [es:006Ch]
    pop bx
    pop es
    ret
; baja la pieza sola cuando pasa suficiente tiempo
revisar_caida:
    push ax
    push bx

    call leer_ticks
    mov bx, ax
    sub ax, [ticks_previos]
    cmp ax, [velocidad]
    jb .fin                     ; todavia  no baja

    mov [ticks_previos], bx     ; reiniciar el conteo

    inc byte [pieza_row]
    call validar_posicion
    cmp al, 1
    je .baja

    ;si no pudo bajar se fija y sale una nueva
    dec byte [pieza_row]
    call fijar_pieza
    call nueva_pieza

.baja:
    call actualizar_pieza

.fin:
    pop bx
    pop ax
    ret

puntero_forma:
    push ax
    push bx

    mov al, [pieza_id]
    mov ah, 0
    mov bx, ax
    mov dh, [colores + bx]      

    mov si, ax
    shl si, 5                   ; id * 32 (4 rotaciones de 8 bytes)

    mov al, [pieza_rot]
    mov ah, 0
    shl ax, 3                   ; rotacion * 8
    add si, ax

    add si, formas

    pop bx
    pop ax
    ret



; girar la pieza si no cabe la deja como estaba
rotar_pieza:
    push ax
    push bx

    mov bl, [pieza_rot]         ; se guarda la rotacion actual
    inc byte [pieza_rot]
    and byte [pieza_rot], 3     ; (rotacion + 1) entre 0 y 3

    call validar_posicion
    cmp al, 1
    je .ok

    mov [pieza_rot], bl        

.ok:
    pop bx
    pop ax
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

   call puntero_forma   ;si=forma actual

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
    mov byte [pieza_rot], 0

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

    call puntero_forma       

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

    call puntero_forma

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
;cada pieza con su rotacion propia ahora 
formas:
    ; O  las rotaciones de este son iguales no cambia la vdd
    db 0,0, 1,0, 0,1, 1,1
    db 0,0, 1,0, 0,1, 1,1
    db 0,0, 1,0, 0,1, 1,1
    db 0,0, 1,0, 0,1, 1,1

    ; T
    db 1,0, 0,1, 1,1, 2,1
    db 0,0, 0,1, 1,1, 0,2
    db 0,0, 1,0, 2,0, 1,1
    db 1,0, 0,1, 1,1, 1,2

    ; I
    db 0,1, 1,1, 2,1, 3,1
    db 0,0, 0,1, 0,2, 0,3
    db 0,2, 1,2, 2,2, 3,2
    db 0,0, 0,1, 0,2, 0,3

    ; L
    db 2,0, 0,1, 1,1, 2,1
    db 0,0, 0,1, 0,2, 1,2
    db 0,0, 1,0, 2,0, 0,1
    db 0,0, 1,0, 1,1, 1,2

    ; Z
    db 0,0, 1,0, 1,1, 2,1
    db 1,0, 0,1, 1,1, 0,2
    db 0,0, 1,0, 1,1, 2,1
    db 1,0, 0,1, 1,1, 0,2



; posicion y tipo de la pieza actual y a rotacion
pieza_col db 3
pieza_row db 0
pieza_id  db 0
pieza_rot db 0

;el control de la caida automatica ojala funcione 
ticks_previos dw 0
velocidad     dw 12       ; ticks entre cada caida 

; datos de la portada
opcion   db 0
t_glifo  db 0
t_fila   db 0
t_col    db 0
t_color  db 0
t_pat    db 0

txt_iniciar db "INICIAR",0
txt_salir   db "SALIR",0
txt_ayuda   db "Flechas: elegir   ENTER: aceptar",0
txt_juego   db "ESC = SALIR",0

; color de cada letra del titulo
titulo_colores db 12,14,10,11,13,9,0,12,14

; fuente 3x5 del titulo
titulo_font:
    db 7,2,2,2,2       ; T
    db 7,4,6,4,7       ; E
    db 7,2,2,2,2       ; T
    db 6,5,6,5,5       ; R
    db 7,2,2,2,7       ; I
    db 3,4,2,1,6       ; S
    db 0,0,0,0,0       ; espacio
    db 3,4,7,5,7       ; 6
    db 7,1,2,2,2       ; 7


; la matriz del tablero 
tablero: times COLS*ROWS db 0