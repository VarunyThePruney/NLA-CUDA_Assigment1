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

void readMatrix(char *filename, double **a, int *n)
{
    FILE *file = fopen(filename, "r");
    fscanf(file, "%d", n);

    int size = (*n) * (*n);
    *a = (double *)malloc((size_t)size * sizeof(double));

    for (int i = 0; i < size; i++)
        fscanf(file, "%lf", &(*a)[i]);

    fclose(file);
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
    char *filenames[] = {"Cholesky_Input_1024x1024.txt", "Cholesky_Input_2048x2048.txt", "Cholesky_Input_4096x4096.txt"};

    FILE *file = fopen("results.csv", "a");

    int run = 1;

    fseek(file, 0, SEEK_END);

    if (ftell(file) != 0)
    {
        FILE *readFile = fopen("results.csv", "r");

        char line[1024];
        int lastRun = 0;

        fgets(line, sizeof(line), readFile);

        while (fgets(line, sizeof(line), readFile))
        {
            int currentRun;

            if (sscanf(line, "%d,", &currentRun) == 1)
            {
                if (currentRun > lastRun)
                {
                    lastRun = currentRun;
                }
            }
        }

        run = lastRun + 1;

        fclose(readFile);
    }

    fseek(file, 0, SEEK_END);

    if (ftell(file) == 0)
    {
        fprintf(file, "Matrix,N,T1\n");
    }

    for (int s = 0; s < 3; s++)
    {
        double *a;
        int n;

        readMatrix(filenames[s], &a, &n);

        int size = n * n;
        double *l = (double *)calloc(size, sizeof(double));

        double start = getTime();
        cholesky(a, l, n);
        double timetaken = getTime() - start;

        printf("Matrix: %s\n", filenames[s]);

        printf("Time taken: %.6f seconds\n\n", timetaken);
        fprintf(file, "%d,%d,%.6f\n", run, n, timetaken);

        free(a);
        free(l);
    }

    fclose(file);
    return 0;
}
