.model tiny
.code
org 100h
locals

@main:
        jmp @start

save_mode db ? ; Сохранить текущий видео режим
cell_size dw 8
video_page dd 0a0000h
time dw 0
oldint1c dw ?, ?

colors db 0, 1fh, 20h, 24h, 28h, 2ch, 30h, 34h ; black, white, blue, magenta, red, yellow, green, cyan

@int1c proc
        push ds
        push cs
        pop ds
        mov ax, time
        inc ax
        mov time, ax

        pop ds
        mov al, 20h
        out 20h, al
        iret

@int1c endp

change_video_mode proc
        push ax

; Схраняем текущий видео режим
        mov ah,0Fh
        int 10h
        mov save_mode,al

; ; Переключиться в графический режим

        mov ah,0 ; установка видео режима
        mov al, 13h ; 320 X 200, 256 colors
        int 10h
        pop ax
        ret
change_video_mode endp

change_time_interrupt proc
        push ax bx es dx
        mov ah, 35h 
        mov al, 1ch
        int 21h 

        mov oldint1c, es
        mov oldint1c+2, bx
        mov ah, 25h
        lea dx, @int1c
        int 21h

        pop dx es bx ax
        ret
change_time_interrupt endp

return_video_mode proc
        push bp
        mov bp, sp
        push ax

        mov ah,0
        mov al, save_mode
        int 10h
        pop ax bp
        ret
return_video_mode endp

return_time_interrupt proc
        push ax ds dx

        mov dx, oldint1c+2
        mov ds, oldint1c
        mov ax, 251ch
        int 21h

        pop dx ds ax
        ret
return_time_interrupt endp

print_vert_line proc
        ; start, height
        push bp
        mov bp, sp
        push ax cx di es

        mov ax,0A000h
        mov es,ax
        mov ax, 68h

        mov di, [bp + 6]
        mov cx, [bp + 4]
@line:
        stosb
        add di, 319
        dec cx
        cmp cx, 0
        jne @line

        pop es di cx ax bp
        ret 4
print_vert_line endp

print_horizont_line proc
        ; start, height
        push bp
        mov bp, sp
        push ax cx di es

        mov ax,0A000h
        mov es,ax
        mov ax, 68h

        mov di, [bp + 6]
        mov cx, [bp + 4]
        
        rep stosb

        pop es di cx ax bp
        ret 4
print_horizont_line endp

print_wrapper proc
        push bp
        mov bp, sp
        push ax cx di es

; left line
        mov di, 2566 ; 320 * 8 + 6
        mov cx, 162 ; 20*8+2
        push di cx
        call print_vert_line

        inc di
        push di cx
        call print_vert_line

        add di, 82 ; 10 * 8 + 1
        push di cx
        call print_vert_line

        inc di
        push di cx
        call print_vert_line

        mov di, 53768 ; 320 * 168 + 8
        mov cx, 81 ; 10*8
        push di cx
        call print_horizont_line

        add di, 320
        push di cx
        call print_horizont_line

        pop es di cx ax bp
        ret
print_wrapper endp

print_cell proc
        ;x, y, color
        push bp
        mov bp, sp
        push ax cx di dx es

        mov ax,0A000h
        mov es,ax

        mov ax, [bp + 6] ; up
        mov cx, 320
        mul cx
        add ax, [bp + 8] ; left
        mov di, ax

        mov ax, [bp + 4] ; color

        mov dx, cell_size
@print_row:
        mov cx, cell_size
        stosb
        rep stosb
        dec dx
        add di, 320
        sub di, cell_size
        dec di
        test dx, dx
        jne @print_row

        pop es dx di cx ax bp
        ret 6
print_cell endp

print_map proc
        push bp
        mov bp, sp
        push ax bx cx di si dx

        xor di, di
        xor cx, cx
        mov ax, 8 ; x
        mov bx, 8 ; y
@@lp:
        mov cl, map[di]
        mov si, cx
        mov cl, colors[si]
        push ax bx cx
        call print_cell
        inc di
        cmp di, 200
        je @@exit

        add ax, 8
        cmp ax, 80
        jng @@lp

        mov ax, 8
        add bx, 8
        jmp @@lp

@@exit:
        pop dx si di cx bx ax bp
        ret
print_map endp

put_figure proc
        ; figure_index, figure_position_x, figure_position_y, color
        push bp
        mov bp, sp
        push ax bx cx si di dx

        mov si, [bp + 10] ; figure index
        shl si, 1
        mov di, figures[si] ; address figure

        mov ax, [bp + 6]
        cmp ax, 0
        jge @@below_top 

        ; фигура заскакивает наверх
        neg ax
        mov bx, 4
        mul bx
        add di, ax
        sub @@figure_length, ax
        mov ax, 0

@@below_top:

        cmp ax, 16
        jl @@above_bottom

        ; фигура ниже дна
        mov si, @@figure_length
        mov bx, 20
        sub bx, ax
        mov ax, bx
        mov bx, 4
        mul bx
        sub [si], bx
        mov ax, [bp + 6]

@@above_bottom:
        mov cx, 10
        mul cx
        mov bx, [bp + 8]

        cmp bx, 0
        jge @@lefter_left

        ; фигура заскакивает за левый край
        neg bx
        add di, bx
        mov @@add_to_next_line_figure, bx
        mov @@figure_start, bx
        mov si, @@add_to_next_line_map
        add si, bx
        mov @@add_to_next_line_map, si
        mov bx, 0

@@lefter_left:

        cmp bx, 6
        jle @@righter_right

        ; фигура заскакивает за правый край
        mov si, 10
        sub si, bx
        mov bx, 4
        sub bx, si
        sub @@figure_length, bx
        sub @@figure_line_length, bx
        add @@add_to_next_line_figure, bx
        add @@add_to_next_line_map, bx
        mov bx, [bp + 8]

@@righter_right:
        add bx, ax

        mov si, bx ; map index
        mov cx, @@figure_start ; figure elements count
        mov bx, @@figure_start ; column count
        mov dx, [bp + 4] ; color

@@lp:
        cmp byte ptr [di], 0
        je @@end_lp
        mov map[si], dl

@@end_lp:   
        ; mov map[si], 2    
        inc bx
        inc di
        inc cx
        inc si
        cmp cx, @@figure_length
        je @@exit
        cmp bx, @@figure_line_length ; перейти на другую строчку
        jne @@lp
        mov ax, @@add_to_next_line_map
        add si, ax
        xor bx,bx
        add bx, @@figure_start
        add cx, @@add_to_next_line_figure
        add di, @@add_to_next_line_figure
        jmp @@lp

@@exit:
        mov ax, 0
        mov @@figure_start, ax
        mov @@add_to_next_line_figure, ax
        mov ax, 4
        mov @@figure_line_length, ax
        mov ax, 6
        mov @@add_to_next_line_map, ax
        mov ax, 16
        mov @@figure_length, ax
        pop dx di si cx bx ax bp
        ret 8

@@figure_start dw 0
@@figure_length dw 16
@@figure_line_length dw 4
@@add_to_next_line_figure dw 0
@@add_to_next_line_map dw 6

put_figure endp

clean_figure proc
        ; figure_index, figure_position_x, figure_position_y
        push bp
        mov bp, sp
        push ax bx cx dx

        mov ax, [bp + 8]
        mov bx, [bp + 6]
        mov cx, [bp + 4]
        xor dx, dx
        push ax bx cx dx
        call put_figure

        pop dx cx bx ax bp
        ret 6
clean_figure endp

check_for_collision proc
        ; figure_index, figure_x, figure_y
        ; return ax: 0 - has collision, 1 - no collision
        push bp
        mov bp, sp
        push bx cx si di dx

        mov si, [bp + 8] ; figure index
        shl si, 1
        mov di, figures[si] ; адрес фигуры

        ; плохой копипаст
        mov ax, [bp + 4]
        cmp ax, 0
        jge @@below_top 

        ; фигура заскакивает наверх
        neg ax
        mov bx, 4
        mul bx
        add di, ax
        sub @@figure_length, ax
        mov ax, 0

@@below_top:

        cmp ax, 16
        jl @@above_bottom

        ; фигура ниже дна
        mov si, @@figure_length
        mov bx, 20
        sub bx, ax
        mov ax, bx
        mov bx, 4
        mul bx
        sub [si], bx
        mov ax, [bp + 4]

@@above_bottom:
        mov cx, 10
        mul cx
        mov bx, [bp + 6]

        cmp bx, 0
        jge @@lefter_left

        ; фигура заскакивает за левый край
        neg bx
        add di, bx
        mov @@add_to_next_line_figure, bx
        mov @@figure_start, bx
        mov si, @@add_to_next_line_map
        add si, bx
        mov @@add_to_next_line_map, si
        mov bx, 0

@@lefter_left:

        cmp bx, 6
        jle @@righter_right

        ; фигура заскакивает за правый край
        mov si, 10
        sub si, bx
        mov bx, 4
        sub bx, si
        sub @@figure_length, bx
        sub @@figure_line_length, bx
        add @@add_to_next_line_figure, bx
        add @@add_to_next_line_map, bx
        mov bx, [bp + 6]

@@righter_right:
        add bx, ax

        ; конец плохого копипаста

        mov si, bx ; map index
        mov cx, @@figure_start ; figure elements count
        mov bx, @@figure_start ; column count

        ; di - адрес по фигуре, si - индекс по карте
        mov ax, 1
@@lp:
        cmp byte ptr [di], 0
        je @@end_lp
        
        cmp map[si], 0
        je @@end_lp
        xor ax, ax

@@end_lp:   
        inc bx
        inc di
        inc cx
        inc si
        cmp cx, @@figure_length
        je @@exit
        cmp bx, @@figure_line_length ; перейти на другую строчку
        jne @@lp
        mov dx, @@add_to_next_line_map
        add si, dx
        xor bx,bx
        add bx, @@figure_start
        add cx, @@add_to_next_line_figure
        add di, @@add_to_next_line_figure
        jmp @@lp

@@exit:
        mov dx, 0
        mov @@figure_start, dx
        mov @@add_to_next_line_figure, dx
        mov dx, 4
        mov @@figure_line_length, dx
        mov dx, 6
        mov @@add_to_next_line_map, dx
        mov dx, 16
        mov @@figure_length, dx
        pop dx di si cx bx bp
        ret 6

@@figure_start dw 0
@@figure_length dw 16
@@figure_line_length dw 4
@@add_to_next_line_figure dw 0
@@add_to_next_line_map dw 6

check_for_collision endp

check_for_border proc
        ; figure_index, color, 
        push bp
        mov bp, sp
        push ax bx cx si di dx

@@exit:
        pop dx di si cx bx ax bp
        ret 4
check_for_border endp

figure_down proc
        ; figure_index, color, 
        push bp
        mov bp, sp
        push ax bx cx si di dx

@@exit:
        pop dx di si cx bx ax bp
        ret 4
figure_down endp

@start:
        call change_video_mode
        call change_time_interrupt
        mov ax, 1
        mov bx, 5
        mov cx, 17     
        mov dx, 2
        push ax bx cx dx
        call put_figure

        call print_map
        call print_wrapper

        mov ax, 1
        mov bx, 5
        mov cx, 16    
        mov dx, 3
        push ax bx cx
        call check_for_collision
        cmp ax, 0
        je @@a
        push ax bx cx dx
        call put_figure

        call print_map
        call print_wrapper
@@a:
        ; push ax bx cx
        ; call clean_figure
        ; call print_map
        ; call print_wrapper      

        mov ah,0
        int 16h
        call return_time_interrupt
        call return_video_mode
        ret

figures dw figure_I, figure_J, figure_L, figure_O, figure_S, figure_T, figure_Z

figure_I db     0,0,0,0
         db     1,1,1,1
         db     0,0,0,0
         db     0,0,0,0

figure_J db     0,0,0,0
         db     0,1,0,0
         db     0,1,1,1
         db     0,0,0,0

figure_L db     0,0,0,0
         db     0,0,1,0
         db     1,1,1,0
         db     0,0,0,0

figure_O db     0,0,0,0
         db     0,1,1,0
         db     0,1,1,0
         db     0,0,0,0

figure_S db     0,0,0,0
         db     0,0,1,1
         db     0,1,1,0
         db     0,0,0,0

figure_T db     0,0,0,0
         db     0,0,1,0
         db     0,1,1,1
         db     0,0,0,0

figure_Z db     0,0,0,0
         db     0,1,1,0
         db     0,0,1,1
         db     0,0,0,0

map db 200 dup(0)
end @main