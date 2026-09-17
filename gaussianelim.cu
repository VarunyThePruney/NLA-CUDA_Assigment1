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