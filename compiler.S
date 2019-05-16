#define COMMENT 258
#define PADDING COMMENT*8
.global add_symbol
.global lookup_symbol
.global set_value
.global symtab
.global lastsym
.global handleop
.global _convert
.global lastop
.data
    lastsym: .quad 0
    lastop: .quad 0
    convert: .asciz "convert"
    display: .asciz "display"
    buf: .zero 1024
    indices: .quad 0,4,8,0
    .set max_symbols,512
    .set stlen,max_symbols*8*3
    symtab: .zero stlen
    branchtable:
    .zero PADDING
    .quad .comment
    .quad .doubleval
    .quad .light
    .quad .ambient
    .quad .constants
    .quad .save_coords
    .quad .camera
    .quad .sphere
    .quad .torus
    .quad .box
    .quad .lineval
    .quad .csval
    .quad .mesh
    .quad .texture
    .quad .stringval
    .quad .setval
    .quad .move
    .quad .scale
    .quad .rotate
    .quad .basename
    .quad .save_knobs
    .quad .tween
    .quad .frames
    .quad .vary
    .quad .push
    .quad .pop
    .quad .save
    .quad .generate_rayfiles
    .quad .shading
    .quad .shading_type
    .quad .setknobs
    .quad .focal
    .quad .display
    .quad .web
    .quad .co
.macro cspeek//Peek at the top of the coordinate system stack
    mov cstop(%rip), %rdi
    mov (%rdi), %rdi
.endm
.macro applytris//Applies the current top of the coordinate system to the triangle matrix
    cspeek
    mov trim(%rip), %rsi
    call multiplymatrix
    call drawtris
    mov trim(%rip), %rdi
    movq $0, 24(%rdi)
.endm
.macro applyedges//Same as above function but for edge matrices
    cspeek
    mov edgem(%rip), %rsi
    call multiplymatrix
    mov edgem(%rip), %rdi
    mov $0xffffff, %rsi
    call drawedges
    mov edgem(%rip), %rdi
    movq $0, 24(%rdi)
.endm
.text
//SYMTAB pseudo-struct: char* name, long int type, union data (either a pointer to light,constants, or matrix) or a double
handleop://raxth element of symtab
    lea op(%rip), %rdi
    imul $280, %rax
    add %rax, %rdi
    mov (%rdi), %rax
    lea branchtable(%rip), %rcx
    jmp *(%rcx,%rax,8);
    .comment:
    ret
    .doubleval:
    .light:
    vmovupd 16(%rdi), %ymm0
    vxorpd zeros(%rip), %ymm0, %ymm0
    vmovupd %ymm0, lightloc(%rip)
    ret
    .ambient:
    vmovupd 8(%rdi), %ymm0
    vmovupd %ymm0, ambient(%rip)
    ret
    .constants:
    //yikes
    ret
    .save_coords:
    ret
    .camera:
    ret
    .sphere://allow constants for lighting
    call constantine
    vmovsd 16(%rdi), %xmm0
    vmovsd 24(%rdi), %xmm1
    vmovsd 32(%rdi), %xmm2//skip to radius
    vmovsd 48(%rdi), %xmm3
    mov edgem(%rip), %rdi
    call makesphere
    applytris
    ret
    .torus:
    call constantine
    vmovsd 16(%rdi), %xmm0
    vmovsd 24(%rdi), %xmm1
    vmovsd 32(%rdi), %xmm2//skip to radii
    vmovsd 48(%rdi), %xmm3
    vmovsd 56(%rdi), %xmm4
    mov edgem(%rip), %rdi
    call maketorus
    applytris
    ret
    .box:
    call constantine
    vmovsd 16(%rdi), %xmm0
    vmovsd 24(%rdi), %xmm1
    vmovsd 32(%rdi), %xmm2//skip to other point
    vmovsd 48(%rdi), %xmm3
    vmovsd 56(%rdi), %xmm4
    vmovsd 64(%rdi), %xmm5
    mov edgem(%rip), %rdi
    call makebox
    applytris
    ret
    .lineval://also allow constants
    call constantine
    vmovsd 16(%rsi), %xmm0
    vmovsd 24(%rsi), %xmm1
    vmovsd 32(%rsi), %xmm2//skip last element of first array
    vmovsd 48(%rsi), %xmm3
    vmovsd 56(%rsi), %xmm4
    vmovsd 64(%rsi), %xmm5
    push %rdi
    mov edgem(%rip), %rdi
    call addedge
    pop %rdi//use cs pointed to in struct
    applyedges
    ret
    .csval:
    .mesh:
    .texture:
    .stringval:
    .setval:
    ret
    .move:
    vmovsd 8(%rdi), %xmm0
    vmovsd 16(%rdi), %xmm1
    vmovsd 24(%rdi), %xmm2
    cspeek
    lea transform(%rip), %rax
    call genmanipulate
    ret
    .scale:
    vmovsd 8(%rdi), %xmm0
    vmovsd 16(%rdi), %xmm1
    vmovsd 24(%rdi), %xmm2
    cspeek
    lea dilate(%rip), %rax
    call genmanipulate
    ret
    .rotate:
    vmovsd 8(%rdi), %xmm0
    vcvtsd2si %xmm0, %rax
    vmovsd 16(%rdi), %xmm0
    push %rax
    push %rdx
    call deg2rad
    pop %rdx
    pop %rax
    lea rotateaxes(%rip), %rdx
    jmp *(%rdx,%rax,8)
    .data
    rotateaxes:
    .quad .rotatex
    .quad .rotatey
    .quad .rotatez
    .text
    .rotatex:
    lea rotatex(%rip), %rax
    jmp endro
    .rotatey:
    lea rotatey(%rip), %rax
    jmp endro
    .rotatez:
    lea rotatez(%rip), %rax
    endro:
    cspeek
    call genrotate
    ret
    .basename:
    .save_knobs:
    .tween:
    .frames:
    .vary:
    ret
    .push:
    call cspush
    ret
    .pop:
    call cspop
    ret
.macro destroyfile//removes the temporary file created for either display or save
    mov $87, %rax
    lea name(%rip), %rdi
    syscall//remove temporary file
.endm
    .save:
    mov $57, %rax
    syscall
    test %rax, %rax
    jnz sover
    mov 8(%rdi), %rsi
    mov (%rsi), %rsi//name
    push %rsi
    lea name(%rip), %rdi
    call pr
    pop %rsi
    vmovups (%rsi), %ymm1
    movsd convert(%rip),%xmm0
    movsd %xmm0, buf(%rip)
    lea buf(%rip), %rdi
    movb $0x0, 7(%rdi)
    movupd name(%rip), %xmm0
    movupd %xmm0, 8(%rdi)
    movb $0x0, 19(%rdi)
    vmovupd %ymm1, 20(%rdi)
    mov %rdi, %rsi
    mov %rsi, %rdx
    mov %rdx, %rcx
    add $8, %rdx
    add $20, %rcx
    mov $0, %r8

    call execlp@PLT
    sover:
    mov $61, %rax
    mov $-1, %rdi
    xor %rsi, %rsi
    xor %rdx, %rdx
    xor %rcx, %rcx
    syscall
    destroyfile
    ret
    .generate_rayfiles:
    .shading:
    .shading_type:
    .setknobs:
    .focal:
    .display:
    lea name(%rip), %rdi
    call pr
    mov $57, %rax
    syscall
    test %rax, %rax
    jnz dover
    vmovupd name(%rip), %ymm1
    movsd display(%rip),%xmm0
    lea buf(%rip), %rdi
    movsd %xmm0, (%rdi)
    movb $0x0, 7(%rdi)
    vmovupd %ymm1, 8(%rdi)
    mov %rdi, %rsi
    mov %rsi, %rdx
    add $8, %rdx
    mov $0, %rcx
    call execlp@PLT
    dover:
    mov $61, %rax
    mov $-1, %rdi
    xor %rsi, %rsi
    xor %rdx, %rdx
    xor %rcx, %rcx
    syscall
    destroyfile
    ret
    .web:
    .co:
    ret
    //p *(double[12]*)((((double*[3])symtab)[2])+2)
constantine:
    push %rdi
    mov 8(%rdi), %rdi
    test %rdi, %rdi
    jz noconstant
    mov 16(%rdi), %rsi
    vmovupd indices(%rip), %ymm1

    vmovupd mask(%rip), %ymm2
    vgatherqpd %ymm2, (%rsi,%ymm1,8), %ymm0
    vandpd mask(%rip), %ymm0, %ymm0
    vmovupd %ymm0, Ka(%rip)

    vmovupd mask(%rip), %ymm2
    vgatherqpd %ymm2, 8(%rsi,%ymm1,8), %ymm0
    vandpd mask(%rip), %ymm0, %ymm0
    vmovupd %ymm0, Kd(%rip)

    vmovupd mask(%rip), %ymm2
    vgatherqpd %ymm2, 16(%rsi,%ymm1,8), %ymm0
    vandpd mask(%rip), %ymm0, %ymm0
    vmovupd %ymm0, Ks(%rip)

    pop %rdi
    ret
    noconstant:
    call cleanup
    pop %rdi
    ret
cleanup:
    vmovupd Kad(%rip), %ymm0
    vmovupd %ymm0, Ka(%rip)
    vmovupd Kdd(%rip), %ymm0
    vmovupd %ymm0, Kd(%rip)
    vmovupd Ksd(%rip), %ymm0
    vmovupd %ymm0, Ks(%rip)
    ret
add_symbol://rdi: char^ name, rsi long int type, rdx void* data
    push %rdi
    push %rsi
    push %rdx
    call lookup_symbol
    pop %rdx
    pop %rsi
    pop %rdi
    test %rax, %rax
    jnz badendadd
    cmpq $max_symbols, lastsym(%rip)
    jge badendadd
    lea symtab(%rip), %rcx
    mov lastsym(%rip), %rax
    imul $24, %rax
    add %rax, %rcx
    incq lastsym(%rip)
    mov %rsi, 8(%rcx)
    mov %rdx, 16(%rcx)
    push %rcx
    push %rdi
    call mstrlen
    mov %rax, %rdi
    call malloc@PLT
    pop %rdi
    mov %rax, %rsi
    push %rsi
    call mstrcpy
    pop %rsi
    pop %rax
    mov %rsi, (%rax)
    badendadd:
    ret
lookup_symbol://rdi char* name
    xor %rax, %rax
    cmp lastsym(%rip), %rax
    je notfound
    lea symtab(%rip), %rsi
    finding:
    push %rax
    push %rsi
    mov (%rsi),%rsi
    call mstrcmp
    mov %rax, %rdx
    pop %rsi
    pop %rax
    test %rdx, %rdx
    jz found
    add $24, %rsi
    inc %rax
    cmp lastsym(%rip), %rax
    jl finding
    notfound:
    xor %rax, %rax
    ret
    found:
    mov %rsi, %rax
    ret
    
set_value://rdi symtab* p , xmm0 double value
    movsd %xmm0, 16(%rdi)
    ret

mstrcmp:
    mov $-16, %rax
    compareloop:
    add $16, %rax
    movdqu (%rdi,%rax), %xmm1 # read 16 bytes of string 1
    pcmpistri $0b00011000, (%rsi,%rax), %xmm1 # unsigned bytes, equal each, invert. returns index in ecx
    jnbe compareloop # jump if not carry flag and not zero flag
    jnc equal
    notequal:
    # strings are not equal
    add %rax, %rcx # offset to first differing byte
    movzxb (%rdi,%rcx), %rax # compare first differing byte
    movzxb (%rsi,%rcx), %edx
    sub %rdx, %rax
    ret
    equal:
    xor %eax, %eax               # strings are equal
    ret

mstrlen:
    mov %rdi, %rax
    mov %edi, %ecx
    pxor %xmm0, %xmm0
    and $0x0F, %ecx
    and $-0x10, %rax
    movdqa (%rax), %xmm1
    pcmpeqb %xmm0, %xmm1
    pmovmskb %xmm1, %edx
    shr %cl, %edx
    shl %cl, %edx
    bsf %edx, %edx
    jnz  L2
    L1:     
    add $0x10, %rax
    movdqa (%rax), %xmm1
    pcmpeqb %xmm0, %xmm1
    pmovmskb %xmm1, %edx
    bsf %edx, %edx
    jz L1
    sub %rdi, %rax
    add %rdx, %rax
    ret    
    L2:# Zero-byte found. Compute string length
    sub %rdi, %rax
    add %rdx, %rax
    ret

mstrcpy://source in rdi, dest in rsi
    push %rdi
    push %rsi
    call mstrlen
    pop %rdi
    pop %rsi//exchanged positions
    mov %rax, %rcx
	cld
	rep movsb
	ret
