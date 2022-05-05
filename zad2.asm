dane1 segment
    kod_bledu_argumentu dw 0
    filename db 200 dup(0),"nazwa2.txt", 0
    kom_bledu db "Sa bledy gdzies, sprobuj ponownie$"
    wsk1 dw ?
    buf1 db 300 dup("$")
    brak_args db "Brak argumentow$"
    blad_otwarcia db "Blad przy otwieraniu pliku$"
    czytanie_pliku_error db "Blad podczas czytania pliku$"
dane1 ends

stos1 segment stack
        dw 200 dup(?)
    ws1 dw ?
stos1 ends

code1 segment
assume cs:code1, ds:dane1
.486

s1:
    ;inicjalizacja stosu
    mov ax,seg stos1
    mov ss,ax
    mov sp,offset ws1
    
    ; na start, póki psp w ds nie jest ruszone to czytam filename
    call GET_FILENAME
    push ax
    mov ax, seg filename
    mov ds, ax
    mov dx, offset filename

    pop ax
    mov ax, word ptr ds:[kod_bledu_argumentu]
    cmp ax, 0
    jne brak_argumentow_main ; jakis problem z argumentami

    mov ax, seg filename
    mov ds, ax


; open file in filename
    xor cx, cx
    mov dx, offset filename
    mov al, 0
    mov ah, 03Dh
    int 21h ; open file in nazwa
    mov word ptr ds:[wsk1], ax ; kod bledu lub handler

    jc error__ ; jak flaga cf jest 1 to jest blad przy otwarciu
    
    ; obsługa grafiki
    mov al, 13h ; tryb graficzny 320x200 256 kolorów
    mov ah, 0 ; zmiana trybu karty VGA
    int 10h ; przerwanie biosu (obsluguje karte graficzna)


czytaj_linie:

    CALL CZYTAJ_KOLOR

    ; w al jest kolor - trzeba go gdzies wpisac ogółem
    mov byte ptr cs:[KD], al
    
    cmp ax, 0 ; detekcja konca pliku jest tutaj, gdy kolor nie miał jak byc znaleziony
    je koniec_pliku

    ; jeden pusty znak tu jest
    mov ax, seg buf1
    mov ds, ax
    mov dx, offset buf1 ; ds:dx -> wsk na bufor
    mov cx, 1 ;czytamy max 1 znak

    mov bx, word ptr ds:[wsk1]
    mov al, 0
    mov ah, 3fh
    int 21h ; wczytaj znaki
    ; koniec pustego znaku

    

    mov cx, 0
    push cx ; licznik ile boków itp
    czytaj_wspolrzedne:
        CALL CZYTAJ_PLIK

        mov word ptr cs:[X2_MAIN], ax

        cmp bx, 0; jak w ax jest -1 to jest koniec
        jl koniec_wspolrzednych
        

        CALL CZYTAJ_PLIK

        mov word ptr cs:[Y2_MAIN], ax

        cmp bx, 0; jak w ax jest -1 to jest koniec
        jl koniec_wspolrzednych
        
        ; i tutaj wpisanie na ekran tych punktów
        pop cx
        push cx
        cmp cx, 0 ; jest pierwszy wiec nie ma jak boku narysowac ale mozna ogarnac tak zeby to trafiło do ostatniego na samiutkim końcu
        je pierwszy_punkt

        call Punkt_Bresenham; wywoluje procedure do zrobienia na ekranie

        jmp continue9

        pierwszy_punkt:
            mov ax, word ptr cs:[X2_MAIN]
            mov word ptr cs:[X_pierwszy], ax
            mov ax, word ptr cs:[Y2_MAIN]
            mov word ptr cs:[Y_pierwszy], ax
        

        continue9:
            mov ax, word ptr cs:[X2_MAIN]
            mov word ptr cs:[X1_MAIN], ax
            mov ax, word ptr cs:[Y2_MAIN]
            mov word ptr cs:[Y1_MAIN], ax
            pop cx
            inc cx
            push cx

            jmp czytaj_wspolrzedne

    koniec_wspolrzednych:
        pop cx
        cmp cx, 0 ; jak jest 0 to nic nie rób a jak jest >0 to zrob linie miedzy pierwszym a ostatnim
        je koniec_wspolrzednych_legit

        push bx
        
        ; tutaj punkt bo nie ma polaczenia miedzy tym co wczuytane a poprzednim
        call Punkt_Bresenham


        mov ax, word ptr cs:[X_pierwszy]
        mov word ptr cs:[X1_MAIN], ax

        mov ax, word ptr cs:[Y_pierwszy]
        mov word ptr cs:[Y1_MAIN], ax

        call Punkt_Bresenham ; i ostatnia linia robi brr

        pop bx
        
        cmp bx ,-2 ; jest koniec pliku
        je koniec_pliku
        
        cmp bx, -3 ; problem z czytaniem (tj koniec inputu liczby odrazu)
        je koniec_pliku_error_


    koniec_wspolrzednych_legit:
    
        jmp czytaj_linie

koniec_pliku_error_:
    mov dx, offset czytanie_pliku_error
    mov ah, 09h
    int 21h


koniec_pliku:
; close
    xor ax,ax
    mov bx, word ptr ds:[wsk1]
    mov ah, 3eh
    int 21h ; zamykanie pliku

exit123:
    jmp koniec
;---------------------------------------------------------------------------------

;get name of file from argument
GET_FILENAME PROC
    start_filename1: 
        mov ax, seg filename
        mov es, ax
        
        ; ds = PSP ; ds jest nieruszalne bo sie PSP zgubi
        
        mov si, 082h
        mov di, offset filename
        
        xor cx, cx ;=0
        mov cl, byte ptr ds:[080h]

        mov al, cl ; w cl jest ilosc znaków w argumentach
        cmp al, 0
        je brak_argumentow1

    p1_get_filename:
        mov al, byte ptr ds:[si]
        mov byte ptr es:[di], al
        inc si
        inc di
        loop p1_get_filename
    
    jmp koniec_get_filename1

    brak_argumentow1:
        mov word ptr es:[kod_bledu_argumentu], 1
        ret

    koniec_get_filename1:
        mov byte ptr es:[di-1], 0
        ret
        
GET_FILENAME ENDP

CZYTAJ_KOLOR PROC
    xor ax, ax
    czytaj_znak_2:
        ; czytaj znak
        mov dx, offset buf1 ; ds:dx -> wsk na bufor
        mov ax, seg buf1
        mov ds, ax
        mov cx, 1 ;czytamy max 1 znak

        mov bx, word ptr ds:[wsk1]
        xor ax, ax
        mov ah, 03fh
        int 21h ; wczytaj znaki
        ; if CF=0 then ax = ilosc wczytanych znakow

        cmp ax, 0 ; w ax jest ilosc wczytanych znakow, jak jest 0 to jest EOF
        je koniec_pliku_czytaj_kolor

        mov al, byte ptr ds:[buf1]

        cmp al, 'G'
        je green_color

        cmp al, 'R'
        je red_color

        cmp al, 'B'
        je blue_color
    
    default_color:
        mov al, 11h ; taki kolor jest default jezeli nie bedzie gitówa
        jmp koniec_kolorow
    green_color:
        mov al, 2
        jmp koniec_kolorow
    red_color:
        mov al, 4
        jmp koniec_kolorow
    blue_color:
        mov al, 20h
        jmp koniec_kolorow

    koniec_pliku_czytaj_kolor:
        mov ax, 0
        jmp koniec_kolorow

    koniec_kolorow:
        ret

CZYTAJ_KOLOR ENDP

CZYTAJ_PLIK PROC 
    ; przygotowanie
    mov cx, 0
    push cx
    mov bx, 0
    push bx
    ;read 
    read_loop:

    czytaj_znak:
        ; czytaj znak
        mov ax, seg buf1
        mov ds, ax
        mov dx, offset buf1 ; ds:dx -> wsk na bufor
        mov cx, 1 ;czytamy max 1 znak

        mov bx, word ptr ds:[wsk1]
        mov ah, 3fh
        int 21h ; wczytaj znaki
        ; if CF=0 then ax = ilosc wczytanych znakow


        cmp ax, 0 ; w ax jest ilosc wczytanych znakow, jak jest 0 to jest EOF
        je koniec_pliku_czytaj_plik


    continue5: ; jak sie znak przeczyta to tu przyjdzie
        ; sprawdzam jaki jest znak
        mov al, byte ptr ds:[buf1]

        cmp al, 0Ah ; koniec linii
        je koniec_linii_czytaj_plik
        cmp al, 0Dh; koniec linii v2
        je koniec_linii_czytaj_plik
        cmp al, ','; przecinek
        je nudy1
        cmp al, ' '; spacja, tak samo reagować jak przecinek
        je nudy1
        cmp al, '0' ; mniejsze niz 0
        jl blad_znak
        cmp al, '9' ; wieksze niz 9
        jg blad_znak
        
        pop bx
        pop cx
        inc cx
        push cx
        push bx
    
        ; calc new bx
        pop ax
        imul ax, 10 ; ax * 10
        mov bx, ax ; ax do bx
        mov al, byte ptr ds:[buf1] ; do ax liczbe
        mov ah, 0 ; gorny bity zerujemy
        sub ax, 30h
        add ax, bx ; dodajemy ax = ax+bx
        push ax ; ax na stos zeby go zachowac
        
        jmp czytaj_znak


    blad_znak: 
        pop ax
        pop cx
        mov bx, -3
        cmp cx, 0
        je brak_znakow_error
        ret

    koniec_linii_czytaj_plik:
        pop ax
        pop cx
        mov bx, -1
        cmp cx, 0
        je brak_znakow_error
        ret

    koniec_pliku_czytaj_plik:
        pop ax
        mov bx, -2
        pop cx
        cmp cx, 0
        je brak_znakow_error
        ret

    nudy1:
        ; do ax liczbe i zamknij plik
        pop ax
        pop cx
        cmp cx, 0
        je brak_znakow_error
        
        mov bx, 0
        ret

    brak_znakow_error:
        jmp koniec_pliku_error_

CZYTAJ_PLIK ENDP 

;...... Rysuje jeden punkt na ekranie z kolorem KD (kolor) o współrzędnych (X_,Y_)
PRINT_POINT PROC
    push ax
    push bx
    push cx
    push dx
    ; 320*y + x
    mov ax, 0a000h
    mov es, ax

    mov bx, 320
    mov ax, word ptr cs:[Y_]
    mul bx ; dx:ax = ax*bx -> ax=y*320

    mov bx, word ptr cs:[X_]
    add bx, ax ; w bx bedzie y*320 + x

    mov al, byte ptr cs:[KD] ; zczytuje kolor

    mov byte ptr es:[bx], al ; zapalam punkt

    pop ax
    pop bx
    pop cx
    pop dx
    
    ret
PRINT_POINT ENDP

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

    just_0:
        mov cx, 1
        mov ax, 0
        push ax

        jmp print1

        ret

    neg1:
        neg ax ; neguje ax bo minusa sb wypisze a dodatnia liczbe normalnie
        push ax ; wrzucam na stos bo za chwile bedzie destrukcja "ax"

        xor ax, ax
        xor dx, dx

        mov dl, 45
        mov ah, 02h ; wypisane minusa
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
;... Algorytm Bresenhama'a
; brany stąd https://www.geeksforgeeks.org/bresenhams-line-generation-algorithm/
Punkt_Bresenham PROC NEAR

        mov ax, word ptr cs:[X1_MAIN]
        mov word ptr cs:[X1_], ax
        mov ax, word ptr cs:[X2_MAIN]
        mov word ptr cs:[X2_], ax
        mov ax, word ptr cs:[Y1_MAIN]
        mov word ptr cs:[Y1_], ax
        mov ax, word ptr cs:[Y2_MAIN]
        mov word ptr cs:[Y2_], ax
        
        ; współrzędne kroku
        mov ax, word ptr cs:[X2_]
        sub ax, word ptr cs:[X1_]
        mov word ptr cs:[DX_], ax ; dx = x2-x1

        mov ax, word ptr cs:[Y2_]
        sub ax, word ptr cs:[Y1_]
        mov word ptr cs:[DY_], ax ; dy = y2-y1

        ;..... tutaj zaczyna sie legit alrogithm bresenhama'a
        mov ax, word ptr cs:[DX_]
        call ABS_ 
        mov word ptr cs:[DX_], ax ; dx_ = abs(dx_)
        mov ax, word ptr cs:[DY_]
        call ABS_
        mov word ptr cs:[DY_], ax ; dy_ = abs(dy_)

        mov dx, word ptr cs:[DX_]
        mov ax, word ptr cs:[DY_]
        cmp dx, ax
        jg DX_jg_DY

    DX_jl_DY:
        mov word ptr cs:[DECIDE_], 1

        mov ax, word ptr cs:[X1_]
        mov bx, word ptr cs:[Y1_]

        mov word ptr cs:[Y1_], ax
        mov word ptr cs:[X1_], bx

        mov ax, word ptr cs:[X2_]
        mov bx, word ptr cs:[Y2_]

        mov word ptr cs:[Y2_], ax
        mov word ptr cs:[X2_], bx

        mov ax, word ptr cs:[DX_]
        mov bx, word ptr cs:[DY_]

        mov word ptr cs:[DX_], bx
        mov word ptr cs:[DY_], ax

        jmp CONTINUE1

    DX_jg_DY:
        mov word ptr cs:[DECIDE_], 0
        jmp CONTINUE1

    CONTINUE1:
        mov word ptr cs:[PK_], 0
        mov ax, word ptr cs:[DY_]
        sub ax, word ptr cs:[DX_]
        mov dx, 2
        imul dx
        mov word ptr cs:[PK_], ax

    ; for loop
        mov ax, word ptr cs:[DX_]
        mov word ptr cs:[I_], ax
        mov cx, word ptr cs:[I_]
    LOOP_I1:
        mov word ptr cs:[I_], cx

        mov ax, word ptr cs:[X1_]
        mov bx, word ptr cs:[X2_]
        cmp ax, bx
        jl X1_jl_X2_loop ; x1++

        ;else x1--
        dec word ptr cs:[X1_]
        jmp CONTINUE2

    X1_jl_X2_loop:
        inc word ptr cs:[X1_]
        jmp CONTINUE2

    CONTINUE2:
        cmp word ptr cs:[PK_], 0
        jl CONTINUE4

        PK_jne_0:
            mov ax, word ptr cs:[Y1_]
            mov bx, word ptr cs:[Y2_]
            cmp ax, bx
            jl Y1_jl_Y2_loop ; Y1++

        ;else Y1--
            dec word ptr cs:[Y1_]
            jmp CONTINUE4

        Y1_jl_Y2_loop:
            inc word ptr cs:[Y1_]
            jmp CONTINUE4
        
        CONTINUE4:
            cmp word ptr cs:[DECIDE_], 0
            je DECIDE_je_0
            DECIDE_jne_0: ; daje y i x odwrotnie
            ; tutaj
                mov ax, word ptr cs:[X1_]
                mov word ptr cs:[Y_], ax
                mov ax, word ptr cs:[Y1_]
                mov word ptr cs:[X_], ax
            ;.....
                call PRINT_POINT
                jmp CONTINUE3

            DECIDE_je_0:
            ; tutaj
                mov ax, word ptr cs:[X1_]
                mov word ptr cs:[X_], ax
                mov ax, word ptr cs:[Y1_]
                mov word ptr cs:[Y_], ax
            ;.....
                call PRINT_POINT
                jmp CONTINUE3
    CONTINUE3:
        ; calc pk
        call PK_CALC

        mov cx, word ptr cs:[I_]
        dec cx
        jnz LOOP_I1
        ; loop LOOP_I1

    exit_punkt_bresenham:
        ret


Punkt_Bresenham ENDP

; dziwne procedury pomocnicze

; abs - zwraca wartosc bezwzgledna z ax do ax
ABS_ PROC
        cmp ax, 0
        jge abs_jge
        neg ax
    abs_jge:
        ret
ABS_ ENDP

; inc PK, warunek w ax
PK_CALC PROC
        mov dx, word ptr cs:[PK_]
        push dx

        mov ax, word ptr cs:[DY_]
        imul ax, 2

        mov bx, ax
        mov ax, word ptr cs:[PK_]
        add ax, bx

        mov word ptr cs:[PK_], ax

        pop dx
        cmp dx, 0 ; w dx trzymam sobie
        jl exit_pk_calc
    pk_calc_jg:
        mov ax, word ptr cs:[DX_]
        imul ax, 2
        mov bx, ax
        mov ax, word ptr cs:[PK_]
        sub ax, bx
        mov word ptr cs:[PK_], ax
    exit_pk_calc:
        ret
PK_CALC ENDP

error__:
    push ax

    mov dx, offset blad_otwarcia
    mov ah, 09h
    int 21h

    mov dl, 10
    mov ah, 02h
    int 21h

    mov dl, 13
    mov ah, 02h
    int 21h

    
    pop ax
    CALL PRINT ; printuje error , bo w ax jest liczba błędu
    jmp koniec_pliku

brak_argumentow_main:
    mov ax, seg brak_args
    mov ds, ax
    mov dx, offset brak_args
    xor ax, ax
    mov ah, 09h
    int 21h
    jmp koniec

koniec_blad:
    mov dx, offset kom_bledu
    mov ax, seg kom_bledu
    mov ds, ax

    xor ax, ax

    mov ah, 09h
    int 21h

koniec:   
    xor ax, ax
    int 16h ; oczekiwanie na klawisz

    mov al,3  ; tryb teskstowy (jeden z nich)
    mov ah, 0 ; zmiana trybu karty VGA
    int 10h ; przerwanie biosu (obsluguje karte graficzna)
    
    ;koniec programu
    mov ah,4ch
    int 21h	

;............................. obiekt punkt XD,YD,KD
; potrzebne do wpisania koloru do punktu, proocedura cala dziala
    KD  db  13
    X_ dw 0
    Y_ dw 0
;............................. 
; to jakies zmienne do algossa bresenhama
    DECIDE_ dw 1
    I_ dw 0

    X1_ dw 0
    Y1_ dw 0
    X2_ dw 0
    Y2_ dw 10

    DX_ dw 1
    DY_ dw 1
    PK_ dw 0
;.............................
; pierwsze wspolrzedne w linii pliku trzeba se zapisac
    Y_pierwszy dw 0
    X_pierwszy dw 0

;.... 
    X1_MAIN dw 0
    X2_MAIN dw 0
    Y1_MAIN dw 0
    Y2_MAIN dw 0

code1 ends


end s1
