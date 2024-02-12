; Assembly 8086 project
; Nima Moazzen
; 401106599

%include "asm_io.inc"

%macro before_align 0
    push rbp
    mov rbp, rsp
    mov rax, rsp
    and rax, 15
    sub rsp, rax
%endmacro

%macro after_align 0
    mov rsp, rbp
    pop rbp
%endmacro

segment .data
n: dq 0 ; our matrices are n*n 
n2 : dq 0 ; n2 = n*n
matrix1 : DD 1000100 DUP(0.0) 
matrix2 : DD 1000100 DUP(0.0)
matrix2_transpose: dd 1000100 DUP(0.0) ; transpose of matrix2 (useful for parallel mul)
matrix3 : DD 1000100 DUP(0.0) ; matrix3 is the result of mul
vector1: dd 10 DUP(0.0) ; two vectors in case of need
vector2: dd 10 DUP(0.0) 
matrix4: dd 1000100 DUP(0.0) ; matrix4 is the result of parallel mul
convolution_matrix : dd 1000000 DUP(0.0)
normal_start_time: dq 0 ; normal start and end time
normal_end_time: dq 0
parallel_start_time: dq 0 ; parallel start and end time
parallel_end_time: dq 0
convolution_result: dq 0 ; result of normal convolution
parallel_convolution_result: dq 0 ; result of parallel convolution 
normal_conv_start_time: dq 0 ; convolution normal and parallel start and end time
normal_conv_end_time: dq 0
parallel_conv_start_time: dq 0
parallel_conv_end_time: dq 0

segment .text

global asm_main

asm_main:
	push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    sub rsp, 8

    call read_int ; read n
    mov [n], rax
    mul rax ; calculate n*n
    mov [n2], rax ; store n*n in n2
    mov rbx, rax ; mov n*n in bx to act like our counter
    mov rbp, 0 

    matrix1_input_loop: ; store matrix1 loop
        call read_float ; read float number
        mov matrix1[rbp*4], rax ; store input float number in matrix1[rbp] (*4 is because of bytes)
        inc rbp ; increament our counter
        cmp rbp, rbx ; compare our counter with size of matrix
        jl matrix1_input_loop ; if it is less, redo the loop


    mov rbp, 0
    matrix2_input_loop: ; do the same percedure for matrix2
        call read_float
        mov matrix2[rbp*4], rax
        inc rbp
        cmp rbp, rbx
        jl matrix2_input_loop

    jmp get_matrix2_transpose ; we go to calculate transpose of matrix2
    matrix2_transpose_end: ; we come back from calculating transpose of matrix2
        mov r12, 0

    jmp muloop ; we go to calculate matrix1 * matrix 2 using the oldschool way
    muloop_end: ; back from calculating
    ;     mov r12, 0

    jmp matrix_parallel_mul ; we go to calculate matrix1 * matrix 2 using the parallel way
    parallel_end: ; back from calculating
        mov r12,0

    mov eax, [normal_end_time] ; normal end time to eax
    mov ebx, [normal_start_time] ; normal start time to 
    sub eax, ebx ; calculate end - start
    mov edi, eax ; print delta time
    call print_int

    mov rdi, 10
    call print_char

    mov eax, [parallel_end_time] ; parallel end time to eax
    mov ebx, [parallel_start_time] ; parallel start time to eax
    sub eax, ebx ; calculate end - start
    mov edi, eax ; print delta time
    call print_int
    
    mov rdi, 10
    call print_char
    mov rdi, 10
    call print_char

    jmp convolution ; go to calculate convolution
    convolution_end: ; back from calculating
        mov r15, 0
    
    jmp parallel_convolution ; go to parallel convolution calculation
    parallel_convolution_end: ; back from calculation
        mov r15,0
    
    mov rdi, 10
    call print_char
    mov eax, [normal_conv_end_time] ; normal end time to eax
    mov ebx, [normal_conv_start_time] ; normal start time to 
    sub eax, ebx ; calculate end - start
    mov edi, eax ; print delta time
    call print_int

    mov rdi, 10
    call print_char

    mov eax, [parallel_conv_end_time] ; parallel end time to eax
    mov ebx, [parallel_conv_start_time] ; parallel start time to eax
    sub eax, ebx ; calculate end - start
    mov edi, eax ; print delta time
    call print_int
    
    mov rdi, 10
    call print_char
    mov rdi, 10
    call print_char


    add rsp, 8

	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp

	ret

get_matrix2_transpose: ; calculating transpose of matrix 2
    mov rbp, [n] ; put the size in register
    mov r12, 0 ; counter 1
    transpose_loop1:
        mov r13, 0 ; counter 2
        transpose_loop2: 
            mov r15, r13 ; the process of reaching element[r13][r12]
            imul r15, rbp
            add r15, r12
            mov rbx, matrix2[r15*4] ; this is [r13][r12]

            mov r14, r12 ; the process of reaching element[r12][r13]
            imul r14, rbp
            add r14, r13
            mov matrix2_transpose[r14*4], rbx ; we put matrix2[r13][r12] in matrix2_transpose[r12][r13]

            inc r13 ; increament second counter
            cmp r13, rbp ; compare second counter
            jl transpose_loop2 ; if less, redo
        
        inc r12 ; increament first counter
        cmp r12, rbp ; comapre first counter
        jl transpose_loop1 ; if less, redo
    
    jmp matrix2_transpose_end ; back to the main part

muloop:
    rdtsc
    mov [normal_start_time], eax   ; we record the start time of normal mul

    mov ebp, 0
    movd xmm3, ebp
    mov rbp , [n]
    mov r14, 0       ; first counter
    mul_loop1:
        mov r12, 0    ; second counter
        mul_loop2:
            mov ebx, 0  ; this will be matrix3[r14][r12]
            movd xmm0 , ebx ; put in xmm0 
            mov r13, 0     ; third counter
            mul_loop3:
                ; getting matrix1[r14][r13]
                mov rcx, r14
                imul rcx, rbp
                add rcx, r13
                mov eax, matrix1[rcx*4]

                ; getting matrix2[r13][r12]
                mov rcx, r13
                imul rcx, rbp
                add rcx, r12
                mov ebx, matrix2[rcx*4]

                movd xmm1, eax  ; calculating sum of eax and ebx using xmm0 and xmm1
                movd xmm2, ebx
                mulss xmm1, xmm2
                addss xmm0, xmm1 

                inc r13 ; increament third counter 
                cmp r13, rbp ; compare third counter
                jle mul_loop3 ; if less we continue to add to get matrix3[r14][r12]
            
            ; process to reach matrix3[r14][r12]
            mov rcx, r14 
            imul rcx, rbp
            add rcx, r12

            ; matrix3[r14][r12] is sum of matrix1[r14][i] * matrix[j][r12] for i in range (0 , n)
            movd ebx, xmm0
            mov matrix3[rcx*4], ebx

            inc r12 ; increament r12
            cmp r12, rbp ; compare r12
            jle mul_loop2 ; if greater, we go to the next element
        
        inc r14 ; increament r14
        cmp r14, rbp ; compare r14
        jle mul_loop1 ; if greater, we go to next row

        rdtsc
        mov [normal_end_time], eax ; record end time of normal mul

    jmp print_result_matrix ; go for printing matrix3

print_result_matrix: ; process of printing matrix3
    mov rbp, [n] ; put size of matrix2 in rbp 
    mov r12, 0 ; counter 1
    print_loop1 :
        mov r13, 0 ; counter 2
        print_loop2:
            ; process to reach matrix3[r12][r13]
            mov r14, r12 
            imul r14, rbp
            add r14, r13
            mov rdi, matrix3[r14*4] ; reach matrix3[r12][r13] then print it
            call print_float
            mov rdi, 32
            call print_char
            inc r13 ; increament r13
            cmp r13, rbp ; compare
            jl print_loop2 ; if greater or equal go to next element
        mov rdi, 10 ; print enter
        call print_char
        inc r12 ; increament r12
        cmp r12, rbp ; compare 
        jl print_loop1 ; if greater or equal, finish it

    mov rdi, 10
    call print_char
    jmp muloop_end ; go to the main 

matrix_parallel_mul:
    rdtsc
    mov [parallel_start_time], eax ; record start time of parallel mul

    mov rbp, [n] ; put size in rbp
    mov r12, 0 ; counter 1
    paralleloop1:
        mov r13, 0 ; counter 2
        paralleloop2:
            mov r14, 0 ; counter 3
            mov rbp, 0 ; sum , it will be matrix4[r12][r13]
            paralleloop3:
                ; try to reach element[r12][r14] of matrix1
                mov rcx, r12 
                imul rcx, [n]
                add rcx, r14
                movups xmm0, matrix1[rcx*4] ; put matrix1[r12][r14] to xmm0
                mov rcx, r13 ; try to reach element[r14][r13] of matrix2
                imul rcx, [n]
                add rcx, r14
                movups xmm1, matrix2_transpose[rcx*4] ; put matrix2_transpose[r14][r13]

                call vector_mul ; call method vector_mul

                
                movd xmm2, ebx ; mov ebx (the result of dot) in xmm2
                movd xmm3, ebp ; mov the sum until now in xmm3
                addss xmm2, xmm3 ; add xmm2 and xmm3 (this is sum until now)
                movd ebp, xmm2  ; put xmm2 in ebp which is our sum

                mov rcx, r12 ; try to reach element [r12][r13] of matrix4
                imul rcx, [n]
                add rcx, r13
                mov matrix4[rcx*4], rbp ; put sum of elements in matrix4[r12][r13]

                add r14, 4 ; add 4 to r14, if n is more than 4 we get 4 more elements
                cmp r14, [n] ; compare r14 to n
                jl paralleloop3 ; if r14 is less than n we do it again
            
            inc r13 ; increament r13
            cmp r13, [n] ; compare r13
            jl paralleloop2 ; if it is less we do it again

        inc r12 ; increament r12
        cmp r12, [n] ; compare r12 to n
        jl paralleloop1 ; if greater or equal we are done

        rdtsc
        mov [parallel_end_time], eax ; record time of end of parallel mul

    jmp print_parallel_result_matrix ; then we print parallel

vector_mul:  ; a subroutine which calculates mul of 2 vectors (if we dont need an element make it zero)
    movups [vector1], xmm0 ; put xmm0 to vector1
    movups [vector2], xmm1 ; put xmm1 to vector2 (for ease of working with elements of it)
    mov r15, [n] ; put size of matrix to r15
    sub r15, r14 ; r15 - r14
    cmp r15, 4 ; if r15 is less than 4 it means that we dont need an element and we should make it zero
    jge dot 
    
    before_dot:
        mov rcx,0 ; if we dont need an element we make it zero
        mov vector1[r15*4], rcx ; make zero in vector1
        mov vector2[r15*4], rcx ; make zero in vector2
        inc r15 ; increament r15, because we want elements with index more than r15 to be zero
        cmp r15, 3 ; compare 
        jle before_dot ; if makeing zero is done, we go to dot level

    dot:
        movups xmm0, [vector1] ; mov vector1 to xmm0 for ease and speed of mul
        movups xmm1, [vector2] ; mov vector2 to xmm1 for ease and speed of mul
        dpps xmm0, xmm1, 0xF1 ; mul xmm0 and xmm1 and put the sum of elements to xmm0 to the first element of xmm0
        movd ebx, xmm0 ; mov the first element of xmm0 to ebx, this is result of dot 
    ret 

print_parallel_result_matrix: ; print parallel result matrix
    mov rbp, [n] ; move size of matrix to rbp
    mov r12, 0 ; counter 1
    parallel_print_loop1:
        mov r13, 0 ; counter 2
        parallel_print_loop2:
            ; process to access element[r12][r13] of matrix4
            mov r14, r12 
            imul r14, rbp
            add r14, r13
            mov rdi, matrix4[r14*4] ; print matrix4[r12][r13]
            call print_float
            mov rdi, 32
            call print_char
            inc r13 ; increament r13
            cmp r13, rbp ; compare r13 with rbp
            jl parallel_print_loop2 ; if greater, go to next line
        mov rdi, 10 ; print enter 
        call print_char
        inc r12 ; increament r12
        cmp r12, rbp ; compare r12 with rbp
        jl parallel_print_loop1 ; if greater or equal stop it

    mov rdi, 10
    call print_char
    jmp parallel_end ; go to parallel_end


convolution: ; calculating covolution in oldschool way
    rdtsc 
    mov [normal_conv_start_time], eax ; record start time
    mov r15, [n2] ; n*n to r15
    mov r12, 0 ; r12 = 0
    mov ebx, 0 ; ebx = 0
    movd xmm0, ebx ; mov ebx to xmm0 , this is the result

    conv_loop:
        mov eax, matrix1[r12*4] ; get matrix1[r12]
        mov ebx, matrix2[r12*4] ; get matrix2[r12]
        movd xmm1, eax ; mull eax and ebx when they are put in xmm1 and xmm2
        movd xmm2, ebx
        mulss xmm1, xmm2
        addss xmm0, xmm1 ; add xmm0 to xmm1 which is result of mul

        inc r12 ; increament r12 so we can add other elements too
        cmp r12, r15 ; compare r12 to n*n
        jl conv_loop ; if less than n*n do it again
    
    movd ebx, xmm0 ; copy xmm0 to ebx
    mov [convolution_result], rbx ; copy amount of rbx (the sum of muls) to memory
    mov rdi, rbx ; print result
    call print_float
    mov rdi, 10
    call print_char
    rdtsc
    mov [normal_conv_end_time], eax ; record end time

    jmp convolution_end ; go to the main process

parallel_convolution: ; caculating average in parallel way
    rdtsc
    mov [parallel_conv_start_time], eax ; record start time
    mov r12, 0 ; counter
    mov rbp, 0 ; result
    parallel_conv_loop:
        movups xmm0, matrix1[r12*4] ; get 4 elements and put it in xmm0
        movups xmm2, matrix1[r12*4]
        movups xmm1, matrix2[r12*4] ; get 4 elements and put it in xmm1
        mulps xmm2, xmm1
        movups [vector1], xmm2
        mov r14, 0
        
        dpps xmm0, xmm1, 0xF1 ; mul 2 vectors and put the sum of its elements in its first element
        movd ebx, xmm0 
        movd xmm2, ebp ; mov our current result to xmm2 for sum
        addss xmm2, xmm0 ; add xmm2 and xmm0
        movd ebp, xmm2 ; put xmm2(new result) to ebp
        add r12, 4 ; increament r12 4 times to get 4 new elements
        cmp r12, [n2] ; compare to n*n
        jl parallel_conv_loop ; if less do it again
 
    mov [parallel_convolution_result], rbp ; store result to memory
    mov rdi, rbp ; print result
    call print_float
    mov rdi, 10
    call print_char
    rdtsc
    mov [parallel_conv_end_time], eax ; record end time

    jmp parallel_convolution_end
