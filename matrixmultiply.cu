#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <sys/time.h>

double time()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec * 0.000001;
}

void cpuMultiply(float *a, float *c, int n)
{
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            for (int k = 0; k < n; k++)
            {
                c[i * n + j] += a[i * n + k] * a[k * n + j];
            }
        }
    }
}

__global__ void gpuMutiply(float *a, float *c, int n)
{
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < n && col < n)
    {
        float sum = 0;
        for (int k = 0; k < n; k++)
        {
            sum += a[row * n + k] * a[k * n + col];
        }
        c[row * n + col] = sum;
    }
}

int main()
{
    int sizes[] = {1000, 2000};
    int threads[] = {8, 16, 32};

    FILE *file = fopen("results.csv", "a");
    fseek(file, 0, SEEK_END);
    if (ftell(file) == 0)
    {
        fprintf(file, "Matrix,CPU_Time,Threads,Run1,Run2,Run3,Run4,Run5,Average\n");
    }

    for (int s = 0; s < 2; s++)
    {
        int n = sizes[s];
        int size = n * n;

        float *a = (float *)malloc(size * sizeof(float));
        float *c = (float *)malloc(size * sizeof(float));

        for (int i = 0; i < size; i++)
        {
            a[i] = 1;
            c[i] = 0;
        }

        double start = time();

        cpuMultiply(a, c, n);
        double cpu_time = time() - start;
        printf("Matrix %d x %d:\nCPU time: %f seconds\n\n", n, n, cpu_time);

        float *d_a;
        float *d_c;

        cudaMalloc(&d_a, size * sizeof(float));
        cudaMalloc(&d_c, size * sizeof(float));

        cudaMemcpy(d_a, a, size * sizeof(float), cudaMemcpyHostToDevice);
        double nxn_time[] = {0, 0, 0};

        for (int t = 0; t < 3; t++)
        {
            int thread = threads[t];
            dim3 block(thread, thread);
            dim3 grid((n + thread - 1) / thread, (n + thread - 1) / thread);

            double total = 0;
            double runtime[] = {0, 0, 0, 0, 0};

            printf("Threads per block: %d x %d\n", thread, thread);
            for (int run = 0; run < 5; run++)
            {
                cudaMemset(d_c, 0, size * sizeof(float));
                cudaDeviceSynchronize();
                start = time();

                gpuMutiply<<<grid, block>>>(d_a, d_c, n);
                cudaDeviceSynchronize();

                double gpuTime = time() - start;
                runtime[run] = gpuTime;
                total += gpuTime;
                printf("run: %d Total time: %f\n", run + 1, gpuTime);
            }

            double average = total / 5;
            nxn_time[t] = average;
            printf("Average Time: %f\n", average);
            printf("Speedup comparing CPU Time to GPU: %fx\n", cpu_time / average);
            fprintf(file,
                    "%d,%f,%dx%d,%f,%f,%f,%f,%f,%f\n",
                    n,
                    cpu_time,
                    thread, thread,
                    runtime[0],
                    runtime[1],
                    runtime[2],
                    runtime[3],
                    runtime[4],
                    average);
        }
        printf("Speedup comparing 16x16 to 8x8: %fx\n", nxn_time[0] / nxn_time[1]);
        printf("Speedup comparing 32x32 to 8x8: %fx\n", nxn_time[0] / nxn_time[2]);
        printf("Speedup comparing 32x32 to 16x16: %fx\n\n", nxn_time[1] / nxn_time[2]);

        cudaFree(d_a);
        cudaFree(d_c);
        free(a);
        free(c);
    }
    fclose(file);
}