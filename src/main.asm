.include "util.asm" # macros e definições

.eqv MAX_LINE_LEN 128 # número máximo de caracteres por entrada

.text
j main

# args: a0 = valor a ser empilhado
# cria nó da lista/pilha encadeada e coloca o ponteiro da cabeça em s9
cria_node:
	sf_start

	mv t0, a0     # move para t0 o valor a empilhar
	sbrk_i(t1, 8) # t1 - aloca um novo node

	sw t0, 0(t1) # guarda o conteúdo no novo nó criado
	sw s9, 4(t1) # ponteiro do nó aponta para o anterior

	mv s9, t1 # atualiza o ponteiro da cabeça

	sf_end

# args: a0 = src, a1 = dst, a2 = n
# move n bytes da string src para a string dst
strncpy:
	sf_start

	# inicializando auxiliares
	mv t0, a0 # t0 = src
	mv t1, a1 # t1 = dst
	mv t2, a2 # t2 = n

	_strncpy_loop: # inicio do loop
	lb t3, 0(t0) # t3 - guarda o conteúdo para transferir para nova string
	sb t3, 0(t1)

	addi t0, t0, 1  # itera pela string original
	addi t1, t1, 1  # itera pela string nova
	addi t2, t2, -1 # decrementa contador

	bne t2, zero, _strncpy_loop # se o contador chegou a zero quebra o loop

	sb zero, 0(t1) # guardando NULL no fim da string

	sf_end

# args: a0 = str
# retorno: inteiro representado pela string str em base 10
atoi:
	sf_start

	# inicializa auxiliares
	mv t0, a0         # t0 recebe a string
	addi t1, zero, 0  # t1 guarda o resultado em inteiro
	addi t2, zero, 10 # t2 fator de multiplicação
	li t4, '\n'

	_atoi_for: # inicio do loop
	lb t3, 0(t0) # carrega o caracter atual de t0 em t3

	beq t3, t4, _atoi_pronto
	beq t3, zero, _atoi_pronto # se chegou no fim da string acaba o loop

	# multiplica o resultado que estava antes para novas casas nao afetarem
	mul t1, t1, t2
	add t1, t1, t3  # adiciona o caracter ao registrador
	addi t1, t1, -48 # corrige de acordo com a tabela ascii
	addi t0, t0, 1   # itera pela string

	j _atoi_for

	_atoi_pronto:
	mv a0, t1 # move resultado para reg de saida

	sf_end

# args: a0 = str, a1 = strlen(str)
# retorno: nova string com espaços removidos
strstrip:
	sf_start
	sw s0, 8(sp) # guarda o registrador s0 na stack

	mv t0, a0 # t0 = str
	addi t2, a1, 1 # t2 = strlen(str)+1
	sbrk(t1, t2) # aloca memória para string resultado
	mv s0, t1

	_strstrip_loop:
	lb t2, (t0)
	addi t0, t0, 1

	# if (c==' ' || c=='\n') continue;
	li t3, ' '
	li t4, '\n'
	beq t2, t3, _strstrip_loop
	beq t2, t4, _strstrip_loop

	# if (!c) break;
	li t3, 0
	beq t2, t3, _strstrip_end

	sb t2, (t1) # guarda caractere no buffer

	addi t1, t1, 1
	j _strstrip_loop

	_strstrip_end:
	li t2, 0
	sb t2, (t1)

	mv a0, s0 # return s0

	lw s0, 8(sp) # obtém o registrador s0 da stack
	sf_end

# args: a0 = str, a1 = strlen(str), a2 = primeira chamada? (FALSE or TRUE)
# lê uma entrada na forma NON, ON ou O, onde N é um operando e O
# é um operador.
# coloca o operando 1 em a0 (ou -1 se não houver), o operador em a1 e o
# operando 2 em a2 (ou -1 se não houver);
parse_input:
	sf_start
	sw s0, 8(sp)

	# strstrip(a0, a1)
	jal ra, strstrip
	# s0 tem o endereço da nossa string agora
	mv s0, a0

	# vendo se o usuário apenas digitou 'enter'
	li t0, 0
	lb t1, 0(s0)
	beq t1, t0, main_loop

	# vendo se primeiro byte é número
	lb a0, 0(s0)
	jal ra, eh_digito
	# se for operador, ir para not_digit
	beqz a0, _not_digit

	li s7, 1 # flag -> primeiro operando existe

	# ler primeiro operando
	mv s4, s0 # s4 = (char *) str_temp
	li s5, 0 # s5 = count

	_read_first_loop:
	beq a1, s5, _parse_err # chegou ao fim da string sem operador

	lb s6, (s4) # lê caractere
	mv a0, s6
	jal ra, eh_digito # verifica se é digito

	# se chegou num operador, converte o primeiro operando pra int
	beqz a0, _convert_first

	addi s4, s4, 1
	addi s5, s5, 1
	j _read_first_loop

	_convert_first:
	mv s2, s6 # s2 = operador
	strncpy_setup(s0, s5) # copia o primeiro operando pra um buffer
	jal ra, strncpy
	mv a0, a1
	jal ra, atoi
	mv s1, a0 # s1 = operando 1
	addi s0, s4, 1 # a0 = str_temp+1

	# ler segundo operando
	_read_second:
	mv s4, s0 # s4 = (char *) str_temp
	li s5, 0

	# não há segundo operando
	lb s6, (s4)
	beqz s6, _parse_err

	_read_second_loop:
	lb s6, (s4)
	beqz s6, _convert_second # chegou ao fim da string
	mv a0, s6
	jal ra, eh_digito
	beqz a0, _parse_err # encontrou outro operador
	addi s4, s4, 1
	addi s5, s5, 1
	j _read_second_loop

	_convert_second:
	strncpy_setup(s0, s5) # copia o segundo operando para um buffer
	jal ra, strncpy
	mv a0, a1
	jal ra, atoi # converte para int
	mv s3, a0 # s3 = operando 2
	beqz s7, _finish_ON
	j _finish_NON

	# não há primeiro operando
	_not_digit:
	li s7, 0 # flag -> primeiro operando não existe
	lb s2, 0(s0) # s2 = operador
	lb t0, 1(s0) # se prox caractere é 0, termina em 0O0
	beqz t0, _finish_O
	addi s0, s0, 1
	j _read_second

	# termina o programa para parsing de NON
	_finish_NON:
	mv a0, s1
	mv a1, s2
	mv a2, s3
	j _parse_input_ret

	# termina o programa para parsing de ON
	_finish_ON:
	li a0, -1
	mv a1, s2
	mv a2, s3
	j _parse_input_ret

	# termina o programa para parsing de O
	_finish_O:
	li a0, -1
	mv a1, s2
	li a2, -1
	j _parse_input_ret

	_parse_err:
	print_string_i("Erro: formatação inválida.")
	exit_i (EXIT_FAILURE)

	_parse_input_ret:
	lw s0, 8(sp)
	sf_end

# args: a0 = ch
# retorno: TRUE se ch é um operator (se está em "+-*/uf") e FALSE se não
eh_operador:
	sf_start

.data
	ops: .string "+-*/uf"
.text

	la t0, ops
	_eh_operador_loop:
	lb t1, (t0)
	beqz t1 _eh_operador_false
	beq a0, t1, _eh_operador_true
	addi t0, t0, 1
	j _eh_operador_loop

	_eh_operador_true:
	li a0, TRUE
	j _eh_operador_ret

	_eh_operador_false:
	li a0, FALSE
	j _eh_operador_ret

	_eh_operador_ret:
	sf_end

# args: a0 = ch
# retorno: TRUE se ch é um dígito numérico válido e FALSE se não
eh_digito:
	sf_start

	li t0, '0'
	li t1, '9'
	bge a0, t0, _greater_zero

	_eh_digito_false:
	li a0, FALSE
	j _eh_digito_ret

	_greater_zero:
	ble a0, t1, _eh_digito_true
	j _eh_digito_false

	_eh_digito_true:
	li a0, TRUE
	j _eh_digito_ret

	_eh_digito_ret:
	sf_end

# calcula expressão
# Entrada: a0 = operando1, a1 = operador, a2 = operando2, a3 = NON flag
# Saída: a0 (Resultado caso +-*/, operando1 caso u/f)
calcula:
	sf_start
	sw s0, 8(sp)

	mv t6, a0 # salva temporariamente

	# Switch case das operações
	li t0, '+'
	beq a1, t0, _calcula_soma
	li t0, '-'
	beq a1, t0, _calcula_sub
	li t0, '*'
	beq a1, t0, _calcula_mul
	li t0, '/'
	beq a1, t0, _calcula_div
	li t0, 'u'
	beq a1, t0, _calcula_undo
	li t0, 'f'
	beq a1, t0, _calcula_fim
	j _operador_err

	# t0 armazenará o resultado de a0 (op) a2
	_calcula_soma:
	li t5, -1
	beq a0, t5, _faltando_operando_err
	beq a2, t5, _faltando_operando_err
	add t0, a0, a2
	jal, _calcula_resultado
	_calcula_sub:
	li t5, -1
	beq a0, t5, _faltando_operando_err
	beq a2, t5, _faltando_operando_err
	sub t0, a0, a2
	jal, _calcula_resultado
	_calcula_mul:
	li t5, -1
	beq a0, t5, _faltando_operando_err
	beq a2, t5, _faltando_operando_err
	mul t0, a0, a2
	jal, _calcula_resultado
	_calcula_div:
	li t5, -1
	beq a0, t5, _faltando_operando_err
	beq a2, t5, _faltando_operando_err
	beqz a2, _div_err # Erro se divisão por zero
	div t0, a0, a2
	jal, _calcula_resultado
	_calcula_resultado: # As operações que retornam um número vão aqui
	mv s0, t0
	beqz a3, _not_NON
	mv a0, t6 # empilha o operando 1
	jal ra cria_node

	_not_NON:
	mv a0, s0 	 # Retorna o resultado t0
	jal ra cria_node # Empilha o resultado
	j _calcula_ret

	_calcula_undo:
	# Checa se a2 é -1:
	li t0, -1
	bne a2, t0, _uf_err

	# checando se é o fim da pilha
	#lw t0, 4(s9) # no fim da pilha, guarda ptr = 0
	beqz s9, _pilha_vazia_err
	lw s9, 4(s9) # desempilha

	beqz s9, _pilha_vazia_err
	lw s0, 0(s9) # carrega resultado
	j _calcula_ret

	_calcula_fim:
	# checando erro de 'f' não aceitar parâmetros
	li t0, -1
	bne a2, t0, _uf_err

	# saindo do programa
	print_string_i("Te amamos Sarita!") # :)
	exit_i(EXIT_SUCCESS)

	_calcula_ret:
	mv a0, s0

	# stack frame end
	lw s0, 8(sp)
	sf_end

	_operador_err:
	print_string_i("Erro: operador inválido.")
	exit_i(EXIT_FAILURE)

	_faltando_operando_err:
	print_string_i("Erro: operando(s) faltando.")
	exit_i(EXIT_FAILURE)

	_div_err:
	print_string_i("Erro: divisão por zero.")
	exit_i(EXIT_FAILURE)

	_uf_err:
	print_string_i("Erro: operador u e f não aceitam números.")
	exit_i(EXIT_FAILURE)

	_pilha_vazia_err:
	print_string_i("Erro: tentativa de 'undo' sem operação anterior.")
	exit_i(EXIT_FAILURE)

main:
	sbrk_i (s0, MAX_LINE_LEN) # aloca memória para a entrada
	li a2, TRUE # flag de primeira chamada

	# loop principal da calculadora
	main_loop:
	read_string_i(s0, MAX_LINE_LEN) # lê expressão da entrada

	#parse_input(s0, MAX_LINE_LEN, TRUE)
	mv a0, s0
	li a1, MAX_LINE_LEN
	jal ra, parse_input

	beqz a0, _eh_NON

	# desempilha
	beqz s9, _eh_NON
	lw a0, 0(s9)
	li a3, 0
	j _calc

	_eh_NON: # entrada é do tipo NON
	li a3, 1
	_calc:
	jal ra, calcula
	print_int(a0)
	print_string_i("\n")

	li a2, FALSE # tira flag de primeira chamada
	j main_loop
