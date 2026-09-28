.model small

; MACROS 
print macro str
    lea dx, str
    mov ah, 09h
    int 21h
endm

.stack 100h

.data
    ; Player Variables
    cash     dw 100      
    tokens   dw 0        
    debt     dw 0        
    bet      dw 0        
    
    ; Statistics & RNG
    g_played dw 0
    g_wins   dw 0
    g_losses dw 0
    seed     db 0        
    sym1     dw 0
    sym2     dw 0
    sym3     dw 0

    ; Main Menu Strings
    newline  db 10, 13, "$"
    
    main_mnu db 10, 13, "=== TERMINAL SLOT MACHINE ==="
             db 10, 13, "1. Buy Tokens (5 Cash = 1 Token)"
             db 10, 13, "2. Manual Spin"
             db 10, 13, "3. Auto-Spin (5 Spins)"
             db 10, 13, "4. Visit Loan Shark (Borrow 50)"
             db 10, 13, "5. View Statistics"
             db 10, 13, "6. Cash Out & Exit"
             db 10, 13, "--------------------------------"
             db 10, 13, "Choice: $"
             
    hdr_csh  db 10, 13, "[Cash: ", "$"
    hdr_tok  db "] [Tokens: ", "$"
    hdr_dbt  db "] [Debt: ", "$"
    hdr_end  db "]", 10, 13, "$"
    
    ; Feature 1 & Loan Strings
    msg_f1   db 10, 13, "Enter Cash to spend (and press ENTER): $"
    msg_err1 db 10, 13, "Error: Not enough cash!$"
    msg_err3 db 10, 13, "Error: Amount must be a multiple of 5!$"
    msg_loan db 10, 13, "The Shark gave you 50 cash. Debt increased!", 10, 13, "$"
    
    ; Slot Machine Strings
    msg_bet  db 10, 13, "Enter token bet per spin (and press ENTER): $"
    msg_err2 db 10, 13, "Error: Not enough tokens!$"
    msg_brk  db 10, 13, "Out of tokens! Stopping auto-spin.", 10, 13, "$"
    
    s_spin   db 10, 13, "[ $"
    s_sep    db " | $"
    s_end    db " ] $"
    
    s_win    db "-> WIN! Payout: $"
    s_lose   db "-> LOST$"
    
    ; Stats & Receipt Strings
    st_title db 10, 13, "--- PLAYER STATS ---$"
    st_p     db 10, 13, "Games Played: $"
    st_w     db 10, 13, "Total Wins:   $"
    st_l     db 10, 13, "Total Losses: $"
    st_d     db 10, 13, "Current Debt: $"
    
    ; Pause & receipt strings
    msg_pause db 10, 13, "Press any key to continue...$"
    r_title  db 10, 13, 10, 13, "=== FINAL RECEIPT ==="
             db 10, 13, "Tokens cashed out.$"
    msg_debt_paid   db 10, 13, "Debt fully repaid.$"
    msg_debt_unpaid db 10, 13, "Cash wasn't enough to cover debt -- lost it all.$"
    r_fin    db 10, 13, "Final Cash: ", "$"

.code
main proc
    mov ax, @data
    mov ds, ax

menu_loop:
    call clear_screen
    call print_header
    print main_mnu

    ; Read menu choice (single keypress)
    mov ah, 01h
    int 21h
    
    cmp al, '1'
    je f1_token
    cmp al, '2'
    je f2_manual
    cmp al, '3'
    je f3_auto
    cmp al, '4'
    je f4_loan
    cmp al, '5'
    je f5_stats
    cmp al, '6'
    je f6_cashout
    
    jmp menu_loop ; Invalid choice, reload menu


; Feature 1: Buy Tokens 
f1_token:
    print msg_f1
    call read_number    
    
    cmp ax, cash
    jg err_token        
    
    mov cx, ax          ; keep the original entered amount
    mov dx, 0           
    mov bx, 5
    div bx              ; ax = amount/5, dx = remainder

    cmp dx, 0
    jne err_token_mult   ; reject if it's not a multiple of 5
    
    mov bx, cash
    sub bx, cx
    mov cash, bx        
    
    add tokens, ax      
    jmp end_feature

err_token_mult:
    print msg_err3
    jmp end_feature

err_token:
    print msg_err1
    jmp end_feature


; Feature 2: Manual Spin
f2_manual:
    print msg_bet
    call read_number
    cmp ax, 0
    je end_feature
    mov bet, ax
    
    cmp ax, tokens
    jg err_tokens
    
    mov bx, tokens
    sub bx, ax
    mov tokens, bx
    
    call do_spin_logic
    jmp end_feature

err_tokens:
    print msg_err2
    jmp end_feature


; Feature 3: Auto-Spin (Loops 5 Times)
f3_auto:
    print msg_bet
    call read_number
    cmp ax, 0
    je end_feature
    mov bet, ax
    
    print newline
    mov cx, 5           
    
auto_loop:
    push cx             
    
    mov ax, bet
    cmp tokens, ax
    jl auto_broke
    
    mov bx, tokens
    sub bx, ax
    mov tokens, bx
    
    call do_spin_logic  
    
    pop cx              
    dec cx
    cmp cx, 0
    jne auto_loop       
    
    jmp end_feature

auto_broke:
    pop cx
    print msg_brk
    jmp end_feature


; Feature 4: Loan Shark
f4_loan:
    add cash, 50
    add debt, 50
    print msg_loan
    jmp end_feature


; Feature 5: Statistics Dashboard
f5_stats:
    call clear_screen
    print st_title
    print st_p
    mov ax, g_played
    call print_number
    print st_w
    mov ax, g_wins
    call print_number
    print st_l
    mov ax, g_losses
    call print_number
    print st_d
    mov ax, debt
    call print_number
    jmp end_feature


; Feature 6: Cash Out & Exit
f6_cashout:
    call clear_screen
    
    mov ax, tokens
    mov bx, 5
    mul bx
    add cash, ax
    mov tokens, 0
    
    mov ax, debt
    cmp ax, 0
    je no_debt_case          ; never had any debt -- say nothing about it

    cmp cash, ax
    jge fully_pay
    
    mov cash, 0         
    print msg_debt_unpaid
    jmp print_receipt
    
fully_pay:
    mov bx, cash
    sub bx, ax
    mov cash, bx
    print msg_debt_paid
    jmp print_receipt

no_debt_case:

print_receipt:
    print r_title
    print r_fin
    mov ax, cash
    call print_number
    print newline
    
    mov ax, 4c00h
    int 21h


; Helper: Wait for keypress
end_feature:
    print newline
    print msg_pause
    mov ah, 07h
    int 21h
    jmp menu_loop
main endp


; HELPER PROCEDURES

; Main Game: Spin the Reels
do_spin_logic proc
    inc g_played
    print s_spin
    
    mov bx, 3
    call get_random
    mov sym1, ax

    mov bx, 3
    call get_random
    mov sym2, ax

    mov bx, 3
    call get_random
    mov sym3, ax
    
    mov ax, sym1
    add al, 'A'
    call print_char
    print s_sep
    
    mov ax, sym2
    add al, 'A'
    call print_char
    print s_sep
    
    mov ax, sym3
    add al, 'A'
    call print_char
    print s_end
    
    mov ax, sym1
    cmp ax, sym2
    jne lost_slots
    mov ax, sym2
    cmp ax, sym3
    jne lost_slots
    
    inc g_wins
    print s_win
    mov ax, bet
    mov bx, 5
    mul bx              
    call print_number
    add tokens, ax
    ret

lost_slots:
    inc g_losses
    print s_lose
    ret
do_spin_logic endp


; Helper: RNG using DIV
get_random proc
    push cx
    push dx
    
    mov ah, 2Ch         
    int 21h             

    ; 8-bit LCG: seed = seed*5 + 3, mixed with the current clock
    ; tick (DL) so the three calls in one spin don't fall into a
    ; fixed, predictable pattern.
    mov al, seed
    mov cl, 5
    mul cl              ; al = (seed * 5) low byte
    add al, 3
    add al, dl
    mov seed, al
    
    mov ah, 0
    mov dx, 0           
    div bx              
    
    mov ax, dx          
    
    pop dx
    pop cx
    ret
get_random endp


; Helper: Number Printer (Uses Stack)
print_number proc
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0           
    mov bx, 10          
    
    cmp ax, 0
    jne split_loop
    
    mov ah, 02h
    mov dl, '0'
    int 21h
    jmp end_print
    
split_loop:
    mov dx, 0           
    div bx              
    push dx             
    inc cx
    cmp ax, 0
    jne split_loop
    
print_stack:
    pop dx              
    add dl, 30h         
    mov ah, 02h
    int 21h
    loop print_stack
    
end_print:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number endp


; Helper: Read Multi-Digit Number
read_number proc
    push bx
    push cx
    push dx
    
    mov bx, 0           
read_loop:
    mov ah, 01h
    int 21h             
    
    cmp al, 13          
    je done_read
    
    ; ignore any key that isn't an ASCII digit '0'-'9'
    cmp al, '0'
    jl read_loop
    cmp al, '9'
    jg read_loop
    
    sub al, 30h         
    mov ah, 0
    mov cx, ax          
    
    mov ax, bx          
    mov dx, 10
    mul dx              
    add ax, cx          
    mov bx, ax          
    
    jmp read_loop
    
done_read:
    mov ax, bx          
    
    pop dx
    pop cx
    pop bx
    ret
read_number endp


; Helper: Print Single Char
print_char proc
    push dx
    mov dl, al
    mov ah, 02h
    int 21h
    pop dx
    ret
print_char endp


; Helper: Print Dashboard Header
print_header proc
    print hdr_csh
    mov ax, cash
    call print_number
    
    print hdr_tok
    mov ax, tokens
    call print_number
    
    print hdr_dbt
    mov ax, debt
    call print_number
    
    print hdr_end
    ret
print_header endp


; HELPER: Clear Screen
; Resets video mode 03h
clear_screen proc
    push ax
    mov ah, 0
    mov al, 03h
    int 10h
    pop ax
    ret
clear_screen endp

end main