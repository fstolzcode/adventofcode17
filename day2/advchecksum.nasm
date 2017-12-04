; CHECKSUM CALC by github.com/stolzATrub
; Compile: nasm -f elf64 -F dwarf -g checksum.nasm && gcc -m64 -g checksum.o -o checksum
; Usage: Expects input int "spreadsheet.in", may not exceed 8192 characters

; !!! CURRENTLY NOT WOKRING !!!

global main
extern printf
extern malloc
extern free
extern atoi

;Fixed data
SECTION .data 
filename: db "spreadsheet.in",0
errormsg: db "An error happened",0
format: db "Checksum: %d",10,0
formaterror: db "%s",10,0
formatnumber: db "%d",0

;Store buffer and buffersize
SECTION .bss
bufptr: resb 8
filesize: resb 8
numbuf: resb 128
arrptr: resb 8
arrnum: resb 8

;Get to the code already
SECTION .text
main:
    ;Prolog
    push rbp
    mov rbp, rsp
    
    ;Load the spreadsheet in
    call loadspreadsheet
    test rax,rax
    jnz  error

    call splitspreadsheet
    test rax,rax
    jnz error

    ;Calculate the sum
    ;call calcchecksum

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

splitspreadsheet:
    ;Prolog, register saving, register clearing
    push rbp
    mov rbp, rsp
    push rbx

    mov rsi, [bufptr]
    mov rdi, [filesize]

    xor rax,rax
    xor rbx,rbx

    countLines:
    cmp rbx,rdi
    je doneCountingLines
    mov dl,[rsi + rbx]
    inc rbx
    cmp dl,10
    jne countLines
    inc rax
    jmp countLines

    doneCountingLines:
    mov [arrnum],rax
    mov rbx,8
    mul rbx
    mov rdi, rax
    call malloc
    test rax,rax
    jle allocerror
    mov  [arrptr],rax

    mov rsi, [bufptr]
    mov rdi, [filesize]
    xor rax,rax
    xor rbx,rbx
    xor rcx,rcx
    xor r8,r8

    countEntries:
    cmp rbx,rdi
    je doneCountingEntries
    mov dl,[rsi + rbx]
    inc rbx
    cmp dl,9
    jne countEntries
    cmp dl,10
    je  allocSubArray
    inc rax
    jmp countEntries

    allocSubArray:
    inc rax
    mov rsi,[arrptr]
    mov r8,rax
    mov rax,8
    mul rcx
    inc rcx
    add rsi, rax
    mov rdi, r8
    call malloc


    xor rax,rax
    jmp countEntries


    doneCountingEntries:


    allocerror:
    mov rax,1

    pop rbx
    mov rsp,rbp
    pop rbp
    ret

calcchecksum:
    ;Prolog, register saving, register clearing
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ;Just clear everything
    xor rax,rax
    xor rbx,rbx
    xor rcx, rcx
    xor rdx, rdx
    xor rbx, rbx
    xor r8,r8
    xor r9, r9
    xor r10,r10
    xor r11,r11
    xor r12,r12 ;
    xor r13,r13 ;Max
    xor r14,r14 ;Min
    xor r15,r15 ;Status

    ;Load some pointers and values in
    mov rsi, [bufptr]
    mov rdi, numbuf
    mov r8, [filesize]

    ;Checksum
    push qword 0;

    ;Read one number
    readNumber:
    cmp r15,2               ;Status Code for End of Line
    je parseLineContinue
    cmp rbx,r8              ;Reached end of file
    je break
    mov dl,[rsi + rbx]      ;Move number in
    inc rbx
    cmp dl,10               ;Reached newline
    je parseLine
    cmp dl,9                ;Reached tab
    je parseNumber
    mov [rdi + r12],dl      ;Move the number into the number buffer
    inc r12
    jmp readNumber

    ;Parse the number
    parseNumber:
    call atoi               ;Convert the number buffer
    test rax,rax
    jl parseError
    test r15,r15            ;Status code for first number converted in line
    jnz continueParsing
    mov r13,rax
    mov r14,rax
    inc r15
    continueParsing:        ;Restore some values
    mov rdi, numbuf
    mov rsi, [bufptr]
    mov r8, [filesize]
    rewind:                 ;Clear the numberbuffer
    mov [rdi + r12], BYTE 0
    dec r12
    test r12,r12
    jnz rewind
    mov [rdi + r12], BYTE 0
    cmp rax,r13             ;Check for Min and Max
    jl checkMinimum
    mov r13,rax
    checkMinimum:
    cmp rax,r14
    jge readNumber
    mov r14,rax
    jmp readNumber 
    
    ;Parse the whole line
    parseLine:
    inc r15                 ;Set the status code
    jmp parseNumber         ;Get the last number in the buffer
    parseLineContinue:      ;Calculate the sum and clean up
    sub r13,r14
    pop rax
    add rax,r13
    push rax
    xor r13,r13
    xor r14,r14
    xor r15,r15
    jmp readNumber

    ;Reaching the end
    break:
    pop rax
    jmp calcend

    ;An error happend
    parseError:
    pop rax
    mov rax,-1

    ;Epilog, clean up, restore
    calcend:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp,rbp
    pop rbp
    ret

loadspreadsheet:
    ;Prolog
    push rbp
    mov rbp, rsp

    ;Malloc 8KB
    mov rdi, 8192
    call malloc
    test rax,rax
    jle loaderror

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
    cmp rax,8192
    jge loaderror
    
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