;sect text

;funcdecl dbg_int 1
# dbg_int(word int, ..., a7=destroy)
dbg_int:
	li a7, 1 # print int
	ecall
	ret
;endfunc

;funcdecl dbg_str 1
# dbg_str(word str, ..., a7=destroy)
dbg_str:
	li a7, 4 # print string
	ecall
	ret
;endfunc

;funcdecl dbg_hex 1
# dbg_hex(word int, ..., a7=destroy)
dbg_hex:
	li a7, 34 # print int hex
	ecall
	ret
;endfunc

;funcdecl dbg_bin 1
# dbg_bin(word int, ..., a7=destroy)
dbg_bin:
	li a7, 35 # print int binary
	ecall
	ret
;endfunc

;funcdecl dbg_uns 1
# dbg_uns(word int, ..., a7=destroy)
dbg_uns:
	li a7, 36 # print int unsigned
	ecall
	ret
;endfunc

;funcdecl dbg_ch 1
# dbg_ch(word char, ..., a7=destroy)
dbg_ch:
	li a7, 11 # print char
	ecall
	ret
;endfunc

;funcdecl dbg_nl 0
# dbg_nl(destroy, ..., a7=destroy)
dbg_nl:
	li a7, 11 # print char
	li a0, 10 # ASCII '\n'
	ecall
	ret
;endfunc

;funcdecl dbg_spc 0
# dbg_spc(destroy, ..., a7=destroy)
dbg_spc:
	li a7, 11 # print char
	li a0, 32 # ASCII ' '
	ecall
	ret
;endfunc
