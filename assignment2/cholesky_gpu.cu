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
    }
}