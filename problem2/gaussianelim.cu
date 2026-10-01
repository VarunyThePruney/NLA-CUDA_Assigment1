#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <sys/time.h>
#include <math.h>
#include <time.h>

double time()
{
    struct timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec + t.tv_usec * 0.000001;
}

// Creates a strictly diagonally dominant matrix
void createSDD(int *a, int n)
{
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            a[i * n + j] = 0;
        }

        int diagonal = 0;

        while (diagonal == 0)
        {
            diagonal = (rand() % 21) - 10; // ensures non-zero value
        }

        a[i * n + i] = diagonal;
        int remaining = abs(diagonal) - 1;

        while (remaining > 0)
        {
            int j = rand() % n;
            if (j != i && a[i * n + j] == 0)
            {
                int value = 1 + rand() % remaining;

                if (rand() % 2 == 0)
                {
                    value = -value;
                }
                a[i * n + j] = value;
                remaining -= abs(value);
            }
        }
    }
}

// Cpu logic, see README for more details
void sequential(double *a, double *x, int n)
{
    for (int i = 0; i < n - 1; i++)
    {
        for (int j = i + 1; j < n; j++)
        {
            double amount = a[j * (n + 1) + i] / a[i * (n + 1) + i];

            for (int k = i; k <= n; k++)
            {
                a[j * (n + 1) + k] = a[j * (n + 1) + k] - amount * a[i * (n + 1) + k];
            }
        }
    }

    for (int i = n - 1; i >= 0; i--)
    {
        double sum = a[i * (n + 1) + n];

        for (int k = i + 1; k < n; k++)
        {
            sum = sum - a[i * (n + 1) + k] * x[k];
        }

        x[i] = sum / a[i * (n + 1) + i];
    }
}

// Gpu logic, see README for more details
__global__ void gaussian(double *a, int n, int i)
{
    int j = i + 1 + blockIdx.y * blockDim.y + threadIdx.y;
    int k = i + 1 + blockIdx.x * blockDim.x + threadIdx.x;

    if (j < n && k <= n)
    {
        double amount = a[j * (n + 1) + i] / a[i * (n + 1) + i];

        a[j * (n + 1) + k] = a[j * (n + 1) + k] - amount * a[i * (n + 1) + k];
    }
}

// Performs back substitution after Gaussian elimination
void backSubstitution(double *a, double *x, int n)
{
    for (int i = n - 1; i >= 0; i--)
    {
        double sum = a[i * (n + 1) + n];

        for (int k = i + 1; k < n; k++)
        {
            sum = sum - a[i * (n + 1) + k] * x[k];
        }

        x[i] = sum / a[i * (n + 1) + i];
    }
}

// Checks the residual of the solution
double residual(int *a, int *b, double *x, int n)
{
    double sum = 0;

    for (int i = 0; i < n; i++)
    {
        double value = 0;

        for (int j = 0; j < n; j++)
        {
            value = value + a[i * n + j] * x[j];
        }

        value = value - b[i];
        sum = sum + value * value;
    }

    return sqrt(sum);
}

// Compares the CPU and GPU solutions
int checkResults(double *cpu, double *gpu, int n)
{
    for (int i = 0; i < n; i++)
    {
        if (fabs(cpu[i] - gpu[i]) > 0.00001)
        {
            printf("Results are NOT the same\n");
            return 0;
        }
    }

    printf("Results match with CPU\n");
    return 1;
}

int main()
{
    srand(time(NULL));

    int sizes[] = {1000, 2000};
    int threads[] = {8, 16, 32};
    const double epsilon = 0.000001;

    // Opens csv as append and writes header if csv doesnt exist
    FILE *file = fopen("results1.csv", "a");

    int run = 1;

    fseek(file, 0, SEEK_END);

    if (ftell(file) != 0)
    {
        FILE *readFile = fopen("results1.csv", "r");

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
        fprintf(file, "Run,Matrix,CPU_Time,CPU_Residual,Threads,Run1,Run2,Run3,Run4,Run5,Average,GPU_Residual\n");
    }

    // Matrix sizes loop
    for (int s = 0; s < 2; s++)
    {
        int n = sizes[s];
        int size = n * n;

        // Allocates space for A, B, augmented matrix and solutions
        int *a = (int *)malloc(size * sizeof(int));
        int *b = (int *)malloc(n * sizeof(int));

        double *aug = (double *)malloc(n * (n + 1) * sizeof(double));

        double *x_cpu = (double *)malloc(n * sizeof(double));

        double *x_gpu = (double *)malloc(n * sizeof(double));

        // Creates SDD matrix and initializes B
        createSDD(a, n);

        for (int i = 0; i < n; i++)
        {
            b[i] = 100;
        }

        // Creates augmented matrix [A | B]
        for (int i = 0; i < n; i++)
        {
            for (int k = 0; k < n; k++)
            {
                aug[i * (n + 1) + k] = a[i * n + k];
            }

            aug[i * (n + 1) + n] = b[i];
        }

        // Performs Gaussian elimination on CPU and tracks time
        double start = time();
        sequential(aug, x_cpu, n);
        double cpu_time = time() - start;

        printf("Matrix %d x %d:\nCPU time: %f seconds\n\n", n, n, cpu_time);

        double cpu_residual = residual(a, b, x_cpu, n);
        printf("CPU Residual: %.10e\n\n", cpu_residual);
        if (cpu_residual > epsilon)
        {
            printf("Residual Test FAILED: CPI: %.10e > Epsilon: %f\n", cpu_residual, epsilon);
        }
        else
        {
            printf("Residual Test PASSED: CPU: %.10e < Epsilon: %f\n", cpu_residual, epsilon);
        }

        // init data on device for GPU Gaussian elimination
        double *gpudev_a;
        cudaMalloc(&gpudev_a, n * (n + 1) * sizeof(double));

        // Runs Threads loop for the 3 thread dimensions
        double nxn_time[] = {0, 0, 0};
        for (int t = 0; t < 3; t++)
        {
            // Init square thread blocks
            int thread = threads[t];

            dim3 block(thread, thread);

            double total = 0;
            double runtime[] = {0, 0, 0, 0, 0};

            printf("Threads per block: %d x %d\n", thread, thread);

            // Runs loop for 5 iterations and measures time
            for (int run = 0; run < 5; run++)
            {
                // Resets augmented matrix
                for (int i = 0; i < n; i++)
                {
                    for (int k = 0; k < n; k++)
                    {
                        aug[i * (n + 1) + k] = a[i * n + k];
                    }

                    aug[i * (n + 1) + n] = b[i];
                }

                cudaMemcpy(gpudev_a, aug, n * (n + 1) * sizeof(double), cudaMemcpyHostToDevice);
                start = time();

                // Performs Gaussian elimination on GPU
                for (int i = 0; i < n - 1; i++)
                {
                    dim3 grid((n - i + thread - 1) / thread, (n - i + thread - 1) / thread);

                    gaussian<<<grid, block>>>(gpudev_a, n, i);
                    cudaDeviceSynchronize();
                }

                cudaMemcpy(aug, gpudev_a, n * (n + 1) * sizeof(double), cudaMemcpyDeviceToHost);

                backSubstitution(aug, x_gpu, n);

                double gpuTime = time() - start;
                runtime[run] = gpuTime;
                total += gpuTime;
                printf("run: %d Total time: %f\n", run + 1, gpuTime);
            }

            // Checks GPU results
            int flag = checkResults(x_cpu, x_gpu, n);
            if (!flag)
            {
                cudaFree(gpudev_a);
                free(a);
                free(b);
                free(aug);
                free(x_cpu);
                free(x_gpu);
                fclose(file);
                return 1;
            }

            double gpu_residual = residual(a, b, x_gpu, n);
            printf("GPU Residual: %.10e\n", gpu_residual);
            if (gpu_residual > epsilon)
            {
                printf("Residual Test FAILED: GPU: %.10e > Epsilon: %f\n", gpu_residual, epsilon);
            }
            else
            {
                printf("Residual Test PASSED: GPU: %.10e < Epsilon: %f\n", gpu_residual, epsilon);
            }

            // Calculates and prints results to output and results1.csv
            double average = total / 5;
            nxn_time[t] = average;
            printf("Average Time: %f\n", average);
            printf("Speedup comparing CPU Time to GPU: %fx\n", cpu_time / average);

            fprintf(file,
                    "%d,%d,%f,%.10e,%d,%f,%f,%f,%f,%f,%f,%.10e\n",
                    run,
                    n,
                    cpu_time,
                    cpu_residual,
                    thread,
                    runtime[0],
                    runtime[1],
                    runtime[2],
                    runtime[3],
                    runtime[4],
                    average,
                    gpu_residual);
        }

        printf("Speedup comparing 16x16 to 8x8: %fx\n", nxn_time[0] / nxn_time[1]);
        printf("Speedup comparing 32x32 to 8x8: %fx\n", nxn_time[0] / nxn_time[2]);
        printf("Speedup comparing 32x32 to 16x16: %fx\n\n", nxn_time[1] / nxn_time[2]);

        cudaFree(gpudev_a);
        free(a);
        free(b);
        free(aug);
        free(x_cpu);
        free(x_gpu);
    }
    fclose(file);
    return 0;
}