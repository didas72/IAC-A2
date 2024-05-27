;sect text

;funcdecl set_pixel 3 noinline
# void set_pixel(const word x, const word y, const word color);
# New implementation of set_pixel, slightly faster
# Takes for granted that the matrix will always be 32x32
set_pixel:
	# Y coordinate is inverted (higher values are below)
	# Pixel offset is x + (height - y) * width
	# Multiplied by sizeof(word) gives offset to base pointer
	# To get offset from (x,y):
	# off = sizeof(word) * (x + (height - y) * width)
	# t0 <- ptr; t1 <- offset
	la t0, LED_MATRIX_0_BASE # Load base pointer
	li t1, 31 # offset = height - 1
	sub t1, t1, a1 # offset = height - y
	slli t1, t1, 5 # offset = (height - y) * width
	add t1, t1, a0 # offset = x + (height - y) * width
	slli t1, t1, 2 # offset = sizeof(word) * (x + (height - y) * width)
	add t0, t0, t1 # calculate final pointer
	sw a2, 0(t0) # store color
_set_pixel_ret:
	ret
;endfunc
