; SPIRAL CALC by github.com/stolzATrub
; Compile: nasm -f elf64 -F dwarf -g spiral.nasm && gcc -m64 -g spiral.o -o spiral
; Usage: Input is hardcoded, sorry

global main
extern printf
extern malloc
extern free
extern atoi

;Fixed data
SECTION .data 
errormsg: db "An error happened",0
format: db "Steps: %d",10,0
formaterror: db "%s",10,0

SECTION .bss

;Get to the code already
SECTION .text
main:
    ;Prolog
    push rbp
    mov rbp, rsp

    ;Calculate the steps
    mov  rdi, 277678
    call calcsteps

    ;printf the steps
    mov rdi,format
    mov rsi,rax
    xor rax,rax
    call printf

    ;done
    jmp end

    ;print error in case
    error:
    mov rdi,formaterror
    mov rsi,errormsg
    xor rax,rax
    call printf

    ;Epilog
    end:
    mov rsp,rbp
    pop rbp

    xor rax, rax
    ret
    
calcsteps:
    ;Prolog, register saving, register clearing
    push rbp
    mov rbp, rsp
    push rbx

    xor rax,rax ; Current Value
    xor rbx,rbx
    xor rcx,rcx ; X
    xor rdx,rdx ; Y

    inc rax ; 1 (0,0)
    inc rbx ; Radius 1
    inc rcx ; X = 1
    inc rax; 2 (1,0)

    spiralUp:
    inc rdx ;Go up
    inc rax
    cmp rax,rdi ;Check found
    je found
    cmp rdx,rbx ;Check Radius
    jne spiralUp

    neg rbx ;Negate Radius
    spiralLeft:
    dec rcx ;Go left
    inc rax
    cmp rax,rdi
    je found
    cmp rcx,rbx
    jne spiralLeft

    spiralDown:
    dec rdx ;Go Down
    inc rax
    cmp rax,rdi
    je found
    cmp rdx,rbx
    jne spiralDown

    neg rbx ;Get the positive radius again
    spiralRight:
    inc rcx ;Go Right
    inc rax
    cmp rax,rdi
    je found
    cmp rcx,rbx
    jne spiralRight

    inc rbx ;One spiral full, go to next radius
    inc rcx ;Advance the X coordinate
    inc rax
    cmp rax,rdi
    je found
    jmp spiralUp


    found:
    xor rax,rax ;Answer is the sum of both coordinates
    cmp rcx,rax ;Negative coordinates if they are negative
    jge noXNegation
    neg rcx
    noXNegation:
    cmp rdx,rax
    jge noYNegation
    neg rdx
    noYNegation:
    add rax,rcx
    add rax,rdx

    pop rbx
    mov rsp,rbp
    pop rbp
    ret