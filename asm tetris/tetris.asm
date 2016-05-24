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

keyboard_buffer db 16 dup(?)
tail dw 0
head dw 0

oldint9 dw ?, ?

colors db 0, 1fh, 20h, 24h, 28h, 2ch, 30h, 34h ; black, white, blue, magenta, red, yellow, green, cyan

@int1c proc
        push ax ds 
        push ds
        push cs
        pop ds
        mov ax, time
        inc ax
        mov time, ax

        pop ds
        mov al, 20h
        out 20h, al
        pop ds ax
        iret

@int1c endp

int9 proc
        push ax bx cx dx di  
        push cs
        pop ds
         
        in al, 60h

; складывание в буффер
        mov di, tail
        mov keyboard_buffer[di], al
        inc di
        ;cmp di, head
        ;je @alert
        and di, 0fh
        mov tail, di

; тут сообщаем клаве все
        in al, 61h
        push ax
        or al, 80h
        out 61h, al
        pop ax
        out 61h, al

; тут 
        mov al, 20h
        out 20h, al
        pop di dx cx bx ax
        iret
int9 endp

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

change_keyboard_interrupt proc
        push ax bx dx es 
        mov ah, 35h 
        mov al, 9h
        int 21h 

        mov oldint9, es
        mov oldint9+2, bx
        mov ah, 25h
        lea dx, int9
        int 21h

        pop es dx bx ax
        ret
change_keyboard_interrupt endp

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

return_keyboard_interrupt proc
        push ax dx
        mov dx, oldint9+2
        mov ds, oldint9
        mov ax, 2509h
        int 21h

        push cs
        pop ds
        pop dx ax
        ret

return_keyboard_interrupt endp

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

;; random!!
; rand    proc       near
;         push       dx
;         mov        ax, word ptr seed  ; считать последнее
;                                        ; случайное число
;         test       ax,ax             ; проверить его, если это -1,
;         js         fetch_seed          ; функция еще ни разу не
;                                        ; вызывалась и надо создать
;                                        ; начальное значение
; randomize:
;         mul        word ptr rand_a    ; умножить на число а,
;         div        word ptr rand_m    ; взять остаток от
;                                        ; деления на 231-1
;         mov        ax,dx
;         mov        word ptr seed,ax  ; сохранить для
;                                        ; следующих вызовов
;         pop        dx
;         ret

; fetch_seed:
;         push       ds
;         push       0040h
;         pop        ds
;         mov        ax, word ptr ds:006Ch ; считать
;                                           ; двойное слово из области
;         pop        ds                     ; данных BIOS по адресу
;                                           ; 0040:0060 - текущее число
;         jmp        randomize        ; тактов таймера

; rand_a  dw         400 014 
; rand_m  dw         2 147 483 563
; seed    dw         -1
; rand    endp

rand   proc
        push bx cx
        mov        ax, word ptr seed

        test       ax,ax             ; проверить его, если это -1,
        js         fetch_seed          

randomize:
        mov        cx,8
newbit: mov        bx,ax
        and        bx,002Dh
        xor        bh,bl
        clc
        jpe        shift
        stc
shift:  rcr        ax,1
        loop       newbit
        mov        word ptr seed,ax
        mov        ah,0
        pop cx bx
        ret

fetch_seed:
        push       ds
        push       0040h
        pop        ds
        mov        ax,word ptr ds:0060h ; считать
                                          ; двойное слово из области
        pop        ds                     ; данных BIOS по адресу
                                          ; 0040:0060 - текущее число
        jmp        randomize        ; тактов таймера

seed    dw         -1

rand   endp


;; end random

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
        ; figure_index, figure_x, figure_y
        ; return ax: 0 - has collision, 1 otherwise
        push bp
        mov bp, sp
        push bx cx si di dx

        mov si, [bp + 8] ; figure index
        shl si, 1
        mov di, figures[si] ; адрес фигуры

        ; поиск самой левой точки

        mov cx, di
        add cx, 16 ; конец фигуры
        xor ax, ax ; column index
        mov dx, 3 ; leftest point
        mov si, di
@@lpl:  
        cmp [si], byte ptr 0
        je @@hasnot_figure_l

        cmp dx, ax
        jle @@hasnot_figure_l
        mov dx, ax

@@hasnot_figure_l:
        inc ax
        inc si

        cmp si, cx
        je @@check_l
        cmp ax, 4
        jne @@lpl
        xor ax, ax
        jmp @@lpl

@@check_l:
        mov ax, [bp + 6]
        add ax, dx
        cmp ax, 0
        jge @@next_l

        xor ax, ax
        jmp @@exit

@@next_l:

        ;поиск самой правой точки
        
        mov cx, di
        add cx, 16 ; конец фигуры
        xor ax, ax ; column index
        mov dx, 0 ; rightest point
        mov si, di
@@lpr:  
        cmp [si], byte ptr 0
        je @@hasnot_figure_r

        cmp dx, ax
        jge @@hasnot_figure_r
        mov dx, ax

@@hasnot_figure_r:
        inc ax
        inc si

        cmp si, cx
        je @@check_r
        cmp ax, 4
        jne @@lpr
        xor ax, ax
        jmp @@lpr

@@check_r:
        mov ax, [bp + 6]
        add ax, dx
        cmp ax, 10
        jl @@next_r

        xor ax, ax
        jmp @@exit

@@next_r:

        ; поиск самой нижней точки

        mov cx, di
        add cx, 16 ; конец фигуры
        xor ax, ax ; column index
        xor bx, bx ; row index
        mov dx, 0 ; downest point
        mov si, di
@@lpd:  
        cmp [si], byte ptr 0
        je @@hasnot_figure_d

        mov dx, bx

@@hasnot_figure_d:
        inc ax
        inc si

        cmp si, cx
        je @@check_d
        cmp ax, 4
        jne @@lpd
        inc bx
        xor ax, ax
        jmp @@lpd

@@check_d:
        mov ax, [bp + 4]
        add ax, dx
        cmp ax, 20
        jl @@next_d

        xor ax, ax
        jmp @@exit

@@next_d:
        mov ax, 1

@@exit:
        pop dx di si cx bx bp
        ret 6
check_for_border endp

rotate_figure proc
        ; figure_index
        push bp
        mov bp, sp
        push ax bx cx dx si di

        mov si, [bp + 4] ; figure index
        shl si, 1
        mov di, figures[si] ; адрес фигуры

        xor bx, bx ; row index 
        xor cx, cx ; column index

@@lp:
        cmp [di], byte ptr 0
        je @@end_lp

        mov ax, bx
        mov dx, 4
        mul dx

        mov dx, cx
        neg dx
        add dx, 3
        add ax, dx
        mov si, ax
        mov temp_figure[si], 1
@@end_lp:
        inc di
        inc bx
        cmp bx, 4
        jne @@lp
        xor bx, bx
        inc cx
        cmp cx, 4
        jne @@lp

@@exit:
        mov si, [bp + 4] ; figure index
        shl si, 1
        mov di, figures[si] ; адрес фигуры
        lea si, temp_figure
        mov cx, 15
        rep movsb

        mov ax, 0
        lea si, temp_figure
        xor cx, cx

@@clean:
        mov [si], ax
        inc si
        inc cx
        cmp cx, 15
        jne @@clean

        pop di si dx cx bx ax bp
        ret 2

temp_figure     db 0,0,0,0
                db 0,0,0,0
                db 0,0,0,0
                db 0,0,0,0
rotate_figure endp

try_to_move proc
        ; figure_index, figure_x, figure_y, shist_x, shift_y, color 
        ; return ax: 0 - cant move, 1 - move
        push bp
        mov bp, sp
        push bx cx dx

        mov ax, [bp + 14]
        mov bx, [bp + 12]
        mov cx, [bp + 10]
        mov dx, [bp + 4]
        push ax bx cx
        call clean_figure

        add bx, [bp + 8]
        add cx, [bp + 6]

        push ax bx cx
        call check_for_border
        cmp ax, 0
        je @@bad_end

        mov ax, [bp + 14]
        push ax bx cx
        call check_for_collision
        cmp ax, 0
        je @@bad_end

        mov ax, [bp + 14]
        push ax bx cx dx
        call put_figure
        mov ax, 1
        jmp @@exit

@@bad_end:
        mov ax, [bp + 14]
        mov bx, [bp + 12]
        mov cx, [bp + 10]
        mov dx, [bp + 4]
        push ax bx cx dx
        call put_figure
        xor ax, ax
@@exit:

        pop dx cx bx bp
        ret 12
try_to_move endp


try_to_rotate proc
        ; figure_index, figure_x, figure_y, color 
        ; return ax: 0 - cant move, 1 - move
        push bp
        mov bp, sp
        push ax bx cx dx

        mov ax, [bp + 10]
        mov bx, [bp + 8]
        mov cx, [bp + 6]
        mov dx, [bp + 4]
        push ax bx cx
        call clean_figure

        push ax
        call rotate_figure  

        push ax bx cx
        call check_for_border
        cmp ax, 0
        je @@bad_end

        mov ax, [bp + 10]
        push ax bx cx
        call check_for_collision
        cmp ax, 0
        je @@bad_end

        mov ax, [bp + 10]
        push ax bx cx dx
        call put_figure
        mov ax, 1
        jmp @@exit

@@bad_end:
        mov ax, [bp + 10]
        push ax ax ax
        call rotate_figure
        call rotate_figure
        call rotate_figure
        mov ax, [bp + 10]
        mov bx, [bp + 8]
        mov cx, [bp + 6]
        mov dx, [bp + 4]
        push ax bx cx dx
        call put_figure
        xor ax, ax
@@exit:

        pop dx cx bx ax bp
        ret 8

try_to_rotate endp

process_key proc
        ; scancode
        ; return ax: 0 - exit, 1 - continue
        push bp
        mov bp, sp
        push bx cx si di dx

        mov si, [bp + 4]
        cmp si, 48h ; up
        jne @@next1

        mov bx, current_figure_index
        mov cx, current_figure_position_x
        mov dx, current_figure_position_y
        push bx cx dx
        mov bx, current_figure_color
        push bx
        call try_to_rotate

@@next1:
        cmp si, 4bh ; left
        jne @@next2

        mov bx, current_figure_index
        mov cx, current_figure_position_x
        mov dx, current_figure_position_y
        push bx cx dx
        mov bx, -1
        mov cx, 0
        mov dx, current_figure_color
        push bx cx dx
        call try_to_move

        cmp ax, 1
        jne @@next2
        mov cx, current_figure_position_x
        dec cx
        mov current_figure_position_x, cx

@@next2:
        cmp si, 4dh ; right
        jne @@next3

        mov bx, current_figure_index
        mov cx, current_figure_position_x
        mov dx, current_figure_position_y
        push bx cx dx
        mov bx, 1
        mov cx, 0
        mov dx, current_figure_color
        push bx cx dx
        call try_to_move

        cmp ax, 1
        jne @@next3
        mov cx, current_figure_position_x
        inc cx
        mov current_figure_position_x, cx

@@next3:
        cmp si, 50h ; down
        jne @@next4

        mov bx, current_figure_index
        mov cx, current_figure_position_x
        mov dx, current_figure_position_y
        push bx cx dx
        mov bx, 0
        mov cx, 1
        mov dx, current_figure_color
        push bx cx dx
        call try_to_move

        cmp ax, 1
        jne @@next4
        mov cx, current_figure_position_y
        inc cx
        mov current_figure_position_y, cx

@@next4:
        cmp si, 01h ; exit
        jne @@continue_exit
        xor ax, ax
        jmp @@exit

@@continue_exit:
        mov ax, 1
@@exit:
        call print_map
        call print_wrapper
        pop dx di si cx bx bp
        ret 2
process_key endp

check_for_key proc
        ;return ax: 0 - exit, 1 - continue
        push si di dx

        mov ax, 1
        mov si, head
        cmp si, tail
        je @@exit

        cli 
        xor dx, dx
        mov dl, keyboard_buffer[si]
        inc si
        and si, 0fh
        mov head, si
        sti

        push dx
        call process_key

@@exit:
        pop dx di si
        ret
check_for_key endp

figure_down proc
        ; figure_index, figure_x, figure_y, color 
        ; return ax: 0 - exit, 1 - continue
        push bp
        mov bp, sp
        push bx cx dx

        mov ax, [bp + 10]
        mov bx, [bp + 8]
        mov cx, [bp + 6]
        mov dx, [bp + 4]

        push ax bx cx
        mov ax, 0
        mov bx, 1
        push ax bx dx
        call try_to_move

@@exit:
        pop dx cx bx bp
        ret 8
figure_down endp

clean_line proc
        ; row_map_index
        push bp
        mov bp, sp
        push ax cx dx si

        mov ax, [bp + 4]
        mov cx, 10
        mul cx
        dec ax
        mov si, ax

@@lp:
        mov di, si
        add di, 10
        mov al, map[si]
        mov map[di], al
        dec si

        cmp si, 0
        jne @@lp

@@exit:
        pop si dx cx ax bp
        ret 2
clean_line endp

check_full_line proc
        push ax bx cx dx si di

        xor si, si
        xor bx, bx ; column count
        xor dx, dx ; rows count
        xor ax, ax ; показатель, что строка заполнена не нулями. 
        ; если 0 - нужно удалять, если 1 - есть пустые клетки
@@lp:
        cmp map[si], 0
        jne @@continue_lp

        mov ax, 1

@@continue_lp:

        inc bx
        inc si

        cmp bx, 10
        jne @@lp

        cmp ax, 0
        jne @@not_clean

        push dx
        call clean_line

@@not_clean:
        inc dx
        xor ax, ax
        xor bx, bx
        cmp si, 200
        jne @@lp

@@exit:
        pop di si dx cx bx ax
        ret 
check_full_line endp

rand_time dw 0

get_next_figure proc
        push ax bx cx dx si di

        ; call rand
        ; mov bx, 7
        ; div bx

        ; mov cx, dx ; запомнили пока индекс фигуры сюда

        ; call rand
        ; mov bx, 7
        ; div bx ; в dx цвет
        ; inc dx

        ; mov ax, cx 

; пыталась сама :(
        mov ah, 2ch
        int 21h

        xor ax, ax
        mov al, dl ; взяли миллисекунды системного времени

        mov dx, rand_time
        add dx, ax
        mov rand_time, dx
        mov ax, dx

        mov bl, 7
        div bl

        mov al, ah
        mov ah, 0
        push ax ; запомнили пока индекс фигуры сюда

        mov ah, 2ch
        int 21h

        xor ax, ax
        mov al, dl ; взяли милли секунды системного времени
        add al, dh
        mov bl, 7
        div bl

        xor dx, dx
        mov dl, ah
        inc dx

        pop ax
;;;;;
        
        ; mov ax, 5
        mov bx, 3
        mov cx, -1
        ; mov dx, 2
        mov current_figure_index, ax
        mov current_figure_position_x, bx
        mov current_figure_position_y, cx
        mov current_figure_color, dx

@@exit:
        pop di si dx cx bx ax
        ret 
get_next_figure endp

check_end_game proc
        ; return ax: 0 - exit, 1 - continue

        push bx cx si

        ; mov ax, 1 ; ; показатель, что строка заполнена нулями. 
        ; если 0 - есть заполненные клетки, если 1 - все нули 

        mov ax, current_figure_index
        mov bx, current_figure_position_x
        mov cx, current_figure_position_y

        push ax bx cx
        call check_for_collision

        xor si, si ; map index
        xor cx, cx ; column index

@lp:
        cmp map[si], 0
        je @continue_lp

        xor ax, ax

@continue_lp:
        inc si
        inc cx
        cmp cx, 10
        jne @lp

@@exit:
        pop si cx bx
        ret 
check_end_game endp

main_loop proc
        push ax bx cx dx si di

@@lp:
        call check_for_key

        cmp ax, 0
        je @@exit

        mov si, 10
        cmp time, si
        jl @@lp

        mov time, byte ptr 0

        mov ax, current_figure_index
        mov bx, current_figure_position_x
        mov cx, current_figure_position_y
        mov dx, current_figure_color

        push ax bx cx dx
        call figure_down

        call print_map
        call print_wrapper

        mov cx, current_figure_position_y
        inc cx
        mov current_figure_position_y, cx
        cmp ax, 0
        jne @@lp

        call check_full_line
        call get_next_figure
        call check_end_game
        cmp ax, 0
        je @@exit
        jmp @@lp

@@exit:
        pop di si dx cx bx ax
        ret

main_loop endp

@start:
        call change_video_mode
        call change_time_interrupt
        call change_keyboard_interrupt

        mov ax, 5
        mov bx, 3
        mov cx, -1
        mov dx, 2
        mov current_figure_index, ax
        mov current_figure_position_x, bx
        mov current_figure_position_y, cx
        mov current_figure_color, dx

        push ax bx cx dx
        call put_figure

        call print_map
        call print_wrapper

        call main_loop

@@exit:
        ; mov ah,0
        ; int 16h
        call return_keyboard_interrupt
        call return_time_interrupt
        call return_video_mode
        ret

current_figure_index dw 0
current_figure_position_x dw 0
current_figure_position_y dw 0
current_figure_color dw 0

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