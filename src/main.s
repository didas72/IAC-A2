;sectord header data text
;poison jal jalr

;sect data
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

 
;sect text
.text

# Entry point, not declared as a function
entry:
    ;funccall rng_seed
    ;funccall mainKMeans
    
    li a7, 10
    ecall


# ========================================
# ===Requested functions (1st delivery)===
# ========================================

;funcdecl cleanScreen 0 noinline
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
;endfunc

;funcdecl printClusters 0 noinline
# printClusters(destroy, destroy, destroy);
printClusters:
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
    ;funccall set_pixel a0 a1 a2
    addi s1, s1, 4 # index += sizeof(word)
    bne s1, s2, _printClusters_loop

_printClusters_ret:
    ret
;endfunc

;funcdecl printCentroids 0 noinline
# printCentroids(destroy, destroy, destroy);
printCentroids:
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
    ;funccall set_pixel a0 a1 a2
    addi s1, s1, 4 # index += 4
    bne s1, s2, _printCentroids_loop # while(index < limit)

_printCentroids_ret:
    ret
;endfunc

;funcdecl calculateCentroids 0 noinline
# calculateCentroids();
# For each cluster, iterate through it's points and average their coordinates
calculateCentroids:
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
_calculateCentroids_cluster_alone: //Put clusters that have no points in (0,0)
    sw x0, 0(t0)
    sw x0, 4(t0)
_calculateCentroids_cluster_not_alone:
	# while (cluster--)
	addi s0, s0, -1
	bgez s0, _calculateCentroids_cluster_iter

_calculateCentroids_ret:
    ret
;endfunc

# ========================================
# ===Requested functions (2nd delivery)===
# ========================================

;funcdecl initializeCentroids 0 noinline
# initializeCentroids(destroy);
# Foreach centroid, initialize it's coordinates with random values
initializeCentroids:
    # s0 <- cur_idx; s1 <- limit
    # t0 <- calcptr
    mv s0, x0
    la s1, k
    lw s1, 0(s1)
	slli s1, s1, 3

_initializeCentroids_iter:
    ;funccall rng_step
    srli a0, a0, 27 # only preserve 5 bits (equivalent to %= 32)
	la t0, centroids
    add t0, t0, s0
    sw a0, 0(t0)
    addi s0, s0, 4
    bne s0, s1, _initializeCentroids_iter

_initializeCentroids_ret:
    ret
;endfunc

;funcdecl manhattanDistance 4 noinline
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
;endfunc

;funcdecl nearestCluster 2 noinline
# nearestCluster(return word x, word y, destroy, destroy);
nearestCluster:
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
    ;funccall manhattanDistance s0 s6 t0 t1
    bgeu a0, s2 _nearestCluster_skip_closest
    mv s1, s3 # nearest_idx = cur_idx
    mv s2, a0 # nearest_dist = dist
_nearestCluster_skip_closest:
    addi s3, s3, 1 # cur_idx++
    bne s3, s4, _nearestCluster_iter

_nearestCluster_ret:
    mv a0, s1 # Store result in return register
    ret
;endfunc

;funcdecl mainKMeans 0 noinline
# mainKMeans(destroy, destroy, destroy, destroy, ..., a7=destroy);
mainKMeans:
    # s0 <- iter_counter
    # iter_counter = l
    la s0, l
    lw s0, 0(s0)

    ;funccall initializeCentroids

mainKMeans_iter:
    ;funccall cleanScreen
    ;funccall calculateClusters
    ;funccall calculateCentroids
    ;funccall printClusters
    ;funccall printCentroids
    # This call is explained in the header
    li a0, 300
    ;funccall sleep_ms a0

    # Break the loop if the centroids didn't changed or l iterations reached
    ;funccall centroidsChanged
    beqz a0, _mainKMeans_ret
    addi s0, s0, -1
    bnez s0, mainKMeans_iter

_mainKMeans_ret:
    ret
;endfunc

# ========================
# ===Auxiliar functions===
# ========================

;funcdecl calculateClusters 0
# calculateClusters(destroy, destroy, destroy, destroy);
# Foreach point, set own cluster to the nearest centroid
calculateClusters:
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
	;funccall nearestCluster a0 a1
	add t0, s0, s2
	sw a0, 0(t0) # clusters[point_idx] = a0
	addi s0, s0, -4
	bgez s0, _calculateClusters_point_iter

_calculateClusters_ret:
    ret
;endfunc

;funcdecl centroidsChanged 0
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
;endfunc

# ===Includes===
;include header.s
;include draw.s
;include rng.s
;include dbg.s
;include sleep.s
