.global pr
.data
strResult: .zero 4# string buffer to store results
newl: .asciz "\n"
message: .asciz  "P3 512 512 255\n"
.text
pr://move filename into %rdi
    push %rbx
    push %r13
    push %r12
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
    lea data(%rip), %r8
    mov $0, %r13
imgy:
    mov $0, %r12
imgx:
    push %rdi
    movzb (%r8), %rdi
    call convert
    pop %rdi
    mov %rbx, %rdx
    mov %rax,%rsi
    mov $1, %rax
    syscall
    inc %r8
    xor %rax, %rax
    push %rdi
    movzb (%r8), %rdi
    call convert
    pop %rdi
    mov %rbx, %rdx
    mov %rax,%rsi
    mov $1, %rax
    syscall
    inc %r8
    xor %rax, %rax
    push %rdi
    movzb (%r8), %rdi
    call convert
    pop %rdi
    mov %rbx, %rdx
    mov %rax,%rsi
    mov $1, %rax
    syscall
    inc %r8
    inc %r8
#handle loop stuff
    inc %r12
    cmp $512, %r12
    jl  imgx

    lea newl(%rip), %rsi
    mov $1, %rdx
    mov $1, %rax
    syscall

    inc %r13
    cmp $512, %r13
    jl  imgy
#close file
    mov $3, %rax
    syscall
    pop %r12
    pop %r13
    pop %rbx
    ret
convert: #convert takes in a byte value in rax and returns its string representation in rsi, and returns the length in rbx (NOTE: NOT C COMPLIANT, RBX IS SUPPOSED TO BE A CALLER SAVED REGISTER BUT IS NEEDED FOR OUTPUT, but I'm too lazy to change anything right now so this should only be used as a planned subroutine and even then probably not much.) mov %rdi, %rax
    mov %rdi, %rax
    mov $10,%rcx         # divisor
    xor %rbx, %rbx         # count digits
divide:
    xor %rdx, %rdx       # high part = 0
    div %rcx             # rax = rdx:rax/rcx, rdx = remainder
    push %dx             # a digit in range [0..9]
    inc %bx              # count digits
    cmp $0, %rax         # rax is 0?
    jnz divide           # no, continue
    mov %bx, %cx         # pop digits from stack in reverse order
    lea strResult(%rip), %rsi  # ds:si points to string buffer
next_digit:
    pop %ax
    add $0x30, %al       # convert to ASCII
    movb %al,(%rsi)       # write it to the buffer
    inc %rsi
    dec %rcx
    jg next_digit
    mov $0x20,%al
    movb %al,(%rsi)       # write it to the buffer
    lea strResult(%rip), %rax
    inc %bx
    mov %rbx,%rcx
    ret
