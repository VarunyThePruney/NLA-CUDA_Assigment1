#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>

double time()
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

int main()
{
}