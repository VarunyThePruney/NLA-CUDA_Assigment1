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

__global__ void gpuMutiply(float *a, float *b, float *c, int n)
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

    for (int s = 0; s < 2; s++)
    {
        int n = sizes[s];
        int size = n * n;
    }
}