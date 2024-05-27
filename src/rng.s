;sect data
# PRNG
rng_current:
    .word 0x69DEAD69

;sect text

;funcdecl rng_step 0
# word rng_step(); //xorshift
rng_step:
	# t0 <- tmp; t1 <- addr
	la t1, rng_current
	lw a0, 0(t1)
	slli t0, a0, 13
	xor a0, a0, t0
	srli t0, a0, 17
	xor a0, a0, t0
	slli t0, a0, 5
	xor a0, a0, t0
	sw t0, 0(t1)
_rng_step_ret:
	ret
;endfunc
