#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <sys/time.h>
#include <math.h>

double time()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec * 0.000001;
}

void readMatrix(char *filename, double **a, int *n)
{
    FILE *file = fopen(filename, "r");
    fscanf(file, "%d", n);

    int size = (*n) * (*n);
    *a = (double *)malloc(size * sizeof(double));

    for (int i = 0; i < size; i++)
    {
        fscanf(file, "%lf", &(*a)[i]);
    }

    fclose(file);
}

__global__ void calculateDiagonal(double *a, int n, int k)
{
    if (threadIdx.x == 0 && blockIdx.x == 0)
    {
        double sum = a[k * n + k];

        for (int j = 0; j < k; j++)
        {
            sum -= a[k * n + j] * a[k * n + j];
        }

        a[k * n + k] = sqrt(sum);
    }
}

__global__ void calculateColumn(double *a, int n, int k)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x + k + 1;

    if (i < n)
    {
        double sum = a[i * n + k];

        for (int j = 0; j < k; j++)
        {
            sum -= a[i * n + j] * a[k * n + j];
        }

        a[i * n + k] = sum / a[k * n + k];
    }
}

int main()
{
    char *filenames[] = {"Cholesky_Input_1024x1024.txt", "Cholesky_Input_2048x2048.txt", "Cholesky_Input_4096x4096.txt"};

    FILE *file = fopen("results_gpu.csv", "w");
    fprintf(file, "Matrix,N,TGPU,Te2e\n");

    for (int s = 0; s < 3; s++)
    {
        double e2e_start = time();
        double *a;

        readMatrix(filenames[s], &a, &n);
        int size = n * n;

        double *gpudev_a;

        cudaMalloc(&gpudev_a, size * sizeof(double));
        cudaMemcpy(gpudev_a, a, size * sizeof(double), cudaMemcpyHostToDevice);

        int block_num = (n + 255) / 256;
        double start = time();

        for (int k = 0; k < n; k++)
        {
            calculateDiagonal<<<1, 1>>>(gpudev_a, n, k);
            calculateColumn<<<block_num, 256>>>(gpudev_a, n, k);
        }
        cudaDeviceSynchronize();
        double gpu_time = time() - start;

        cudaMemcpy(a, gpudev_a, size * sizeof(double), cudaMemcpyDeviceToHost);

        double e2e_time = time() - e2e_start;
    }
}