#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>


#define BLOCK_SIZE 256


double *readMatrix(const char *filename, int n) {

    FILE *file = fopen(filename, "r");

    if (file == NULL) {
        printf("Error opening %s\n", filename);
        exit(1);
    }

    double *A =
        (double *)malloc(n * n * sizeof(double));

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {

            if (fscanf(file, "%lf,", 
                       &A[i * n + j]) != 1) {

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

    double *B =
        (double *)malloc(n * sizeof(double));

    for (int i = 0; i < n; i++) {

        if (fscanf(file, "%lf", &B[i]) != 1) {
            printf("Error reading vector\n");
            exit(1);
        }
    }

    fclose(file);

    return B;
}


/*
    CUDA kernel.

    Each thread handles one row.
*/
__global__
void eliminateRows(double *A,
                   double *B,
                   int n,
                   int k) {

    int i = blockIdx.x * blockDim.x +
            threadIdx.x + k + 1;

    if (i < n) {

        double factor =
            A[i * n + k] /
            A[k * n + k];

        for (int j = k; j < n; j++) {

            A[i * n + j] -=
                factor * A[k * n + j];
        }

        B[i] -= factor * B[k];
    }
}


void backSubstitution(double *A,
                      double *B,
                      double *X,
                      int n) {

    for (int i = n - 1; i >= 0; i--) {

        X[i] = B[i];

        for (int j = i + 1; j < n; j++) {

            X[i] -=
                A[i * n + j] * X[j];
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

            Ax +=
                A[i * n + j] * X[j];
        }

        double difference =
            Ax - B[i];

        sum +=
            difference * difference;
    }

    return sqrt(sum);
}


void runExperiment(int n) {

    char matrixFile[100];
    char vectorFile[100];

    sprintf(matrixFile,
            "data/A_%d.csv", n);

    sprintf(vectorFile,
            "data/B_%d.csv", n);

    printf("\n====================================\n");
    printf("CUDA Parallel Gaussian Elimination\n");
    printf("N = %d\n", n);
    printf("====================================\n");


    double *A_original =
        readMatrix(matrixFile, n);

    double *B_original =
        readVector(vectorFile, n);


    long long matrixSize =
        (long long)n * n;


    double *A =
        (double *)malloc(
            matrixSize * sizeof(double));

    double *B =
        (double *)malloc(
            n * sizeof(double));

    double *X =
        (double *)malloc(
            n * sizeof(double));


    for (long long i = 0;
         i < matrixSize;
         i++) {

        A[i] = A_original[i];
    }


    for (int i = 0; i < n; i++) {

        B[i] = B_original[i];
    }


    double *d_A;
    double *d_B;


    cudaMalloc(
        (void **)&d_A,
        matrixSize * sizeof(double));

    cudaMalloc(
        (void **)&d_B,
        n * sizeof(double));


    cudaMemcpy(
        d_A,
        A,
        matrixSize * sizeof(double),
        cudaMemcpyHostToDevice);

    cudaMemcpy(
        d_B,
        B,
        n * sizeof(double),
        cudaMemcpyHostToDevice);


    cudaEvent_t start, stop;

    cudaEventCreate(&start);
    cudaEventCreate(&stop);


    cudaEventRecord(start);


    for (int k = 0; k < n - 1; k++) {

        int rows =
            n - k - 1;

        int blocks =
            (rows + BLOCK_SIZE - 1) /
            BLOCK_SIZE;

        eliminateRows<<<blocks,
                        BLOCK_SIZE>>>(
            d_A,
            d_B,
            n,
            k);

        cudaDeviceSynchronize();
    }


    cudaMemcpy(
        A,
        d_A,
        matrixSize * sizeof(double),
        cudaMemcpyDeviceToHost);

    cudaMemcpy(
        B,
        d_B,
        n * sizeof(double),
        cudaMemcpyDeviceToHost);


    backSubstitution(
        A,
        B,
        X,
        n);


    cudaEventRecord(stop);

    cudaEventSynchronize(stop);


    float milliseconds = 0;

    cudaEventElapsedTime(
        &milliseconds,
        start,
        stop);


    double seconds =
        milliseconds / 1000.0;


    double residual =
        calculateResidual(
            A_original,
            B_original,
            X,
            n);


    printf("CUDA Execution Time = %.6f seconds\n",
           seconds);

    printf("Residual = %.10e\n",
           residual);


    cudaFree(d_A);
    cudaFree(d_B);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

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
