# NLA-CUDA_Assigment1
SE24UCSE242 - Varun Sai Golakoti\
SE24UCSE244 - 

# Matrix Multiplication:
Matrix multiplication consists of 3 main loops
1. Sizes loop: iterates twice between 1000x1000 matrix and 2000x2000 matrix.<br>This is also where the rows major arrays for A and C_cpu and C_gpu are initialized and cpuMultiply is ran with recorded times.
We then use cudaMalloc and cudaMemcpy to allocate memory space to the GPU and move needed information there. After loops 2 and 3 are done, this loop will use the runtimes found to calculate speedup between the different thread options used.
2. Threads loop: The threads loop iterates 3 times for 8x8, 16x16 and 32x32 blocks. To start, the block dimensions are configured. Ex: for 8x8 thread blocks, you will need a 125 by 125 grid of blocks to cover a 1000x1000 matrix. After the runs loop is finished, it verifies the result with checkResult() which just ensures that a[i] == c[i]. Then, it finds average and writes the data to a csv file.
3. Runs loop: This loop iterates 5 times and runs gpuMultiply for each thread option while recording runtime per run and total runtime across the 5 runs used to find average later.


<h3>CPU Multiply Logic:</h3>
The core logic of CPU is simple, mainly residing in one line. It runs a triple loop as every cell needs to multiply a column in matrix multiplcation. Resulting in n^3 operations. The main logic is<br> &emsp;&emsp;&emsp;&emsp;c[i * n + j] += a[i * n + k] * a[k * n + j].<br> Where i*n and k*n mean the row number and column number (since we are using row major) and +k and +j give exact element. Those two are then mulitplied and added to the current element i*n+j and then iterated to next k where first element a[i*n+k] moves right once and a[k*n+j] moves down one.

<h3>GPU Multiply Logic:</h3>
GPU does a somewhat similar thing, but rather than using loops to find the cell to work on, it uses the x and y coordinates of the block and thread to find the row and column. <br>Example: if you are on the 5th block and 3th thread using a 8x8 block dimension, your row is 5 * 8 + 3 = 43. As we discussed earlier, for 1000x1000 matrix, there will be 125 blocks, so doing [0-124] * 8 + [0-7] gives 1000 options, exactly one for each row. Similarly for the x coordinate and columns. You get 1000 more options, giving you exactly one thread for each cell in 1000x1000. Then: 
<br>&emsp;&emsp;&emsp;&emsp;sum += a[row * n + k] * a[k * n + col]; 
<br> is used again in a very similar fashion as CPU, but replacing the i and j with row and col. Finally, it runs cudaSynchronize to ensure that main function waits and all threads are finished to continue calculating runtime and others.
<br>
<br>

# Gaussian Elimination:
