;sect text

;funcdecl sleep_ms 1
# void sleep_ms(destroy word ms, destroy, ..., a7=destroy)
sleep_ms:
	# a0 <- ms_low
	# s0 <- ms_bkp; s1 <- start_ms
	mv s0, a0
	li a7, 30
	ecall
	mv s1, a0

_sleep_ms_loop:
	ecall
	sub a0, a0, s1
	bltu a0, s0, _sleep_ms_loop

_sleep_ms_ret:
	ret
;endfunc
