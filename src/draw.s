#;sect text

#;funcdecl set_pixel autosave forceinline leaf ? ?
# void set_pixel(word x, word y, word color);
set_pixel:
	# t0 <- ptr; t1 <- yinv
	la t0, LED_MATRIX_0_BASE
	li t1, 0xF80 # 4 * (32 - 1) * (32)
	slli a0, a0, 2 # x*4 is x offset
	add t0, t0, a0
	slli a1, a1, 7 # y*4*32 is y offset
	sub t1, t1, a1
	add t0, t0, t1
	sw a2, 0(t0)
#_set_pixel_ret:
	ret
#;endfunc
