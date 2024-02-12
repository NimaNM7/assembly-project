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
nminus_one: dq 0 ; nminus_one = n - 1
nminus_two: dq 0 ; nminus_two = n - 2
matrix1 : DD 1000100 DUP(0.0) ; picture
matrix2 : DD 100 DUP(0.0) ; convolution matrix
matrix3 : DD 1000100 DUP(0.0) ; matrix3 is the result of mul

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
    dec rax
    mov [nminus_one], rax
    dec rax
    mov [nminus_two], rax
    add rax, 2
    mul rax ; calculate n*n
    mov rbx, rax ; mov n*n in bx to act like our counter
    mov rbp, 0 

    matrix1_input_loop: ; store matrix1 loop
        call read_float ; read float number
        mov matrix1[rbp*4], rax ; store input float number in matrix1[rbp] (*4 is because of bytes)
        inc rbp ; increament our counter
        cmp rbp, rbx ; compare our counter with size of matrix
        jl matrix1_input_loop ; if it is less, redo the loop

    mov rbp, 0
    mov rbx, 9
    matrix2_input_loop: ; do the same percedure for matrix2 which has 9 elements
        call read_float
        mov matrix2[rbp*4], rax
        inc rbp
        cmp rbp, rbx
        jl matrix2_input_loop

    jmp image_process
    image_process_end:
        mov r12,0 

    jmp print_result_image
    print_result_image_end:
        mov r12, 0

    add rsp, 8

	pop r15
	pop r14
	pop r13
	pop r12
    pop rbx
    pop rbp

	ret

image_process:
    mov r15, 0
    mov r12, 1 ; counter1(i)
    image_process_loop1:
        mov r13, 1 ; counter2(j)
        image_process_loop2:
            ; call our subroutine
            call calculate_convolution
            ; reach element [r12-1][r13-1] from final image to put the answer of convolution of matrix with
            ; element [r12][r13] as center with processing image
            mov rbx, r12
            dec rbx
            imul rbx, [nminus_two]
            add rbx, r13
            dec rbx
            mov matrix3[rbx*4], rbp

            inc r13 ; increament counter
            cmp r13, [nminus_one] ; compare with n-1
            jl image_process_loop2 ; if less do it again
        inc r12 ; increament counter
        cmp r12, [nminus_one] ; compare
        jl image_process_loop1 ; if less do it again
    
    jmp image_process_end ; come back to the main process

calculate_convolution:
    mov ebp, 0 ; this is the output of the subroutine
    movd xmm2, ebp 
    mov r14, 0
    convolution_loop:
        ; access matrix1[r12+r14-1][r13-1] which is the first element of each row of 3x3 matrix and put it in xmm0
        mov rbx, r12
        add rbx, r14
        dec rbx
        imul rbx, [n]
        add rbx, r13
        dec rbx
        movups xmm0, matrix1[rbx*4]
        
        ; access matrix2[r14][0], the first elements of each row of image processor matrix and put it in xmm1
        mov rbx, r14
        imul rbx, 3
        movups xmm1, matrix2[rbx*4]

        ; xmm0[0] = xmm0[0] * xmm1[0] + xmm0[1] * xmm1[1] + xmm0[2] * xmm1[2]
        dpps xmm0, xmm1, 0x71

        ; add every row result to the main answer
        addss xmm2, xmm0
        
        ; increament counter and do other loop-related stuff
        inc r14 
        cmp r14, 2
        jle convolution_loop

    ; mov xmm2 to our main output
    movd ebp, xmm2
    ret
                    
print_result_image:
    mov rbp, [n] ; move size of matrix to rbp
    sub rbp, 2
    mov r12, 0 ; counter 1
    parallel_print_loop1:
        mov r13, 0 ; counter 2
        parallel_print_loop2:
            ; process to access element[r12][r13] of matrix3
            mov r14, r12 
            imul r14, rbp
            add r14, r13
            mov rdi, matrix3[r14*4] ; print matrix3[r12][r13]
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

    jmp print_result_image_end ; go to end of print result image