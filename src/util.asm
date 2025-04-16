# códigos de saída
.eqv EXIT_SUCCESS 0
.eqv EXIT_FAILURE 1

# booleanos
.eqv FALSE 0
.eqv TRUE  1

# cria stack frame
.macro sf_start
addi sp, sp, -16 # aloca 16 bytes na stack (alinhamento padrão)
sw ra, 12(sp) # guarda o endereço de retorno na stack
.end_macro

# destrói stack frame
.macro sf_end
lw ra, 12(sp) # obtém o endereço de retorno da stack
addi sp, sp, 16 # limpa a stack
jr ra # retorna
.end_macro

# prepara registros pra strncpy
.macro strncpy_setup(%src, %n)
mv a2, %n
addi t6, a2, 1 #espaço pra string e o null
sbrk(a1, t6)
mv a0, %src
.end_macro

# chamadas do ambiente (sufixo i indica argumento imediato)
.macro print_string(%str)
mv a0, %str
li a7, 4
ecall
.end_macro

.macro print_string_i(%str)
.data
str: .string %str
.text
la a0, str
li a7, 4
ecall
.end_macro

.macro read_string_i (%dst, %max)
mv a0, %dst
li a1, %max
li a7, 8
ecall
.end_macro

.macro sbrk(%dst, %bytes_r)
mv a0, %bytes_r
li a7, 9
ecall
mv %dst, a0
.end_macro

.macro sbrk_i(%dst, %bytes)
li a0, %bytes
li a7, 9
ecall
mv %dst, a0
.end_macro

.macro print_int (%n)
mv a0, %n
li a7, 1
ecall
.end_macro

.macro exit_i (%status)
li a0, %status
li a7, 93
ecall
.end_macro
