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

.data
#;sect data

# Test input
n_points:
    .word 30
points:
    .word 16, 1, 17, 2, 18, 6, 20, 3, 21, 1, 17, 4, 21, 7, 16, 4, 21, 6, 19, 6, 4, 24, 6, 24, 8, 23, 6, 26, 6, 26, 6, 23, 8, 25, 7, 26, 7, 20, 4, 21, 4, 10, 2, 10, 3, 11, 2, 12, 4, 13, 4, 9, 4, 9, 3, 8, 0, 10, 4, 10
centroids:
    .word 0,0
k:
    .word 1
clusters:
    .zero 120 # 30*4

# Colors
colors:      .word 0xff0000, 0x00ff00, 0x0000ff  #  Colors for each cluster

.equ         black      0
.equ         white      0xffffff

 
.text
#;sect text

entry:
    #;funccall mainSingleCluster 0
    
    li a7, 10
    ecall


# =========================
# ===Requested functions===
# =========================

#;funcdecl cleanScreen autosave noinline autoleaf ? ?
# void cleanScreen();
cleanScreen:
    # t0 <- ptr; t1 <- index; t2 <- calcptr; t3 <- limit
    la t0, LED_MATRIX_0_BASE
    mv t1, x0
    li t3, LED_MATRIX_0_SIZE

_cleanScreen_loop:
    add t2, t0, t1
    sw x0, 0(t2)
    addi t1, t1, 4
    blt t1, t3, _cleanScreen_loop

_cleanScreen_ret:
    ret
#;endfunc


#;funcdecl printClusters autosave noinline autoleaf ? ?
# void printClusters();
# Implemented for 2nd delivery already
printClusters:
    # s0 <- clusters; s1 <- index; s2 <- limit; s3 <- colors; s4 <- points
    # t0 <- calcptr; t1 <- tmp
    la s0, clusters
    mv s1, x0 # index = 0
    la s2, n_points
    lw s2, 0(s2)
    slli s2, s2, 2 # limit *= sizeof(int)
    la s3, colors
    la s4, points

_printClusters_loop:
    add t0, s4, s1 # calcptr = &points[index]
    add t0, t0, s1 # calcptr += index (calcptr is now &points[index << 1])
    lw a0, 0(t0) # set_pixel.x = *caclptr
    lw a1, 4(t0) # set_pixel.y = *(caclptr + 4)
    add t0, s0, s1 # calcptr = &clusters[index]
    lw t1, 0(t0) # tmp = *calcptr
    slli t1, t1, 2 # tmp <<= 2
    add t0, s3, t1 # calcptr = &colors[tmp]
    lw a2, 0(t0) # set_pixel.color = *calcptr
    #;funccall set_pixel 0
    addi s1, s1, 4 # index += 4
    bne s1, s2, _printClusters_loop

_printClusters_ret:
    ret
#;endfunc


#;funcdecl printCentroids autosave noinline autoleaf ? ?
# void printCentroids();
printCentroids:
    # s0 <- centroids; s1 <- index; s2 <- limit; s3 <- colors
    # t0 <- calcptr
    la s0, centroids
    mv s1, x0 # index = 0
    la s2, k
    lw s2, 0(s2)
    slli s2, s2, 2 # limit *= sizeof(int)
    la s3, colors

_printCentroids_loop:
    add t0, s0, s1 # calcptr = &centroids[index]
    add t0, t0, s1 # calcptr += index (calcptr is not &centroids[index << 1])
    lw a0, 0(t0) # sex_pixel.x = *calcptr
    lw a1, 4(t0) # set_pixel.y = *(calcptr + 4)
    add t0, s3, s1 # calcptr = &colors[index]
    lw a2, 0(t0) # set_pixel.color = *calcptr
    #;funccall set_pixel 0
    addi s1, s1, 4 # index += 4
    bne s1, s2, _printCentroids_loop

_printCentroids_ret:
    ret
#;endfunc


#;funcdecl calculateCentroids autosave noinline autoleaf ? ?
# void calculateCentroids();
calculateCentroids:
    # t0 <- x_tot; t1 <- y_tot; t2 <- points/centroids; t3 <- index; t4 <- limit; t5 <- calcptr; t6 <- tmp
    
    mv t0, x0 # x_tot = 0
    mv t1, x0 # y_tot = 0

    la t2, points
    mv t3, x0 # index = 0
    la t4, n_points
    lw t4, 0(t4)
    slli t4, t4, 3 # limit *= sizeof(int) * 2
_calculateCentroids_total_loop:
    add t5, t2, t3 # calcptr = $points[index]
    lw t6, 0(t5) # tmp = *calcptr
    add t0, t0, t6 # x_tot += tmp
    lw t6, 4(t5) # tmp = *(calcptr + 4)
    add t1, t1, t6 # y_tot += tmp
    addi t3, t3, 8 # index += 4
    bne t3, t4, _calculateCentroids_total_loop # loop

_calculateCentroids_divide:
    srli t4, t4, 3 # limit /= sizeof(int) * 2 (back to n_points)
    div t0, t0, t4 # x_tot /= limit
    div t1, t1, t4 # y_tot /= limit
    la t2, centroids
    # TODO: (2nd delivery) Make stores depend on k instead of constant [0]
    sw t0, 0(t2) # *(centroids + 4) = x_tot
    sw t1, 4(t2) # *(centroids + 4) = y_tot

_calculateCentroids_ret:
    ret
#;endfunc


#;funcdecl mainSingleCluster autosave noinline autoleaf ? ?
# void mainSingleCluster();
mainSingleCluster:
    li t0, 1
    la t1, k
    sw t0, 0(t1)

    #;funccall cleanScreen 0
    #;funccall printClusters 0
    #;funccall calculateCentroids 0
    #;funccall printCentroids 0

_mainSingleCluster_ret:
    ret
#;endfunc

# ===Includes===
#;include draw.s
