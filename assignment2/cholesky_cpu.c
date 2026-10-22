#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

double getTime()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec * 0.000001;
}

int readMatrix(char *filename, double **a, int *n)
{
    FILE *file = fopen(filename, "r");
    fscanf(file, "%d", n);

    int size = (*n) * (*n);
    *a = (double *)malloc((size_t)size * sizeof(double));

    for (int i = 0; i < size; i++)
        fscanf(file, "%lf", &(*a)[i]);

    fclose(file);
    return 1;
}

void cholesky(double *a, double *l, int n)
{
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j <= i; j++)
        {
            double sum = a[i * n + j];

            for (int k = 0; k < j; k++)
                sum -= l[i * n + k] * l[j * n + k];

            if (i == j)
            {
                if (sum <= 0.0)
                    return;

                l[i * n + j] = sqrt(sum);
            }
            else
                l[i * n + j] = sum / l[j * n + j];
        }
    }
}

int main()
{
    char *filenames[] = {
        "Cholesky_Input_1024x1024.txt",
        "Cholesky_Input_2048x2048.txt",
        "Cholesky_Input_4096x4096.txt"};

    FILE *file = fopen("results.csv", "a+");
    fseek(file, 0, SEEK_END);

    if (ftell(file) == 0)
        fprintf(file, "Matrix,N,CPU_Time,RelativeResidual,Verified\n");

    for (int s = 0; s < 3; s++)
    {
        double *a;
        int n;

        readMatrix(filenames[s], &a, &n);

        int size = n * n;
        double *l = (double *)calloc(size, sizeof(double));
        printf("\nMatrix: %s (%d x %d)\n", filenames[s], n, n);

        double start = getTime();
        cholesky(a, l, n);
        double cpu_time = getTime() - start;

        // double r = residual(a, l, n);
        // int verified = r < 1e-10;

        printf("CPU time: %.6f seconds\n", cpu_time);
        // printf("Relative residual: %.12e\n", r);
        // printf("Verification: %s\n", verified ? "PASSED" : "FAILED");

        // fprintf(file, "%s,%d,%.6f,%.12e,%s\n", filenames[s], n, cpu_time, r, verified ? "PASSED" : "FAILED");

        fflush(file);
        free(a);
        free(l);
    }
    fclose(file);
}