/*
 * stress_opencl.c — GPU stress test via OpenCL matrix multiplication
 * Used to verify TGP (Total Graphics Power) under load.
 *
 * Build:   gcc -O2 stress_opencl.c -o stress_gpu -lOpenCL
 * Run:     sudo ./stress_gpu
 * Monitor: watch -n1 'nvidia-smi --query-gpu=power.draw,power.limit,temperature.gpu --format=csv,noheader'
 */
#include <stdio.h>
#include <stdlib.h>
#include <CL/cl.h>

#define N 4096

const char *kernel_src =
"__kernel void matmul(__global float *A, __global float *B, __global float *C, int n) {\n"
"  int row = get_global_id(0);\n"
"  int col = get_global_id(1);\n"
"  float sum = 0.0f;\n"
"  for (int k = 0; k < n; k++) sum += A[row*n+k] * B[k*n+col];\n"
"  C[row*n+col] = sum;\n"
"}\n";

int main() {
    cl_platform_id platform;
    cl_device_id device;
    cl_context ctx;
    cl_command_queue queue;
    cl_program program;
    cl_kernel kernel;
    cl_mem A, B, C;

    clGetPlatformIDs(1, &platform, NULL);
    cl_int err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, NULL);
    if (err != CL_SUCCESS) { fprintf(stderr, "No GPU found\n"); return 1; }

    char name[128];
    clGetDeviceInfo(device, CL_DEVICE_NAME, sizeof(name), name, NULL);
    printf("Device: %s\n", name);
    printf("Matrix: %dx%d — running stress (Ctrl+C to stop)\n\n", N, N);

    ctx = clCreateContext(NULL, 1, &device, NULL, NULL, NULL);
    queue = clCreateCommandQueue(ctx, device, 0, NULL);

    size_t sz = N * N * sizeof(float);
    float *h = (float*)malloc(sz);
    for (int i = 0; i < N*N; i++) h[i] = (float)(i % 100) / 100.0f;

    A = clCreateBuffer(ctx, CL_MEM_READ_ONLY|CL_MEM_COPY_HOST_PTR, sz, h, NULL);
    B = clCreateBuffer(ctx, CL_MEM_READ_ONLY|CL_MEM_COPY_HOST_PTR, sz, h, NULL);
    C = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sz, NULL, NULL);

    program = clCreateProgramWithSource(ctx, 1, &kernel_src, NULL, NULL);
    clBuildProgram(program, 1, &device, NULL, NULL, NULL);
    kernel = clCreateKernel(program, "matmul", NULL);

    clSetKernelArg(kernel, 0, sizeof(cl_mem), &A);
    clSetKernelArg(kernel, 1, sizeof(cl_mem), &B);
    clSetKernelArg(kernel, 2, sizeof(cl_mem), &C);
    clSetKernelArg(kernel, 3, sizeof(int), &(int){N});

    size_t gs[2] = {N, N};
    size_t ls[2] = {16, 16};

    int iter = 0;
    while (1) {
        clEnqueueNDRangeKernel(queue, kernel, 2, NULL, gs, ls, 0, NULL, NULL);
        clFinish(queue);
        if (++iter % 5 == 0) printf("iter %d done\n", iter);
    }

    free(h);
    return 0;
}
