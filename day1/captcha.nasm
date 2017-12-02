; CAPTCHA SOLVER by github.com/stolzATrub
; Compile: nasm -f elf64 -F dwarf -g captcha.nasm && gcc -m64 -g captcha.o -o captcha
; Usage: Expects input int "captcha.in", may not exceed 4096 characters

global main
extern printf
extern malloc
extern free

;Fixed data
SECTION .data 
filename: db "captcha.in",0
errormsg: db "An error happened",0
format: db "Captcha: %d",10,0
formaterror: db "%s",10,0

;Store buffer and buffersize
SECTION .bss
bufptr: resb 8
filesize: resb 8

;Get to the code already
SECTION .text
main:
    ;Prolog
    push rbp
    mov rbp, rsp
    
    ;Load the captcha in
    call loadcaptcha
    test rax,rax
    jnz  error

    ;Calculate the sum
    call calccaptcha

    ;printf the sum
    mov rdi,format
    mov rsi,rax
    xor rax,rax
    call printf

    ;free the buffer
    mov rdi,[bufptr]
    call free

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

calccaptcha:
    ;Epilog, register saving, register clearing
    push rbp
    mov rbp, rsp
    push rbx

    xor rsi,rsi
    xor rdi,rdi
    xor rax,rax
    xor rbx,rbx
    xor rcx,rcx
    xor rdx,rdx

    ;Get the start and the end of the buffer
    mov rsi,[bufptr]
    mov rdi,[filesize]
    add rdi,rsi
    sub rdi,1
    mov rbx,rsi

    ;Check if two consecutive numbers are the same, if yes add number to accumulator
    loopback:
    cmp rbx,rdi
    je break
    mov cl,[rbx]
    sub cl,48
    inc rbx
    mov dl,[rbx]
    sub dl,48
    xor cl,dl
    jnz loopback
    add rax,rdx
    jmp loopback

    ;Check the edge case
    break:
    mov cl,[rsi]
    mov dl,[rdi]
    sub cl,48
    sub dl,48
    xor cl,dl
    jnz skiplast
    add rax,rdx

    ;Epilod
    skiplast:

    pop rbx
    mov rsp,rbp
    pop rbp
    ret

loadcaptcha:
    ;Prolog
    push rbp
    mov rbp, rsp

    ;Malloc 4KB
    mov rdi, 4096
    call malloc
    test rax,rax
    jle error

    mov r8,rax ;r8 malloc pointer

    ;Get the file descriptor
    mov rdi,filename
    xor rsi, rsi
    xor rdx, rdx
    mov rax, 2
    syscall
    test rax,rax
    jle loaderror

    ;Get the size
    mov r9, rax ;r9 fd
    mov rdi,rax
    mov rax,8
    xor rsi,rsi
    xor rdx,2
    syscall
    test rax,rax
    jle loaderror
    cmp rax,4096
    jge error
    
    mov r10,rax ;r10 filesize

    ;Seek back to filestart
    mov rdi,r9
    mov rax,8
    xor rsi,rsi
    xor rdx,rdx
    syscall
    test rax,rax
    jl loaderror

    ;Read everything into the buffer
    mov rdi,r9
    mov rsi,r8
    mov rdx,r10
    xor rax,rax
    syscall
    test rax,rax
    jl loaderror

    ;Close the file
    mov rax,3
    mov rdi,r9
    syscall
    test rax,rax
    jl loaderror

    ;Save the data
    mov [bufptr],r8
    mov [filesize],r10

    ;Epilog, return 0
    xor rax,rax

    mov rsp,rbp
    pop rbp
    ret

    ;return 1 if error
    loaderror:
    mov rax,1
    mov rsp,rbp
    pop rbp
    ret