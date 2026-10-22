# NLA-CUDA_Assigment1

SE24UCSE242 - Varun Sai Golakoti\
SE24UCSE244 - Konakalla Sai Shloka

---

https://github.com/VarunyThePruney/NLA-CUDA_Assigment1

---

# Matrix Multiplication:

Matrix multiplication consists of 3 main loops

1. Sizes loop: iterates twice between 1000x1000 matrix and 2000x2000 matrix.<br>This is also where the rows major arrays for A and C_cpu and C_gpu are initialized and cpuMultiply is ran with recorded times.
   We then use cudaMalloc and cudaMemcpy to allocate memory space to the GPU and move needed information there. After loops 2 and 3 are done, this loop will use the runtimes found to calculate speedup between the different thread options used.
2. Threads loop: The threads loop iterates 3 times for 8x8, 16x16 and 32x32 blocks. To start, the block dimensions are configured. Ex: for 8x8 thread blocks, you will need a 125 by 125 grid of blocks to cover a 1000x1000 matrix. After the runs loop is finished, it verifies the result with checkResult() which just ensures that a[i] == c[i]. Then, it finds average and writes the data to a csv file.
3. Runs loop: This loop iterates 5 times and runs gpuMultiply for each thread option while recording runtime per run and total runtime across the 5 runs used to find average later.

<h3>CPU Multiply Logic:</h3>
The core logic of CPU is simple, mainly residing in one line. It runs a triple loop as every cell needs to multiply a column in matrix multiplcation. Resulting in n^3 operations. The main logic is<br><br> &emsp;&emsp;&emsp;&emsp;c[i * n + j] += a[i * n + k] * a[k * n + j].<br><br> Where i*n and k*n mean the row number and column number (since we are using row major) and +k and +j give exact element. Those two are then multiplied and added to the current element i*n+j and then iterated to next k where first element a[i*n+k] moves right once and a[k*n+j] moves down one.

<h3>GPU Multiply Logic:</h3>
GPU does a somewhat similar thing, but rather than using loops to find the cell to work on, it uses the x and y coordinates of the block and thread to find the row and column. <br>Example: if you are on the 5th block and 3rd thread using a 8x8 block dimension, your row is 5 * 8 + 3 = 43. As we discussed earlier, for 1000x1000 matrix, there will be 125 blocks, so doing [0-124] * 8 + [0-7] gives 1000 options, exactly one for each row. Similarly for the x coordinate and columns. You get 1000 more options, giving you exactly one thread for each cell in 1000x1000. Then: 
<br><br>&emsp;&emsp;&emsp;&emsp;sum += a[row * n + k] * a[k * n + col]; 
<br><br> is used again in a very similar fashion as CPU, but replacing the i and j with row and col and copied after the inner loop finishes to c matrix. Finally, it runs cudaSynchronize to ensure that main function waits and all threads are finished to continue calculating runtime and others.
<br>
<br>

# Gaussian Elimination:

Gaussian Elimination also consists of 3 loops with a few more steps than Matrix Multiplication:

1. **Sizes Loop:** iterates twice for 1000x1000 and 2000x2000. Deals with initilization of row major matrices.

Gaussian Elimination starts with a difficult process of creating a randomized SDD (Strictly Diagonally Dominant) matrix that follows the condition:  
<br>&emsp;&emsp;&emsp;&emsp;|Aii| > ∑ j != i |Aij| <br>

We complete this in the function createSDD() where we first initilize the diagonal values Aii by doing rand() % 21 - 10 which gives a random value between [-10,10] and the while loop ensures that the diagonal element is non-zero. Next, the remaining room in the diagonal for ∑ |Aij| is calculated and while the remaining is > 0, a random j value that is not already used is found and placed with a random value ranging from [-remaining,+remaining]. This continues until remaining is 0 and the row is finished.
<br><br>
Following this step, b matrix is created with values 100 and augmented matrix [A | B] is made by appending the b values to a row of A into array aug.
<br>After this, we start CPU gaussian elimination and calculate the residual by doing ||Ax - B|| and ensure it is more accurate than our requirement of ε = 0.000001. Finally, we allocate space for our augmented matrix on the gpu with cudaMalloc

2. **Threads loop:** Runs 3 times for 8x8, 16x16 and 32x32 blocks.

First, this loop creates our dim3 block for our current thread setting. After the runs loop completes, it ensures cpu and gpu results are matching, finds residual in the same manner as CPU residual. Finally, it calculates statistics like average and speedups and writes those into the csv.

3. **Runs loop:** This loop handles 5 iterations of doing gaussian elimination on GPU while tracking time of each iteration.

This loop starts by ensuring the augmented matrix is correct as it will be modified by CPU and GPU iterations. Then, it uses cudaMemcpy to move the augmented matrix to gpudev_a on the device. Next, it runs a loop i from 0 to n-1 where i represents each column in the matrix that has to be modified to 0 to get upper triangular matrix. The code then finds the grid dimensions needed for the code block and current column and solves with GPU gaussian elimination. Next, the results in gpudev_a is copied to aug and backsubstitution is calculated and placed into x_gpu.

<h3>CPU Gaussian Elimination</h3>
CPU Gaussian elimination runs 3 loops, the i loop iterates though A matrix and finds Aii aka the pivot element. Then, the j loop iterates for every row under i to describe the rows we want to eliminate in the ith column. There, we find our pivot amount that we will do to each term in the row. Finally, we use k to update every other column in that row for the amount found. 
<br><br>&emsp;&emsp;&emsp;&emsp;a[j * (n + 1) + k] = a[j * (n + 1) + k] - amount * a[i * (n + 1) + k];
<br><br>

This line modifies every other element k in the current row j with the amount Aij / Aii

<h3>GPU Gaussian Elimination:</h3>
Once again, the gpu version is very similar, but this time it uses a loop outside for each pivot Aii element, then the blocks of threads are launched. Then, j finds which row the thread will work on under the pivot and k finds which column the thread is working on. Then, as long as the threads are inside the range, (note: k goes to n as it also modifies B's matrix values) it performs the exact same operation as CPU version.
<br><br>&emsp;&emsp;&emsp;&emsp;a[j * (n + 1) + k] = a[j * (n + 1) + k] - amount * a[i * (n + 1) + k];
<br><br>

<h3>Back Substitution:</h3>
We originally tried to also implement this in parallel, but it proved to be very difficult and inefficient as every result requires the previous results and only part that can be done on device is the summation part. <br>Outside of that, the logic of this is also quite simple, it starts with a loop for n-1 to 0 which signifies the last row and moving upwards. Then, we find the B value for that row that we want to solve for and start the k loop that signifies the summation and subtraction from B. Finally, the value of the division is computed. 
<br>
For a general row, the math goes like:
<br>
 Updated B = B - ∑Aik * Xk &emsp; Then: &emsp; xi = B / Aii
<br>
