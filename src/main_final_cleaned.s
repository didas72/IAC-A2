#
# IAC 2023/2024 k-means
# 
# Grupo: 1
# Campus: Taguspark
#
# Autores:
# 106196, Diogo Cruz Diniz
#
# Tecnico/ULisboa

# INTRO:
# There are a lot of comment lines in this style at the header that explain several things in the project
# They can be moslty ignored but they also justify a lot of the decisions made in the code. 

# PREPROCESSING:
# The provided code was processed by RV_Fabrication v1.0 by Didas72 with command 'RV_Fabrication -lS src/main.s'
# The preprocessor performs includes with section preservation, auto-saving of registers, function calls and inlines (latter unused), symbol poisoning and macro application (unused)
# Code can be provided as needed. (kept in a private repository until final project submission)
# The output code was cleaned by hand to strip some of the generated comments that cluttered the code.
# These mostly consisted of commented function code, which is replaced by processed code.
# Preprocessor directives were preserved. These are mostly unintrusive and help understand how the preprocessor was used.
# Preprocessor comments start with '[[FABR]]'
# Some .sect directives may seem out of place, but it is simply a product of how the preprocessor handles includes.

# RIPES:
# The LED matrix is expected to be 32 by 32.

# C COMMENTS:
# In all C translation comments, pointers are assumed to be char* or equivalent.
# Pointer scaling is done by hand and ignored in the comments

# FUNCTION DOCUMENTATION:
# Functions are documented as follows:
#
# ;funcdecl <name> <argc> [inlinehint]
# # <name>(<arguments>*); //<remarks>
# [further notes]
# <name>:
# # <register usage>
#
# Where
# <argument> can be either:
#    '[modifier] <type> [name]' - for most arguments
#    '<reg>=<argument>' - for shortening function declarations
#    '<modifier>'
# modifiers can be 'return' for arguments which are also return values, 'destroy' for regs which are overwritten or 'const' if the register is not altered
# NOTE: The argument notes are mere hints, not to be used as specs. The RV calling convention is the spec.
# NOTE: The behaviours of functions explicitly requested are less documented since theire behaviour was not defined by me.

# LABELS:
# A lot of labels throughout the code are never referenced.
# These are present for readability. All labels follow a specific format:
# <function_name>: - for regular function declaration
# _<function_name>_<internal_name>: - for 'function-private' labels
# Label placement is also part of the documentation
# When a label is preceeded by a blank line, it denotes a separate block of code,
# whereas a label that is preceeded by a line of code, is either used in a jump or is a mere name for part of the 'code sequence'.

# DEBUGGING FUNCTIONS:
# Several functions were implemented for debugging purposes. These were preserved for future reference but their calls removed with an exception.
# The debugging functions fall into two groups: log and sleep.
# Functions used for logging are defined in dbg.s and are simple prints to the RIPES console.
# The only sleep function if defines in sleep.s and it actively waits X milliseconds. Calls to this function were preserved as they help see the algorithm in action.

# EXTRA VARIABLES:
# Only 'centroids_prev' was added as an extra variable. It holds the previous state of 'centroids'.
# It is used to detect changes in the centroids, to determine when to stop the algorithm.

# SAVED REGISTERS AND OPTIMIZATIONS:
# Certain functions use more sX registers than may seem necessary.
# These are mostly array base pointers that could be 'la'd as needed, but they were kept in dedicated
# registers to speed up pointer calculation, given the lack of indexing options in RISC-V I.
# This results in more push/pop operations but the perfomance gain was considered worth the trouble.
# This optimization was not always used.
#
# In 'leaf' functions, tX registers were used to avoid unnecessary pushs of sX registers.
# This goes against the RISC-V convention, but register integrity was ensured by the preprocessor.

# CONCLUSIONS/RESTROSPECTIVE:
# An optimization to array traversal was noticed halfway through the project and was not applied everywhere.
# When traversing arrays backwards, there is no need to keep a 'limit' register, used widely across the code.
# The simple comparison between the index and zero suffices to determine the stop condition, sparing a register per array traversed.
#
# There could have been more consistency with what optimizations where and were not used, which might have made the code less readable.

#[[FABR]] ;include draw.s
#[[FABR]] ;sect text
.data

# Test input
n_points:
    .word 30
points:
    .word 16, 1, 17, 2, 18, 6, 20, 3, 21, 1, 17, 4, 21, 7, 16, 4, 21, 6, 19, 6, 4, 24, 6, 24, 8, 23, 6, 26, 6, 26, 6, 23, 8, 25, 7, 26, 7, 20, 4, 21, 4, 10, 2, 10, 3, 11, 2, 12, 4, 13, 4, 9, 4, 9, 3, 8, 0, 10, 4, 10
k:
    .word 3 # Also update clusters, centroids and centroids_prev
clusters:
    .zero 120 # 30*4
centroids:
    .word 0,0, 0,0, 0,0
centroids_prev:
    .word -1,-1, -1,-1, -1,-1
l:
    .word 20

colors:      .word 0xff0000, 0x00ff00, 0x0000ff  #  Colors for each cluster

.equ         black      0
.equ         white      0xffffff

 
#[[FABR]] ;sect text
# PRNG
rng_current:
    .word 0x69DEAD69 # Default seed, used if rng_seed is not called

#[[FABR]] ;sect text
.text

# Entry point, not declared as a function
entry:
#[[FABR]]     ;funccall rng_seed
	call rng_seed
#[[FABR]]     ;funccall mainKMeans
	call mainKMeans
    
    li a7, 10
    ecall


# ========================================
# ===Requested functions (1st delivery)===
# ========================================

#[[FABR]] ;funcdecl cleanScreen 0 noinline
# cleanScreen();
cleanScreen:
    # t0 <- ptr; t1 <- index; t2 <- calcptr; t3 <- limit; t4 <- white
    la t0, LED_MATRIX_0_BASE
    mv t1, x0 # index = 0
    li t3, LED_MATRIX_0_SIZE
    li t4, white

_cleanScreen_loop:
    add t2, t0, t1 # calcptr = &matrix[index]
    sw t4, 0(t2) # *calcptr = white
    addi t1, t1, 4 # index += sizeof(word)
    blt t1, t3, _cleanScreen_loop # while (index < matrixSize)

_cleanScreen_ret:
    ret

#[[FABR]] ;funcdecl printClusters 0 noinline
# printClusters(destroy, destroy, destroy);
printClusters:
	addi sp, sp, -24
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw ra, 20(sp)
    # s0 <- clusters; s1 <- index; s2 <- limit; s3 <- colors; s4 <- points
    # t0 <- calcptr; t1 <- clust_idx
    la s0, clusters
    mv s1, x0 # index = 0
    la s2, n_points
    lw s2, 0(s2)
    slli s2, s2, 2 # limit *= sizeof(word)
    la s3, colors
    la s4, points

_printClusters_loop:
    # Iterate through each point, get it's coordinates,
    # find color from cluster index, and call set_pixel
    add t0, s4, s1 # calcptr = &points[index]
    add t0, t0, s1 # calcptr += index (calcptr is now &points[index << 1])
    lw a0, 0(t0) # set_pixel.x = *caclptr
    lw a1, 4(t0) # set_pixel.y = *(caclptr + 4)
    add t0, s0, s1 # calcptr = &clusters[index]
    lw t1, 0(t0) # clust_idx = *calcptr
    slli t1, t1, 2 # clust_idx <<= 2 (clust_idx *= sizeof(word) to calculate offset)
    add t0, s3, t1 # calcptr = &colors[clust_idx]
    lw a2, 0(t0) # set_pixel.color = *calcptr
	call set_pixel
    addi s1, s1, 4 # index += sizeof(word)
    bne s1, s2, _printClusters_loop

_printClusters_ret:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw ra, 20(sp)
	addi sp, sp, 24
    ret

#[[FABR]] ;funcdecl printCentroids 0 noinline
# printCentroids(destroy, destroy, destroy);
printCentroids:
	addi sp, sp, -16
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw ra, 12(sp)
    # s0 <- centroids; s1 <- index; s2 <- limit
    # t0 <- calcptr
    la s0, centroids
    mv s1, x0 # index = 0
    la s2, k # load k pointer
    lw s2, 0(s2) # load k value
    slli s2, s2, 2 # limit *= sizeof(int)
    li a2, black # set_pixel.color = black for all iterations

_printCentroids_loop:
    # Iterate through each centroid, fetch coordinates and call set_pixel
    add t0, s0, s1 # calcptr = &centroids[index]
    add t0, t0, s1 # calcptr += index (calcptr is not &centroids[index << 1])
    lw a0, 0(t0) # sex_pixel.x = *calcptr
    lw a1, 4(t0) # set_pixel.y = *(calcptr + 4)
    # set_pixel.color is already set
	call set_pixel
    addi s1, s1, 4 # index += 4
    bne s1, s2, _printCentroids_loop # while(index < limit)

_printCentroids_ret:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw ra, 12(sp)
	addi sp, sp, 16
    ret

#[[FABR]] ;funcdecl calculateCentroids 0 noinline
# calculateCentroids();
# For each cluster, iterate through it's points and average their coordinates
calculateCentroids:
	addi sp, sp, -32
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s6, 24(sp)
	sw s7, 28(sp)
	# s0 <- cluster; s1 <- points; s2 <- centroids; s3 <- clusters; s4 <- x_accum; s5 <- y_accum; s6 <- counter; s7 <- point_idx
	# t0 <- calcptr; t1 <- tmp

	# cluster = n - 1
	la s0, k
	lw s0, 0(s0)
	addi s0, s0, -1

	# Array pointers
	la s1, points
	la s2, centroids
	la s3, clusters

_calculateCentroids_cluster_iter:
    # init with 0
	mv s4, x0
	mv s5, x0
	mv s6, x0

	# point_idx = (n_points - 1) * sizeof(word)
	la s7, n_points
	lw s7, 0(s7)
	addi s7, s7, -1
	slli s7, s7, 2

_calculateCentroids_point_iter:
	# iF (clusters[point_idx] != cluster) continue;
	add t0, s3, s7
	lw t1, 0(t0)
	bne s0, t1 _calculateCentroids_point_skip
	# x_accum += points[point_idx].x
	slli t0, s7, 1
	add t0, t0, s1
	lw t1, 0(t0)
	add s4, s4, t1
	# y_accum += points[point_idx].y
	lw t1, 4(t0)
	add s5, s5, t1
	# counter++
	addi s6, s6, 1
_calculateCentroids_point_skip:
	# while (point_idx--)
	addi s7, s7, -4
	bgez s7, _calculateCentroids_point_iter

_calculateCentroids_cluster_average:
    # centroids[cluster].x = x_accum; centroids[cluster].y = y_accum
	slli t0, s0, 3
    add t0, t0, s2
	beqz s6, _calculateCentroids_cluster_alone
    # x_accum /= counter; y_accum /= counter (ignore div by 0, pray if you will)
    div s4, s4, s6
	div s5, s5, s6
	sw s4, 0(t0)
	sw s5, 4(t0)
    j _calculateCentroids_cluster_not_alone
_calculateCentroids_cluster_alone: #Put clusters that have no points in (0,0)
    sw x0, 0(t0)
    sw x0, 4(t0)
_calculateCentroids_cluster_not_alone:
	# while (cluster--)
	addi s0, s0, -1
	bgez s0, _calculateCentroids_cluster_iter

_calculateCentroids_ret:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s6, 24(sp)
	lw s7, 28(sp)
	addi sp, sp, 32
    ret

# ========================================
# ===Requested functions (2nd delivery)===
# ========================================

#[[FABR]] ;funcdecl initializeCentroids 0 noinline
# initializeCentroids(destroy);
# Foreach centroid, initialize it's coordinates with random values
initializeCentroids:
	addi sp, sp, -12
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw ra, 8(sp)
    # s0 <- cur_idx; s1 <- limit
    # t0 <- calcptr
    mv s0, x0
    la s1, k
    lw s1, 0(s1)
	slli s1, s1, 3

_initializeCentroids_iter:
	call rng_step
    srli a0, a0, 27 # only preserve 5 bits (equivalent to %= 32)
	la t0, centroids
    add t0, t0, s0
    sw a0, 0(t0)
    addi s0, s0, 4
    bne s0, s1, _initializeCentroids_iter

_initializeCentroids_ret:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw ra, 8(sp)
	addi sp, sp, 12
    ret

#[[FABR]] ;funcdecl manhattanDistance 4 noinline
# manhattanDistance(return word x1, word y1, word x2, word y2);
manhattanDistance:
    # t0 <- axis_tmp
    sub t0, a2, a0 # axis_tmp = x2 - x1
    bgtz t0, _manhattanDistance_x_positive
    neg t0, t0 # axis_tmp *= -1
_manhattanDistance_x_positive:
    mv a0, t0

    sub t0, a3, a1 # axis_tmp = y2 - y1
    bgtz t0, _manhattanDistance_y_positive
    neg t0, t0 # axis_tmp *= -1
_manhattanDistance_y_positive:
    # Add x distance to y distance to form total manhattan distance
    add a0, a0, t0

_manhattanDistance_ret:
    ret

#[[FABR]] ;funcdecl nearestCluster 2 noinline
# nearestCluster(return word x, word y, destroy, destroy);
nearestCluster:
	addi sp, sp, -32
	sw s0, 0(sp)
	sw s6, 4(sp)
	sw s2, 8(sp)
	sw s3, 12(sp)
	sw s4, 16(sp)
	sw s5, 20(sp)
	sw s1, 24(sp)
	sw ra, 28(sp)
    # s0 <- x_backup; s1 <- nearest_idx; s2 <- nearest_dist; s3 <- cur_idx; s4 <- limit; s5 <- centroids, s6 <- y_backup
    # t0 <- tmp_x; t1 <- tmp_y; t2 <- calcptr
    mv s0, a0 # Backup x
    mv s6, a1 # Backup y
    addi s2, x0, -1 # nearest_dist = 0xFFFFFFFF (max unsigned value)
    mv s3, x0 # cur_idx = 0
    la s4, k
    lw s4, 0(s4) # limit = k
    la s5, centroids

_nearestCluster_iter:
    slli t2, s3, 3 # calcptr = &centroids[cur_idx * 2 * sizeof(word)]
    add t2, t2, s5
    lw t0, 0(t2) # tmp_x = *calcptr
    lw t1, 4(t2) # tmp_y = *(calcptr + 4)
	mv a0, s0
	mv a1, s6
	mv a2, t0
	mv a3, t1
	call manhattanDistance
    bgeu a0, s2 _nearestCluster_skip_closest
    mv s1, s3 # nearest_idx = cur_idx
    mv s2, a0 # nearest_dist = dist
_nearestCluster_skip_closest:
    addi s3, s3, 1 # cur_idx++
    bne s3, s4, _nearestCluster_iter

_nearestCluster_ret:
    mv a0, s1 # Store result in return register
	lw s0, 0(sp)
	lw s6, 4(sp)
	lw s2, 8(sp)
	lw s3, 12(sp)
	lw s4, 16(sp)
	lw s5, 20(sp)
	lw s1, 24(sp)
	lw ra, 28(sp)
	addi sp, sp, 32
    ret

#[[FABR]] ;funcdecl mainKMeans 0 noinline
# mainKMeans(destroy, destroy, destroy, destroy, ..., a7=destroy);
mainKMeans:
	addi sp, sp, -8
	sw s0, 0(sp)
	sw ra, 4(sp)
    # s0 <- iter_counter
    # iter_counter = l
    la s0, l
    lw s0, 0(s0)

	call initializeCentroids

mainKMeans_iter:
	call cleanScreen
	call calculateClusters
	call calculateCentroids
	call printClusters
	call printCentroids
    # This call is explained in the header
    li a0, 300
	call sleep_ms

    # Break the loop if the centroids didn't changed or l iterations reached
	call centroidsChanged
    beqz a0, _mainKMeans_ret
    addi s0, s0, -1
    bnez s0, mainKMeans_iter

_mainKMeans_ret:
	lw s0, 0(sp)
	lw ra, 4(sp)
	addi sp, sp, 8
    ret

# ========================
# ===Auxiliar functions===
# ========================

#[[FABR]] ;funcdecl calculateClusters 0
# calculateClusters(destroy, destroy, destroy, destroy);
# Foreach point, set own cluster to the nearest centroid
calculateClusters:
	addi sp, sp, -16
	sw s0, 0(sp)
	sw s1, 4(sp)
	sw s2, 8(sp)
	sw ra, 12(sp)
    # s0 <- point_idx; s1 <- points; s2 <- clusters
	# t0 <- calcptr
	# points_idx = (n_points - 1) * sizeof(word)
	la s0, n_points
	lw s0, 0(s0)
	addi s0, s0, -1
	slli s0, s0, 2

	la s1, points
	la s2, clusters

_calculateClusters_point_iter:
    # calcptr = &points[point_idx]
	slli t0, s0, 1
	add t0, t0, s1
	lw a0, 0(t0) # a0 = points[point_idx].x
	lw a1, 4(t0) # a0 = points[point_idx].y
	call nearestCluster
	add t0, s0, s2
	sw a0, 0(t0) # clusters[point_idx] = a0
	addi s0, s0, -4
	bgez s0, _calculateClusters_point_iter

_calculateClusters_ret:
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw s2, 8(sp)
	lw ra, 12(sp)
	addi sp, sp, 16
    ret

#[[FABR]] ;funcdecl centroidsChanged 0
# centroidsChanged(return bool);
centroidsChanged:
    # t0 <- centroids_ptr; t1 <- prev_ptr; t2 <- limit; t3 <- tmp1, t4 <- tmp2
    mv a0, x0 # default to false
    la t0, centroids
    la t1, centroids_prev
    la t2, k
    lw t2, 0(t2)
    slli t2, t2, 3 # limit = &centroids[k * 2 * sizeof(word)]
    add t2, t0, t2

_centroidsChanged_iter:
    lw t3, 0(t0) # check X coordinate
    lw t4, 0(t1)
    bne t3, t4, _centroidsChanged_true
    lw t3, 4(t0) # check Y coordinate
    lw t4, 4(t1)
    bne t3, t4, _centroidsChanged_true
    addi t0, t0, 8
    addi t1, t1, 8
    bne t0, t2, _centroidsChanged_iter
    j _centroidsChanged_false

_centroidsChanged_true:
    li a0, 1 # set return to true
_centroidsChanged_false:

_centroidsChanged_update:
    la t0, centroids
    la t1, centroids_prev
    # limit can be reused

_centroidsChanged_update_iter:
    lw t3, 0(t0) # copy contents of centroids to centroids_prev
    sw t3, 0(t1)
    lw t3, 4(t0)
    sw t3, 4(t1)
    addi t0, t0, 8 # advance pointers
    addi t1, t1, 8
    bne t0, t2, _centroidsChanged_update_iter

_centroidsChanged_ret:
    ret

# ===Includes===
#[[FABR]] ;include header.s
#[[FABR]] ;sect header

#[[FABR]] ;funcdecl set_pixel 3 noinline
# set_pixel(const word x, const word y, const word color);
# New implementation of printPoint, slightly faster.
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
	
#[[FABR]] ;include rng.s
#[[FABR]] ;sect data

# ==============================================
# ===Pseudo random number generator functions===
# ==============================================

#[[FABR]] ;funcdecl rng_seed 0
# rng_seed(destroy, destroy); //Set seed to system time
rng_seed:
	li a7, 30 # System time millis
	ecall
	la t0, rng_current
	sw a0, 0(t0) # Use lower half (changes more often)
_rng_seed_ret:
	ret

#[[FABR]] ;funcdecl rng_step 0
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

#[[FABR]] ;include dbg.s
#[[FABR]] ;sect text

#[[FABR]] ;funcdecl dbg_int 1
# dbg_int(word int, ..., a7=destroy)
dbg_int:
	li a7, 1 # print int
	ecall
	ret

#[[FABR]] ;funcdecl dbg_str 1
# dbg_str(word str, ..., a7=destroy)
dbg_str:
	li a7, 4 # print string
	ecall
	ret

#[[FABR]] ;funcdecl dbg_hex 1
# dbg_hex(word int, ..., a7=destroy)
dbg_hex:
	li a7, 34 # print int hex
	ecall
	ret

#[[FABR]] ;funcdecl dbg_bin 1
# dbg_bin(word int, ..., a7=destroy)
dbg_bin:
	li a7, 35 # print int binary
	ecall
	ret

#[[FABR]] ;funcdecl dbg_uns 1
# dbg_uns(word int, ..., a7=destroy)
dbg_uns:
	li a7, 36 # print int unsigned
	ecall
	ret

#[[FABR]] ;funcdecl dbg_ch 1
# dbg_ch(word char, ..., a7=destroy)
dbg_ch:
	li a7, 11 # print char
	ecall
	ret

#[[FABR]] ;funcdecl dbg_nl 0
# dbg_nl(destroy, ..., a7=destroy)
dbg_nl:
	li a7, 11 # print char
	li a0, 10 # ASCII '\n'
	ecall
	ret

#[[FABR]] ;funcdecl dbg_spc 0
# dbg_spc(destroy, ..., a7=destroy)
dbg_spc:
	li a7, 11 # print char
	li a0, 32 # ASCII ' '
	ecall
	ret

#[[FABR]] ;include sleep.s
#[[FABR]] ;sect text

#[[FABR]] ;funcdecl sleep_ms 1
# sleep_ms(destroy word ms, destroy, ..., a7=destroy)
sleep_ms:
	addi sp, sp, -8
	sw s0, 0(sp)
	sw s1, 4(sp)
	# a0 <- ms_low
	# s0 <- ms_bkp; s1 <- start_ms
	mv s0, a0
	li a7, 30 # System time millis
	ecall
	mv s1, a0

_sleep_ms_loop:
	ecall
	sub a0, a0, s1
	bltu a0, s0, _sleep_ms_loop # Loop until requested millis elapsed

_sleep_ms_ret:
	lw s0, 0(sp)
	lw s1, 4(sp)
	addi sp, sp, 8
	ret

#[[FABR]] ;sectord header data text
#[[FABR]] ;poison jal jalr

#[[FABR]] ;sect data
