.model large

dane1 segment
    number1 dw 0, "$"
    numberA dw 0
    numberB dw 0
    text2 db 10, "To nie jest cyfra$"
    text3 db 10, "To nie jest dobra wartosc - wieksza niz 20$"
    podajA db 10, "Podaj parametr A(min 0, max 8): $"
    podajB db 10, "Podaj parametr B(min 0, max 8): $"
    wypiszY db 10, "wspolrzedna Y dla X=0: $"
    wypiszX db 10, "wspolrzedna X dla ktorej funkcja ta przyjmuje wartosc 0: $"
    wypiszSkale db 10, "Skala to kazda kratka to 1, w obu osiach :) $"
    brak_miejsca db "Brak miejsca zerowego$"
    i1    db 408 dup (" "), "$"
dane1 ends

stos1 segment stack
        dw 200 dup(?)
    ws1 dw ?
stos1 ends

code1 segment

;######################################################
; print y0, where x = 0 so just print B
;######################################################
PRINT_Y0 PROC

    mov ah, 09h
    mov dx, offset wypiszY
    int 21h


    mov ax, [ds:numberB]
    call PRINT
    ret
PRINT_Y0 endp

;######################################################
; print x0, where y = 0 so x0 = -b/a
;######################################################
PRINT_X0 PROC
    .486
    mov ah, 09h
    mov dx, offset wypiszX
    int 21h

    cmp [ds:numberA], 0
    je wpisane_0

    mov ax, [ds:numberB] ; ax = b

    mov bx, [ds:numberA] ; bx = a

    xor dx,dx ; dx = 0
    neg dx ; to jest dziwne ale neguje liczbe dx:ax (-b)


    idiv bx ; ax = dx:ax/bx

    push dx

    neg ax

    call PRINT

    pop dx

    cmp dx, 0
    jnz print_reszta

    jmp exit

print_reszta:

    push dx

    mov ah, 09h
    mov dl, ' '
    int 21h

    pop ax
    call PRINT

    mov ah, 02h
    mov dl, '/'
    int 21h

    mov ax, [ds:numberA]
    call PRINT
    jmp exit

wpisane_0:
    mov ah, 09h
    mov dx, offset brak_miejsca
    int 21h

exit:
    ret
PRINT_X0 endp

;######################################################
; print number (16bit), from ax
;######################################################
PRINT PROC

    cmp ax, 0
    je just_0
    
    cmp ax, 0 ;check if less than 0 (print -)
    jg start1; if greate than 0 (with sign)

    cmp ax, 0
    jl neg1; just before start1, prints - and neg ax

    ret

    just_0:
        mov cx, 1
        mov ax, 0
        push ax

        jmp print1

        ret

    neg1:
        neg ax
        push ax

        xor ax, ax
        xor dx, dx

        mov dl, 45
        mov ah, 02h
        int 21h

        pop ax

    start1:
        ;initialize count
        mov cx,0
        mov dx,0

    label1:
        ; if ax is zero
        cmp ax,0
        je print1     
        ;initialize bx to 10
        mov bx,10       
        ; extract the last digit
        div bx                 
        ;push it in the stack
        push dx             
        ;increment the count
        inc cx             
        ;set dx to 0
        xor dx,dx
        jmp label1
    print1:
        ;check if count
        ;is greater than zero
        cmp cx,0
        je exit
        ;pop the top of stack
        pop dx
        ;add 48 so that it
        ;represents the ASCII
        ;value of digits
        add dx,48
        ;interrupt to print a
        ;character
        mov ah,02h
        int 21h
        ;decrease the count
        dec cx
        jmp print1
exit:
    ret
PRINT ENDP

WCZYTAJLICZBE proc

    mov ds:numberA, 0
    mov ds:numberB, 0
    mov ds:number1, 0

    mov ah, 09h
    mov dx, offset podajA
    int 21h

    call WCZYTAJ
    mov ax, ds:number1
    mov ds:numberA, ax

    mov ah, 09h
    mov dx, offset podajB
    int 21h

    call WCZYTAJ 
    mov ax, ds:number1
    mov ds:numberB, ax

    ret
    
WCZYTAJLICZBE endp

WCZYTAJ proc

    mov ds:number1, 0; zainicjalizuj na 0

loop1:

    mov ah, 01h ; wczytaj cyfre
    int 21h

    cmp al, 08 ; backspace
    je backspace1

    cmp al, 13 ; enterek, konczymy
    je enter1

    cmp al,30h ; less than 0
    jl invalidchar

    cmp al, 39h ; greater than 9
    jg invalidchar

    sub al, 30h ; z kodu robie liczbe
    mov ah, 0 ; usuwam bo w al jest liczba z input
    mov bx, ax ; to co z inputa
    mov cx, ax
    
    ; mul number by 10 and add bx (input)
    mov ax, ds:number1
    mov dx, 10
    mul dx ; 10 * ax
    add ax, bx
    mov ds:number1, ax
    ; end mult number and add

    mov ax, 8
    cmp ax, ds:number1  ; check if greater than 8
    jl tooBig

    jmp loop1
    
    
backspace1:
    mov ax, [ds:number1]
    mov bx, 10
    div bx ; / cos -> ah
    mov [ds:number1], ax

    mov dl, 00 ; rng pusty znak XD
    mov ah, 06h
    int 21h

    mov dl, 08 ; backspace i jest git
    mov ah, 06h
    int 21h

    jmp loop1
    ret



invalidchar:
    mov ah, 09h
    mov dx, offset text2
    int 21h

    mov ah,4ch ; koncze program caly
    int 21h	
    ret

enter1:
    mov ax, [ds:number1]
    ; call PRINT
    ret

tooBig: ; too big
    mov ah, 09h
    mov dx, offset text3
    int 21h

    mov ax, [ds:number1]
    call PRINT

    mov ah,4ch ; koncze program caly
    int 21h	
    ret


WCZYTAJ endp

;######################################################
; przygotowuje i4 do wypisania na konsole
;######################################################
PREPARE_ARR proc

start:
    xor cx, cx
    
    mov bx, 23 ; end line
    push bx
    
    mov bx, 11 ; middle line
    push bx
    
    

loop2:
    ; put into i1+1=+22*i

    ; let bx be offset at all times
    
    ; zawsze na stosie jest srodkowy, koncowy
    pop bx

    mov [ds:i1][bx], '#'
    add bx, 24

    mov ax, bx ; just for second
    pop bx

    mov [ds:i1][bx], 10
    add bx, 24

    push bx
    push ax
    
    inc cx
    cmp cx, 16 ; jest 16 rzędów XD
    jle loop2

    pop bx
    pop bx
    jmp loop3_start
    ret


loop3_start:
    xor cx, cx
    
    mov bx, 192
    
loop3:

    mov [ds:i1][bx], '#'
    inc bx
   
    inc cx
    cmp cx, 22 ; tyle trzeba wypelnic
    jle loop3

    ret
PREPARE_ARR endp

WRITE_ARR_FUNC proc

start_write:
    mov cx, -11; warunek poczatkowy petli
    
for_loop:
    ;y = ax + b start
    ; dx is y
    mov dx, cx ; x
    imul dx, [ds:numberA] ; a*x
    add dx, [ds:numberB] ; a*x + b
    ;y = ax+b end
    
    cmp dx, 8 ; boundaries
    jg next ; jesli wieksze

    cmp dx, -8 ; boundaries
    jl next; jesli mniejsze

    neg dx ; neguj y
    
    mov ax, 0
    add ax, 8*24 ; srodek czyli 8 * 24
    add ax, 11 ; to jest ogolnie stala to ax tutaj
    add ax, cx ; przesuniecie w bok XD

    push ax

    mov ax, dx
    imul ax, 24 ; ax * 24 -> ax

    mov dx, ax ; przesune se 
    pop ax ; i sciagne ze stosu
    
    add ax, dx
    mov bx, ax ; bo to bazowy index xd

    mov [ds:i1][bx], '*' ; w ax jest dokladnie pkt gdzie wpisac wiec normalnie go tam wpisuje

next:
    inc cx
    cmp cx, 11
    jng for_loop
    
    ret
    
WRITE_ARR_FUNC endp

PRINT_ARR proc
    xor ax, ax
    xor dx, dx 

    mov ah, 02h
    mov dl, 10
    int 21h

    xor ax, ax
    xor dx, dx
    
    mov ah, 09h
    mov dx, offset i1
    int 21h

    ret

PRINT_ARR endp

    
assume cs:code1, ds:dane1

s1:
    ; ;PSP do rejestru ES
    ; mov bx,ds
    ; mov es,bx

    ;segment danych do DS
    mov ax, seg dane1
    mov ds, ax

    ;inicjalizacja stosu
    mov ax,seg stos1
    mov ss,ax
    mov sp,offset ws1

    xor ax,ax
    xor bx,bx

    mov number1, 0
    
    ;glowna czesc programu - wywolania funkcji
    call WCZYTAJLICZBE

    call PRINT_Y0
    call PRINT_X0

    call PREPARE_ARR

    mov bx, 407
    mov [ds:i1][bx], ' '

    call WRITE_ARR_FUNC

    call PRINT_ARR

    xor ax,ax
    mov ah, 09h
    mov dx, offset wypiszSkale 
    int 21h
    
    ;koniec programu
    mov ah,4ch
    int 21h	
    ret

code1 ends


end s1
