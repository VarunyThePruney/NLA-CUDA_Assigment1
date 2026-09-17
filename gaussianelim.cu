#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <math.h>

int rand_num(int min, int max)
{
    return (rand() % (max - min + 1) + min);
}

int main()
{
    srand(time(NULL));
    int min = -10;
    int max = 10;

    int sizes[] = {1000, 2000};
    int threads[] = {8, 16, 32};

    for (int s = 0; s < 2; s++)
    {
        int n = sizes[s];
        int size = n * n;

        int *a = (int *)malloc(size * sizeof(int));
        for (int i = 0; i < size; i++)
        {
            a[i] = rand_num(min, max);
        }

        int *b = (int *)malloc(n * sizeof(int));
        for (int i = 0; i < n; i++)
        {
            b[i] = 100;
        }
    }
}