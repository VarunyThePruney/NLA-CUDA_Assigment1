#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

double *readMatrix(const char *filename, int n) {
    FILE *file = fopen(filename, "r");

    if (file == NULL) {
        printf("Error opening %s\n", filename);
        exit(1);
    }

    double *A = (double *)malloc(n * n * sizeof(double));

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (fscanf(file, "%lf,", &A[i * n + j]) != 1) {
                printf("Error reading matrix\n");
                exit(1);
            }
        }
    }

    fclose(file);
    return A;
}


double *readVector(const char *filename, int n) {
    FILE *file = fopen(filename, "r");

    if (file == NULL) {
        printf("Error opening %s\n", filename);
        exit(1);
    }

    double *B = (double *)malloc(n * sizeof(double));

    for (int i = 0; i < n; i++) {
        if (fscanf(file, "%lf", &B[i]) != 1) {
            printf("Error reading vector\n");
            exit(1);
        }
    }

    fclose(file);
    return B;
}


void gaussianElimination(double *A, double *B, int n) {

    for (int k = 0; k < n - 1; k++) {

        for (int i = k + 1; i < n; i++) {

            double factor = A[i * n + k] /
                            A[k * n + k];

            for (int j = k; j < n; j++) {
                A[i * n + j] -=
                    factor * A[k * n + j];
            }

            B[i] -= factor * B[k];
        }
    }
}


void backSubstitution(double *A, double *B,
                      double *X, int n) {

    for (int i = n - 1; i >= 0; i--) {

        X[i] = B[i];

        for (int j = i + 1; j < n; j++) {
            X[i] -= A[i * n + j] * X[j];
        }

        X[i] /= A[i * n + i];
    }
}


double calculateResidual(double *A,
                         double *B,
                         double *X,
                         int n) {

    double sum = 0.0;

    for (int i = 0; i < n; i++) {

        double Ax = 0.0;

        for (int j = 0; j < n; j++) {
            Ax += A[i * n + j] * X[j];
        }

        double difference = Ax - B[i];

        sum += difference * difference;
    }

    return sqrt(sum);
}


void runExperiment(int n) {

    char matrixFile[100];
    char vectorFile[100];

    sprintf(matrixFile, "data/A_%d.csv", n);
    sprintf(vectorFile, "data/B_%d.csv", n);

    printf("\n====================================\n");
    printf("Sequential Gaussian Elimination\n");
    printf("N = %d\n", n);
    printf("====================================\n");

    double *A_original = readMatrix(matrixFile, n);
    double *B_original = readVector(vectorFile, n);

    double *A = (double *)malloc(n * n * sizeof(double));
    double *B = (double *)malloc(n * sizeof(double));
    double *X = (double *)malloc(n * sizeof(double));

    // Make copies because Gaussian elimination modifies A and B
    for (long long i = 0; i < (long long)n * n; i++) {
        A[i] = A_original[i];
    }

    for (int i = 0; i < n; i++) {
        B[i] = B_original[i];
    }

    clock_t start = clock();

    gaussianElimination(A, B, n);
    backSubstitution(A, B, X, n);

    clock_t end = clock();

    double time_taken =
        (double)(end - start) / CLOCKS_PER_SEC;

    double residual =
        calculateResidual(A_original,
                          B_original,
                          X,
                          n);

    printf("Execution Time = %.6f seconds\n",
           time_taken);

    printf("Residual = %.10e\n", residual);

    free(A_original);
    free(B_original);
    free(A);
    free(B);
    free(X);
}


int main() {

    runExperiment(1000);
    runExperiment(2000);

    return 0;
}
