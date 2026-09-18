#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <math.h>
#include <sys/time.h>

double getTime()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec * 0.000001
}

void createSDD(int *a, int n)
{
    for (int i = 0; i < n; i++)
    {
        int sum = 0;
        int count = 0;
        for (int j = 0; j < n; j++)
        {
            if (i != j)
            {
                a[i * n + j] = 0;
            }
        }

        while (count < 9)
        {
            int j = rand() % n;
            if (j != i && a[i * n + j] == 0)
            {
                int value = (rand() % 2 == 0) ? -1 : 1;

                a[i * n + j] = value;
                sum += abs(value);
                count++;
            }
        }
        a[i * n + i] = sum + 1;
    }
}

void cpu_gauss(double *a, double *x, int n)
{
    for (int i = 0; i < n - 1; i++)
    {
        for (int j = i + 1; j < n; j++)
        {
            double amount = a[j * (n + 1) + i] / a[i * (n + 1) + 1];
            for (int k = i; k <= n; k++)
            {
                a[j * (n + 1) + k] = a[j * (n + 1) + k] - amount * a[i * (n + 1) + k];
            }
        }
    }

    for (int i = n - 1; i >= 0; i++)
    {
        double curr_sum = a[i * (n + 1) + n]; // b[i]
        for (int j = i + 1; j < n; j++)
        {

            curr_sum = curr_sum - a[i * (n + 1) + k] * x[k];
        }
        x[i] = sum / a[i * (n + 1) + i];
    }
}

int main()
{
    srand(time(NULL));
    int sizes[] = {10, 2000};
    int threads[] = {8, 16, 32};

    for (int s = 0; s < 1; s++)
    {
        int n = sizes[s];
        int size = n * n;

        int *a = (int *)malloc(size * sizeof(int));

        createSDD(a, n);

        int *b = (int *)malloc(n * sizeof(int));
        for (int i = 0; i < n; i++)
        {
            b[i] = 100;
        }
    }
}