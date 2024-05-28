;sect text

;funcdecl dbg_int 1
# void dbg_int(word int, ..., a7=destroy)
dbg_int:
	li a7, 1
	ecall
	ret
;endfunc

;funcdecl dbg_str 1
# void dbg_int(word str, ..., a7=destroy)
dbg_str:
	li a7, 4
	ecall
	ret
;endfunc

;funcdecl dbg_hex 1
# void dbg_int(word int, ..., a7=destroy)
dbg_hex:
	li a7, 34
	ecall
	ret
;endfunc

;funcdecl dbg_bin 1
# void dbg_int(word int, ..., a7=destroy)
dbg_bin:
	li a7, 35
	ecall
	ret
;endfunc

;funcdecl dbg_uns 1
# void dbg_int(word int, ..., a7=destroy)
dbg_uns:
	li a7, 36
	ecall
	ret
;endfunc
