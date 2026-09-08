bits 16
org 100h

inicio:
    call iniciar_video
    call esperar_tecla
    call restaurar_video
    call salir_programa

iniciar_video:
    mov ax, 0013h
    int 10h
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