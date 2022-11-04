;====================================================================
; Main.asm file generated by New Project wizard
; =====================================
; exemplo programa com interrupcao TC1 - timer 1 ,
; contagem de tempo em timer 1 e multiplexacao em Timer 0
; comparacao de registradores 
; MODO Normal (estouro ou overflow)
; interrupcao do TC1, toda vez que TCNT1 alcanca seu valor maximo 65535
; Prof. Marcos Chaves

;====================================================================
;DEFINI��ES DA PORTAS E FLAGS
;===============================================================================
;FLAG 

; r0 utilizado em decodifica display
.def unidades = r1
.def  dezenas =r2
.def centenas = r3
.def segundos = r4
.def minutos = r5
.def horas=r6
.def numero_digito_exibir=r7
.def aux =	r16		
.def numberL = R20
.def numberH = R22

.def eeprom_address = r23
.def display_number = r24		
.def delay_time = r25		


.EQU DIG0  = 0X03D4            ;DIGITO 0
.EQU DIG1  = 0X03D3            ;DIGITO 1
.EQU DIG2  = 0X03D2            ;DIGITO 2
.EQU DIG3  = 0X03D1            ;DIGITO 2
.EQU DIG4  = 0X03D0            ;DIGITO 2

.equ DISPLAY  = PORTD	//PORTD � onde est� conectado o Display (seg a = LSB)

;====================================================================
; VARIABLES
;====================================================================
;.equ	TCNT1L	= 0x84	; MEMORY MAPPED
;.equ	TCNT1H	= 0x85	; MEMORY MAPPED
;====================================================================
; RESET and INTERRUPT VECTORS
;====================================================================
.org 0x0000
      ; Reset Vector
      rjmp  Start
.org 0x0020  ; overflow de tcnt0 valor top
     rjmp TIM0_OV    
.ORG 0x001A 
     rjmp TIM1_OVERFLOW ; Interrupcao por estouro de timer 1 (modo normal)

.org 0x050		
;====================================================================
; CODE SEGMENT
;====================================================================
;  .include "lib328Pv03.inc"
Start:
      ; Write your code here
	LDI  AUX,0xFF	    
	OUT  DDRB,AUX  	//habilita o pull-up do PB0 (demais pinos em 1)
	OUT  DDRD, AUX    	//PORTD como sa�da
	OUT  DDRC,AUX   	//desliga o display

; 

;          CONFIGURA TIMER 0 PARA MULTIPLEXAR DISPLAY A CADA 16ms


;

  ldi r16,0b00000000  ;  ativa pinos 0C0A E 0C0B com mudan�a na igualdade, operacao TC0 modo NORMAL
	out TCCR0A,r16
	
	/* TCCR0A  Registrador de controle A do TC0  
	COM0A1 COM0A0 COM0B1 COM0B0  -     -     WGM01 WGM00
	 7        6     5      4     3     2       1     0

	 COM0A1 COM0A0 controlam o comportamento do pino 0C0A pino D6 (modos normal, CTC, pwm rapido)
	   0      0  - pino 0C0A desconectado
	   0      1  - mudanca de estado na igualdade (modo normal)
	   1      0  - aterrado na igualdade(modo normal/pwm rapido) =0 crescente e =1 decrescente (pwm fase corrigida)
	   1      1  - Ativo  na igualdade (modo normal/pwm rapido) =1 crescente e =0 decrescente (pwm fase corrigida)

	   COM0B1 COM0B0  controlam o comportamento do pino 0C0B  pino D5
	   0      0  - pino 0C0B desconectado
	   0      1  - mudanca de estado na igualdade (modo normal)
	   1      0  - aterrado na igualdade (modo normal/pwm rapido) =0 crescente e =1 decrescente (pwm fase corrigida)
	   1      1  - Ativo  na igualdade (modo normal/pwm rapido) =1 crescente e =0 decrescente (pwm fase corrigida)

	   WGM02 WGM01 WGM00 bits do modo de controle, fonte do valor maximo e forma de onda
	   0     0     0  - normal     TOP em FF
	   0     0     1  - pwm fase corrigida top em FF
	   0     1     0  - CTC        TOP em 0CR0A
	   0     1     1  - pwm rapido  TOP em FF
	   1     0     0  - 
	   1     0     1  - pwm fase corrigida top em 0CR0A
	   1     1     0   -
	   1     1     1  - pwm rapido TOP em 0CR0A
	*/

	ldi r16,0b00000001  ; se habilitar interrupcao por overflow 
	sts TIMSK0,r16 
	/* TIMSK0 Interruptor de mascara do contador TC0
	- - - - - 0CIE0B 0CIE0A TOIE0
	7 6 5 4 3   2      1      0
	0CIE0B ativa a interrup��o na igualdade de compara��o 0CR0B
	0CIE0A ativa a interrup��o na igualdade de compara��o 0CR0A
	TOIE0  ativa a interrup��o de estouro em TOP=FF

	*/

	ldi r16,0b00000101
	out TCCR0B,r16   ; prescaler 1024
	/* TCCR0B  Registrador de controle B do TC0
	F0C0A  FOC0B   -    -   WGM02  CS02  CS01  CS00
	7        6     5    4     3      2    1      0

	CS02  CS01  CS00  bits de selecao do prescaler
	   0     0     0  - sem fonte de clock tc0 parado
	   0     0     1  - prescaler =1
	   0     1     0  - prescaler = 8
	   0     1     1  - prescaler = 64
	   1     0     0  - prescaler = 256
	   1     0     1  - prescaler = 1024
	   1     1     0  - clock externo pino T0 (pd4) contagem borda descida
	   1     1     1  - clock externo pino T0 (pd4) contagem borda subida     
	*/

;	ldi r16,100
;	out TCNT0,r16   ; valor inicial do TC0  




; 

;              CONFIGURA TIMER 1 PARA INCREMENTAR SEGUNDOS

;
	ldi r16,0b00000000    ; pinos desconectados 
	sts TCCR1A,r16   ; registrador de controle TC1

;   TCCR1A  Registrador de controle do TC1
; +-------+------+------+------+-----+-----+-----+-----+
; + B7    |  B6  | B5   |  B4  | B3  |  B2 |  B1 | B0  |
; + COM1A1|COM1A0|COM1B1|COM1B0| -   | -   |WGM11|WGM10|
; +-------+------+------+------+-----+-----+-----+-----+


;COM1A1/COM1B1 COM1A0/COM1B0 controlam o comportamento do pino 0C1A(PB1)/0C1B(PB2) PB1 (modos normal, CTC, pwm rapido)
;	   0           0  - pino 0C1A desconectado (normal , CTC, pwm rapido e fase corrigida)
;	   0           1  - mudanca de estado na igualdade (normal , CTC e pwm rapido)
;	   1           0  - nivel baixo na igualdade  (normal , CTC e pwm rapido)  nivel baixo na comparacao, contagem crescente(pwm fase corrigida)
;	   1           1  - Ativo  na igualdade (normal , CTC e pwm rapido), nivel alto na comparacao contagem descrescente(pwm fase corrigida)

   
;	    WGM13    WGM12  WGM11  WGM10  bits do modo de controle, fonte do valor maximo e forma de onda
;	     0          0     0     0  - normal     TOP em FFFF
;	     0          0     0     1  - pwm fase corrigida top em FF 8 bits
;	     0  	0     1     0  - pwm fase corrigida top em 1FF 9 bits
;	     0  	0     1     1  - pwm fase corrigida top em 3FF 10 bits
;	     0  	1     0     0  - CTC
;	     0  	1     0     1  - pwm rapido  top em FF 8 bits
;	     0  	1     1     0   -pwm rapido top em 1FF 9 bits
;	     0  	1     1     1  - pwm rapido top em 1FF 9 bits
;	     1      0     0     0  - pwm frequencia e fase corrigidas TOP ICR1
;	     1      0     0     1  - pwm frequencia e fase corrigidas TOP 0CR1A
;	     1  	0     1     0  - pwm fase corrigida TOP ICR1
;	     1  	0     1     1  - pwm fase corrigida TOP 0CR1A
;	     1  	1     0     0  - CTC
;	     1  	1     0     1  - reservado
;	     1  	1     1     0  - PWM rapido top ICR1
;	     1  	1     1     1  - PWM rapido top 0CR1A
;
	ldi r16,0b00000101  ;  
	sts TCCR1B,r16
;   TCCR1B  Registrador de controle do TC1
; +-------+------+------+------+------+-----+-----+-----+
; + B7    |  B6  | B5   |  B4  | B3   |  B2 |  B1 | B0  |
; + ICNC1 |ICES1 |  -   |WGM13 | WGM12| CS12| CS11| CS10|
; +-------+------+------+------+------+-----+-----+-----+

;	  ICNC1  filtro de ruido habilitado
;	  OICES1 =0 borda de descida, =1 borda de subida em modo entrada ICP1

;   CS12  CS11  CS10  bits de selecao do prescaler
;	   0     0     0  - sem fonte de clock tc1 parado
;	   0     0     1  - prescaler =1
;	   0     1     0  - prescaler = 8
;	   0     1     1  - prescaler = 64
;	   1     0     0  - prescaler = 256
;	   1     0     1  - prescaler = 1024
;	   1     1     0  - clock externo pino T1 (pd5) contagem borda descida
;	   1     1     1  - clock externo pino T1 (pd5) contagem borda subida     

;
	ldi r16,0b00000001  ;  habilitar interrupcao
	sts TIMSK1,r16 
	; TIMSK1 Interruptor de mascara do contador TC1
; +-------+------+------+------+------+------+------+-----+
; +   B7  |  B6  |  B5  |  B4  |  B3  |   B2 |   B1 |  B0 |
; +       |      | ICIE1|      |      |OCIE1B|OCIE1A|TOIE1|
; +-------+------+------+------+------+------+------+-----+

;	ICIE1 ativa a interrupcao por captura de entrada pinos ICP1 (pB0) ou comparador analogico
;	0CIE1B ativa a interrupcao TC1 igualdade de comparacao 0CR1B
;	0CIE1A  ativa a interrupcao TC1 igualdade de comparacao 0CR1A
;	TOIE1  ativa interrupcao por estouro de TC1 top
;
 ; valor para tncnt1L e tcnt1H  = 49910 (0xC2F6) para preescaler=1024 e tempo de estouro=1 segundos
 	ldi r16,0xC2  
	sts	TCNT1H,r16
	ldi r16,0xF6 
    sts	TCNT1L,r16


	

    sei ; habilita as interrupcoes no microcontrolador



Loop:
   
 ;   imprimir hora:minutos:segundos
	

	,
   rjmp  Loop ; fim loop 



;==============================================================	
; rotina executada em overflow de tcnt0
TIM0_OV:
     sbi PORTC,0
	 sbi PORTC,1
	 sbi PORTC,2
	 sbi PORTC,3
	 sbi PORTC,4
     inc numero_digito_exibir
	 ldi aux,5
     cp numero_digito_exibir,aux
	 breq exibir_display0

	 ldi aux,1
     cp numero_digito_exibir,aux
	 breq exibir_display1

	 ldi aux,2
     cp numero_digito_exibir,aux
	 breq exibir_display2


	 ldi aux,3
     cp numero_digito_exibir,aux
	 breq exibir_display3

	 ldi aux,4
     cp numero_digito_exibir,aux
	 breq exibir_display4

exibir_display0:
     clr numero_digito_exibir  
	 LDS   aux,DIG0
	 RCALL Decodifica	//chama sub-rotina de decodifica��o	  para display 7 segmentos
	 cbi PORTC,0
	 reti	

exibir_display1:
	 LDS   aux,DIG1
	 RCALL Decodifica	//chama sub-rotina de decodifica��o	  para display 7 segmentos
	 cbi PORTC,1
	 reti	

exibir_display2:
	 LDS   aux,DIG2
	 RCALL Decodifica	//chama sub-rotina de decodifica��o	  para display 7 segmentos
	 cbi PORTC,2
	 reti	

exibir_display3:
	 LDS   aux,DIG3
	 RCALL Decodifica	//chama sub-rotina de decodifica��o	  para display 7 segmentos
	 cbi PORTC,3
	 reti

exibir_display4:
	 LDS   aux,DIG4
	 RCALL Decodifica	//chama sub-rotina de decodifica��o	  para display 7 segmentos
	 cbi PORTC,4
	 reti

;====================================================================
; rotina executada quando timer 16 bits estoura, tempo 1000ms
TIM1_OVERFLOW:
    ; atualiza valor contagem inicial 49910 (0xC2F6)
	ldi r16,0xC2  
	sts	TCNT1H,r16
	ldi r16,0xF6 
    sts	TCNT1L,r16

evento_1seg:   ; eventos a cada 1 segundo
      
         inc segundos	        
         ldi aux,60
         cp segundos,aux
         breq aumenta_minutos
         rjmp separa_numeros

aumenta_minutos:
        inc minutos
		clr segundos
		ldi aux,10
		cp minutos,aux
        breq zera_minutos
        rjmp separa_numeros
zera_minutos:
        clr minutos

separa_numeros:
         mov numberL, segundos
		 rcall write_number_0_999  ; separa segundos em unidade e dezena
		 STS DIG0,unidades
	     STS DIG1,dezenas  ; 
    	 mov numberL, minutos
		 rcall write_number_0_999  ; separa segundos em unidade e dezena
		 STS DIG2,unidades
	     STS DIG3,dezenas  ; 
    	 

		reti
	



//------------------------------------------------------------------------------------
//SUB-ROTINA que decodifica um valor de 0 -> 15 para o display 
//------------------------------------------------------------------------------------
Decodifica:
 
	LDI  ZH,HIGH(Tabela<<1)	//carrega o endere�o da tabela no registrador Z, de 16 bits (trabalha como um ponteiro)
	LDI  ZL,LOW(Tabela<<1) 	//deslocando a esquerda todos os bits, pois o bit 0 � para a sele��o do byte alto ou baixo no end. de mem�ria
	ADD  ZL,AUX 	   		//soma posi��o de mem�ria correspondente ao nr. a apresentar na parte baixa do endere�o
	BRCC le_tab           	//se houve Carry, incrementa parte alta do endere�o, sen�o l� diretamente a mem�ria
	INC  ZH    
      
le_tab:		
	LPM  R0,Z            	//l� valor em R0
	OUT  DISPLAY,R0   		//mostra no display
	RET
//------------------------------------------------------------------------------------
//	Tabela p/ decodificar o display: como cada endere�o da mem�ria flash � de 16 bits, 
//	acessa-se a parte baixa e alta na decodifica��o
//------------------------------------------------------------------------------------
Tabela: .dw 0x7940, 0x3024, 0x1219, 0x7802, 0x1800, 0x0308, 0x2146, 0x0E06
//             1 0     3 2     5 4     7 6     9 8     B A     D C     F E  
//====================================================================================



; ### Sub-rotina para escrever um numero de 0 a 255 no LCD ###
				

write_number_0_999:
	clr   centenas
	clr   dezenas
	clr   unidades
findcentenas:
 	subi  numberL,100        ;keep subtracting 100
	sbci  numberH,0          ;across two bytes
	brcs  finddezenas	       ;until number goes negative
	inc   centenas         ;incrementing a "centenas" register
	rjmp  findcentenas     ;each time

finddezenas:
	subi  numberL,-100       ;add back the last hundred
	subi  numberL,10	       ;to make the number positive
	brcs  findunidades         ;and repeat the process with dezenas
	inc   dezenas
	rjmp  finddezenas+1

findunidades:
	subi numberL,-10        ;then repeat with unidades
	mov   unidades,numberL
	ldi r29,48
	 CLR  numberL      ;keep subtracting 100
	 CLR numberH          ;across two bytes

	ret