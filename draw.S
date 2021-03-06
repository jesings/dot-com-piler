.global draw
.global edgem
.global trim
.global name
.global parsefd
.global zbuffer
.global half
.global data
.global minval
.data
    .align 32
    x: .quad 0
    half: .double .5
    .align 32
    name: .asciz "./image.ppm"
    .align 32
    parsefile: .asciz "./script"
    .align 32
    minval: .double -inf
.bss
    .align 32
    data: .zero 1048576
    zbuffer: .zero 2097152
    .align 32
    edgem: .quad 0
    drawm: .quad 0
    trim: .quad 0
    parsefd: .quad 0
.text
draw:
    lea zbuffer(%rip), %rdi
    mov minval(%rip), %rax
    mov $262144, %rcx
    rep stosq//fill zbuffer with -infinity double

    mov $10, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, edgem(%rip)//make tiny dummy edge matrix

    mov $4096, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, trim(%rip)//make tiny dummy trimatrix

    mov $4, %rdi
    mov $4, %rsi
    call makematrix
    push %rax
    mov %rax, %rdi
    call identitymatrix//make identity coordinate stack matrix
    mov $16, %rdi
    call malloc@PLT
    mov %rax, cstop(%rip)
    pop %rdi
    mov %rdi, (%rax)

    call init_temps//initialize temporary values

    xor %rax, %rax
    nextop:
    push %rax
    call handleop
    pop %rax
    inc %rax
    cmp lastop(%rip), %rax
    jl nextop


    mov edgem(%rip), %rdi
    call freematrix//free edge matrix

    mov trim(%rip), %rdi
    call freematrix//free trimatrix

    csstackstill:
    call cspop//free last item on coordinate stack
    cmpq $0, cstop(%rip)
    jne csstackstill

    call free_temps
    ret
