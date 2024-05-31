;sect data
# PRNG
rng_current:
    .word 0x69DEAD69 # Default seed, used if rng_seed is not called

;sect text

# ==============================================
# ===Pseudo random number generator functions===
# ==============================================

;funcdecl rng_seed 0
# rng_seed(destroy, destroy); //Set seed to system time
rng_seed:
	li a7, 30 # System time millis
	ecall
	la t0, rng_current
	sw a0, 0(t0) # Use lower half (changes more often)
_rng_seed_ret:
	ret
;endfunc

;funcdecl rng_step 0
# rng_step(return word); //Implements 32-bit xorshift
rng_step:
	# t0 <- tmp; t1 <- addr
	# Load current and update it
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
