
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <math.h>
#include <omp.h>

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
    *a = (double *)malloc(size * sizeof(double));

    for (int i = 0; i < size; i++)
    {
        fscanf(file, "%lf", &(*a)[i]);
    }

    fclose(file);
}

int cholesky(double *a, double *l, int n)
{
    for (int k = 0; k < n; k++)
    {
        double sum = a[k * n + k];

        for (int j = 0; j < k; j++)
        {
            sum -= l[k * n + j] * l[k * n + j];
        }

        if (sum <= 0)
            return 0;

        l[k * n + k] = sqrt(sum);

#pragma omp parallel for
        for (int i = k + 1; i < n; i++)
        {
            double sum = a[i * n + k];

            for (int j = 0; j < k; j++)
            {
                sum -= l[i * n + j] * l[k * n + j];
            }

            l[i * n + k] = sum / l[k * n + k];
        }
    }

    return 1;
}

int main()
{
    char *filenames[] = {"Cholesky_Input_1024x1024.txt", "Cholesky_Input_2048x2048.txt", "Cholesky_Input_4096x4096.txt"};

    int threads[] = {2, 4, 8, 16};

    FILE *file = fopen("results_cpu_t.csv", "a");

    int run = 1;

    fseek(file, 0, SEEK_END);

    if (ftell(file) != 0)
    {
        FILE *readFile = fopen("results_cpu_t.csv", "r");

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
        fprintf(file, "Run,N,Threads,Tp,Tbest\n");
    }

    for (int s = 0; s < 3; s++)
    {
        double *a;
        int n;
        readMatrix(filenames[s], &a, &n);
        int size = n * n;
        double best = 999999999.0;
        double runtime[4];
        printf("Matrix: %d x %d\n", n, n);

        for (int t = 0; t < 4; t++)
        {
            double *l = (double *)calloc(size, sizeof(double));
            omp_set_num_threads(threads[t]);

            double start = getTime();
            int valid = cholesky(a, l, n);
            double cpu_time = getTime() - start;
            free(l);

            if (!valid)
            {
                printf("Cholesky decomposition failed.\n");
                break;
            }

            runtime[t] = cpu_time;

            printf("Threads: %d, Tp: %f seconds\n",
                   threads[t], runtime[t]);

            if (runtime[t] < best)
                best = runtime[t];
        }

        printf("TCPU_best: %f seconds\n\n", best);
        for (int t = 0; t < 4; t++)
        {
            fprintf(file, "%d,%d,%d,%f,%f\n", run, n, threads[t], runtime[t], best);
        }

        free(a);
    }

    fclose(file);
    return 0;
}
