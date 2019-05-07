.global main
.global data
.global edgem
.global trim
.global name
.global parsefd
.global zbuffer
.global half
.data
    x: .quad 0
    half: .double .5
    name: .asciz "./image.ppm"
    parsefile: .asciz "./script"
.bss
    data: .zero 1048576
    zbuffer: .zero 2097152
    edgem: .quad 0
    drawm: .quad 0
    trim: .quad 0
    parsefd: .quad 0
.text
main:
    lea zbuffer(%rip), %rdi
    mov minval(%rip), %rax
    mov $262144, %rcx
    rep stosq

    mov $10, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, edgem(%rip)

    mov $4, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, trim(%rip)

    mov $4, %rdi
    mov $4, %rsi
    call makematrix

    push %rax
    mov %rax, %rdi
    call identitymatrix

    mov $16, %rdi
    call malloc@PLT
    mov %rax, cstop(%rip)
    pop %rdi
    mov %rdi, (%rax)

    call init_temps

    mov $2, %rax
    lea parsefile(%rip), %rdi
    xor %rsi, %rsi
    syscall
    mov %rax, parsefd(%rip)

    call parse

    mov $3, %rax
    mov parsefd(%rip), %rdi
    syscall

    mov edgem(%rip), %rdi
    call freematrix

    mov trim(%rip), %rdi
    call freematrix

    call cspop

    call free_temps
    ret
