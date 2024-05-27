;sect header
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

# LED should be 32x32
# In all C translation comments, pointers are assumed to be char* or equivalent,
# pointer scaling is done by hand and ignored in the comments

;sectord header data text
;poison jal jalr

;sect data
.data

# Test input
n_points:
    .word 30
points:
    .word 16, 1, 17, 2, 18, 6, 20, 3, 21, 1, 17, 4, 21, 7, 16, 4, 21, 6, 19, 6, 4, 24, 6, 24, 8, 23, 6, 26, 6, 26, 6, 23, 8, 25, 7, 26, 7, 20, 4, 21, 4, 10, 2, 10, 3, 11, 2, 12, 4, 13, 4, 9, 4, 9, 3, 8, 0, 10, 4, 10
centroids:
    .word 0,0, 0,0, 0,0
k:
    .word 3
clusters:
    .zero 120 # 30*4

# Colors
colors:      .word 0xff0000, 0x00ff00, 0x0000ff  #  Colors for each cluster

.equ         black      0
.equ         white      0xffffff

 
;sect text
.text

entry:
    ;funccall mainKMeans
    
    li a7, 10
    ecall


# ========================================
# ===Requested functions (1st delivery)===
# ========================================

;funcdecl cleanScreen 0 noinline
# void cleanScreen();
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
# void printClusters(destroy, destroy, destroy);
# Implemented for 2nd delivery already
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
# void printCentroids(destroy, destroy, destroy);
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

;funcdecl calculateCentroidsK1 0 noinline 
# void calculateCentroidsK1();
calculateCentroidsK1:
    # t0 <- x_tot; t1 <- y_tot; t2 <- points/centroids; t3 <- index; t4 <- limit; t5 <- calcptr; t6 <- tmp
    mv t0, x0 # x_tot = 0
    mv t1, x0 # y_tot = 0
    la t2, points
    mv t3, x0 # index = 0
    la t4, n_points
    lw t4, 0(t4)
    slli t4, t4, 3 # limit *= sizeof(word) * 2 (because sizeof(x) + sizeof(y))
    
_calculateCentroidsK1_total_loop:
    # Accumulate total x and y values
    add t5, t2, t3 # calcptr = $points[index]
    lw t6, 0(t5) # tmp = *calcptr
    add t0, t0, t6 # x_tot += tmp
    lw t6, 4(t5) # tmp = *(calcptr + 4)
    add t1, t1, t6 # y_tot += tmp
    addi t3, t3, 8 # index += 4
    bne t3, t4, _calculateCentroids_total_loop # while (index < limit)

_calculateCentroidsK1_divide:
    # Divide by count to get floor(average) and store it
    srli t4, t4, 3 # limit /= sizeof(int) * 2 (back to n_points)
    div t0, t0, t4 # x_tot /= limit
    div t1, t1, t4 # y_tot /= limit
_calculateCentroidsK1_store:
    la t2, centroids
    # TODO: (2nd delivery) Make stores depend on k instead of constant [0]
    sw t0, 0(t2) # *centroids = x_tot
    sw t1, 4(t2) # *(centroids + 4) = y_tot

_calculateCentroidsK1_ret:
    ret
;endfunc

;funcdecl calculateCentroids 0 noinline
calculateCentroids:
_calculateCentroids_ret:
    ret
;endfunc

# ========================================
# ===Requested functions (2nd delivery)===
# ========================================

;funcdecl initializeCentroids 0 noinline
# void initializeCentroids(destroy);
initializeCentroids:
    # s0 <- cur_idx; s1 <- limit
    # t0 <- calcptr
    mv s0, x0
    la s1, k
    lw s1, 0(s1)

_initializeCentroids_iter:
    ;funccall rng_step
    la t0, centroids
    add t0, t0, s0
    sw a0, 0(t0)
    addi s0, s0, 4
    bne s0, s1, _initializeCentroids_iter

_initializeCentroids_ret:
    ret
;endfunc

;funcdecl manhattanDistance 4 noinline
# word manhattanDistance(word x1, word y1, word x2, word y2);
manhattanDistance:
    # t0 <- axis_tmp
    sub t0, a2, a0 # axis_tmp = x2 - x1
    blt t0, x0, _manhattanDistance_x_positive
    neg t0, t0 # axis_tmp *= -1
_manhattanDistance_x_positive:
    mv a0, t0

    sub t0, a3, a1 # axis_tmp = y2 - y1
    blt t0, x0, _manhattanDistance_y_positive
    neg t0, t0
_manhattanDistance_y_positive:
    add a0, a0, t0

_manhattanDistance_ret:
    ret
;endfunc

;funcdecl nearestCluster 2 noinline
# word nearestCluster(word x, word y, destroy, destroy);
nearestCluster:
    # s0 <- x_backup; s1 <- nearest_idx; s2 <- nearest_dist; s3 <- cur_idx; s4 <- limit
    # t0 <- tmp_x; t1 <- tmp_y; t2 <- calcptr
    mv s0, a0 # Backup x
    addi s2, x0, -1 # nearest_dist = 0xFFFFFFFF
    mv s3, x0 # cur_idx = 0
    la s4, k
    lw s4, 0(s4)
    slli s4, s4, 2 # limit = k * sizeof(word)

_nearestCluster_iter:
    la t2, centroids
    add t2, t2, s3 # calcptr = &centroids[cur_idx]
    lw t0, 0(t2) # tmp_x = *calcptr
    lw t1, 4(t2) # tmp_x = *(calcptr + 4)
    #REVIEW: function call
    ;funccall manhattanDistance s0 a1 t0 t1
    bgeu a0, s2 _nearestCluster_skip_closest
    mv s2, a0
    srli s1, s3, 2
_nearestCluster_skip_closest:
    addi s3, s3, 4
    bne s3, s4, _nearestCluster_iter

_nearestCluster_ret:
    mv a0, s1
    ret
;endfunc

;funcdecl mainKMeans 0 noinline
mainKMeans:
    ;funccall initializeCentroids

mainKMeans_iter:
    ;funccall cleanScreen
    #TODO: Calculate clusters
    ;funccall calculateCentroids
    ;funccall printClusters
    ;funccall printCentroids
    #TODO: Loop until no change

_mainKMeans_ret:
    ret
;endfunc

# ========================
# ===Auxiliar functions===
# ========================



# ===Includes===
;include draw.s
;include rng.s
