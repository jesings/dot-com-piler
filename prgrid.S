.global pr
.data
.align 16
strResult: .zero 4# string buffer to store results
.align 32
message: .asciz  "P6 512 512 255\n"
.text
pr://move filename into %rdi
#open file
    mov $2, %rax
    mov $65, %rsi                # open for writing and CREAT flag
    mov $0777, %rdx
    syscall
    mov %rax, %rdi

#write initial string to file (header) 
    mov $1, %rax
    lea message(%rip), %rsi          # address of string to output
    mov $15, %rdx               # number of bytes
    syscall
    mov $0, %rdx
#do draw

    mov $0, %rcx
    lea data(%rip), %rsi
    dumdumlup:
    mov $3, %rdx
    mov $1, %rax
    push %rcx
    push %rsi
    syscall
    pop %rsi
    pop %rcx
    add $4, %rsi
    inc %rcx
    cmp $262144, %rcx
    jne dumdumlup

    mov $3, %rax
    syscall
    ret
