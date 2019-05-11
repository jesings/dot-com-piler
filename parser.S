.macro cspeek//Peek at the top of the coordinate system stack
    mov cstop(%rip), %rdi
    mov (%rdi), %rdi
.endm
.macro argy numargs//get numargs args from global args, and put them into xmm registers in reverse order
    call inpstream
    lea buf(%rip), %rdi
    mov $\numargs, %rsi
    call getargs
    mov $\numargs, %rdi
    call convertargs
    lea args(%rip), %r8
    .altmacro
    argshelper %(\numargs-1), 0
.endm
.macro argshelper regn, argo//This just writes the code for putting the args into xmm registers in reverse order
.altmacro
    movsd \argo(%r8), %xmm\regn
    .if \regn
        argshelper %(\regn-1), %(\argo+8)
    .endif
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
.macro calctoken token, fxn//call fxn if the string pointed to by token is equivalent to the string that was just input
    lea \token(%rip), %rsi
    call mstrcmp
    test %rax, %rax
    jne \fxn
.endm
.macro manipulatefxn token,manip,labelname//calls genmanipulate with either translate or scale in manip if the token stuff as discussed above work. Labelname needs to be unique from all other labelnames in all other kinds of functions like this
    lea \token(%rip), %rsi
    call mstrcmp
    test %rax, %rax
    je \labelname
    argy 3
    cspeek
    lea \manip(%rip), %rax
    call genmanipulate
    jmp afterl
    \labelname:
.endm
.macro shapefxn token, num, makefxn, apply, labelname, matrix//calls a function to draw a shape (line,box,sphere,torus,circle) in mkfxn if token stuff works, gathers the numbers of args specified as numargs, applies them to the proper matrix, either trim or edgem, labelname is still unique
    lea \token(%rip), %rsi
    call mstrcmp
    test %rax, %rax
    je \labelname
    argy \num
    mov \matrix(%rip), %rdi
    call \makefxn
    \apply
    jmp afterl
    \labelname:
.endm
.macro splinefxn word, matrixname, labelname//generates a spline (specified by which spline matrix to use, either beziermatrix or hermitematrix) if token stuff works, unique labelname
    lea \word(%rip), %rsi
    call mstrcmp
    test %rax, %rax
    je \labelname
    argy 8
    mov edgem(%rip), %rdi
    lea \matrixname(%rip), %rsi
    call makespline
    applyedges
    jmp afterl
    \labelname:
.endm
.macro csparse word, csfunc, labelname//pops or pushes from cs stack if tokenstuff works, unique labelname
    lea \word(%rip), %rsi
    call mstrcmp
    test %rax, %rax
    je \labelname
    call \csfunc
    jmp afterl
    \labelname:
.endm
.global parse
.global minval
.data
    .align 32
    line: .asciz "line"
    .align 32
    scale: .asciz "scale"
    .align 32
    move: .asciz "move"
    .align 32
    rotate: .asciz "rotate"
    .align 32
    display: .asciz "display"
    .align 32
    save: .asciz "save"
    .align 32
    _convert: .asciz "convert"
    .align 32
    circle: .asciz "circle"
    .align 32
    hermite: .asciz "hermite"
    .align 32
    bezier: .asciz "bezier"
    .align 32
    box: .asciz "box"
    .align 32
    sphere: .asciz "sphere"
    .align 32
    torus: .asciz "torus"
    .align 32
    cspushm: .asciz "push"
    .align 32
    cspopm: .asciz "pop"
    .align 32
    clear: .asciz "clear"
    .align 32
    minval: .double -inf
    double10: .double 10
.bss
    .align 32
    buf: .zero 1024
    curchar: .byte 0
    args: .zero 64
    lens: .zero 64
    decimals: .zero 64
    streamdone: .byte 0
.text
rotatel://Rotates by either x, y, or z, depending -- complex args parsing necessary
    call inpstream
    lea buf(%rip),%rdi
    mov $2, %rsi
    call getargs
    lea args(%rip), %r8
    mov 8(%r8), %rax
    push %rax
    mov $2, %rdi
    call convertargs
    lea args(%rip), %r8
    movsd (%r8), %xmm0
    call deg2rad
    pop %rax
    cmpb $0x79,(%rax)
    je doyro
    jg dozro
    lea rotatex(%rip), %rax
    jmp endro
    doyro:
    lea rotatey(%rip), %rax
    jmp endro
    dozro:
    lea rotatez(%rip), %rax
    endro:
    cspeek
    call genrotate
    jmp afterl
.macro destroyfile a,b,c//removes the temporary file created for either display or save
    movups %xmm0, \a(%rdi)
    movb $0x20, \b(%rdi)
    vmovups %ymm1, \c(%rdi)
    call system@plt
    mov $87, %rax
    lea name(%rip), %rdi
    syscall//remove temporary file
    jmp afterl
.endm
displayl://Displays the image
    lea name(%rip), %rdi
    call pr
    vmovups name(%rip), %ymm1
    movsd display(%rip),%xmm0
    lea buf(%rip), %rdi
    destroyfile 0,7,8
savel://saves the image into the proper filename, which is unfortunately capped at 31 chars
    lea name(%rip), %rdi
    call pr
    call inpstream
    vmovups buf(%rip), %ymm1
    movsd _convert(%rip),%xmm0
    movsd %xmm0, buf(%rip)
    lea buf(%rip), %rdi
    movb $0x20, 7(%rdi)
    movups name(%rip), %xmm0
    destroyfile 8,19,20
clearl:
    lea zbuffer(%rip), %rdi
    mov minval(%rip), %rax
    mov $262144, %rcx
    rep stosq
    lea data(%rip), %rdi
    xor %rax, %rax
    mov $98304, %rcx
    rep stosq
    jmp afterl
inpstream://file descriptor in parsefd(%rip), returns a string in %rax, or 0 if an EOF is encountered
    mov parsefd(%rip), %rdi
    xor %rcx, %rcx
    lea curchar(%rip), %rsi
    mov $1, %rdx
    nchar:
    xor %rax, %rax
    push %rcx
    syscall
    pop %rcx
    mov curchar(%rip), %r8b
    lea buf(%rip), %r9
    movb %r8b, (%r9,%rcx)
    inc %rcx
    cmp $0, %rax
    jne noteof
    movb $0, (%r9,%rcx)
    movb $1, streamdone(%rip)
    ret
    noteof:
    cmpb $0xA,curchar(%rip)
    jne nchar
    dec %rcx
    movb $0, (%r9,%rcx)
    lea buf(%rip), %rax
    ret
parse://parses the script file
    parseloop:
    call inpstream
    mov %rax, %rdi
    movb streamdone(%rip), %al
    cmpb $1, %al
    je end//the input is compared to a series of tokens to check for equality, execute that one, parse next line
    manipulatefxn scale, dilate,.a
    manipulatefxn move, transform,.b
    shapefxn circle, 4, makecircle, applyedges, .c, edgem
    shapefxn sphere, 4, makesphere, applytris, .d, trim
    shapefxn torus, 5, maketorus, applytris, .e, trim
    shapefxn box, 6, makebox, applytris, .f, trim
    shapefxn line, 6, addedge, applyedges, .g, edgem
    splinefxn hermite, hermitematrix, .h
    splinefxn bezier, beziermatrix, .i
    csparse cspushm, cspush, .j
    csparse cspopm, cspop, .k
    calctoken rotate, rotatel
    calctoken display, displayl
    calctoken save, savel
    calctoken clear, clearl
    afterl:
    movb streamdone(%rip), %al
    cmpb $1, %al
    je end
    //rax is the string
    jmp parseloop
    end:
    ret
strlen://rdi is the string
    xor %rax, %rax
    lstart:
    movb (%rdi, %rax), %cl
    testb %cl,%cl 
    je lenend
    inc %rax
    jmp lstart
    lenend:
    ret
mstrcmp://rdi is string 1, rsi is string 2
    xor %rax, %rax
    cmpstart:
    movb (%rdi, %rax), %cl
    test %cl, %cl
    je nend
    movb (%rsi, %rax), %dl
    cmpb %cl,%dl 
    jne nend
    inc %rax
    jmp cmpstart
    nend:
    movb (%rsi, %rax), %dl
    test %dl, %dl
    je yend
    mov $0, %rax
    ret
    yend:
    mov $1, %rax
    ret
convert2: //string in rdi, length in rsi, converts a string to a floating point, output in xmm0
    xor %r9, %r9//okay so r9 counts where the decimal point is, only increment it when necessary
    xor %rdx, %rdx
    xor %rcx, %rcx
    xor %rax, %rax
    cmpb $0x2d,(%rdi)
    jne cvt2i
    inc %rdx
    cvt2i:
    imul $10, %rax
    movb (%rdi,%rdx), %cl
    test %r9, %r9
    jnz alreadydecimal
    cmpb $0x2E,%cl
    jne nodecimal
    push %rdx
    xor %rdx, %rdx
    mov $10, %r10
    idiv %r10
    pop %rdx
    inc %r9
    jmp yesdecimal
    alreadydecimal:
    inc %r9
    nodecimal:
    subb $0x30, %cl
    add %rcx, %rax
    yesdecimal:
    inc %rdx
    cmp %rdx, %rsi
    jne cvt2i
    cmpb $0x2d, (%rdi)
    jne afterneg
    neg %rax
    afterneg:
    cmp $1, %r9
    jle nodecimal2
    dec %r9
    cvtsi2sd %r9, %xmm1
    vmovsd double10(%rip), %xmm0
    call exponent
    breakpoint:
    cvtsi2sd %rax, %xmm1
    vdivsd %xmm0, %xmm1, %xmm0
    ret
    nodecimal2:
    cvtsi2sd %rax, %xmm0
    ret
convertargs://number of args is in %rdi, converts all the args to ints, rather than pointers
    dec %rdi
    cmp $0, %rdi
    jl convertaend
    lea args(%rip), %r8
    lea lens(%rip), %r9
    push %rdi
    mov (%r9,%rdi,8),%rsi
    shl $3, %rdi
    add %r8, %rdi
    mov (%rdi), %rdi
    push %r8
    call convert2
    pop %r8
    pop %rdi
    vmovsd %xmm0, (%r8,%rdi,8)
    jmp convertargs
    convertaend:
    ret
getargs: //input in %rdi, count in %rsi, output is in args
    xor %rax, %rax
    dec %rsi
    cmp $0, %rsi
    jl getend
    argstart:
    movb (%rdi, %rax), %cl
    or $0x20, %cl
    cmpb $0x20,%cl 
    je argend
    inc %rax
    jmp argstart
    argend:
    lea args(%rip),%r8
    mov %rdi, (%r8,%rsi,8)
    lea lens(%rip),%r8
    mov %rax, (%r8,%rsi,8)
    inc %rax
    add %rax, %rdi
    jmp getargs
    getend:
    ret
