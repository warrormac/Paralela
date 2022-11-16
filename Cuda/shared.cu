#include <cstdio>
#include <cuda_runtime.h>
#include <stdlib.h>
#if defined(NDEBUG)
#define CUDA_CHECK(X) (X)
#else
#define CUDA_CHECK(X) do{\
	(X);\
	cudaError_t e = cudaGetLastError();\
	if(cudaSuccess != e){\
		printf("cuda failure %s at %s : %d",cudaGetErrorString(e), __FILE__, __LINE__);\
		exit(1);\
	}\
}while(0)
#endif
#define Tile_size 16

						
__global__ void MatrixMulKernel(int* d_M, int* d_N, int* d_P, int Width) {
    
    __shared__ int Mds[Tile_size][Tile_size]; 
    __shared__ int Nds[Tile_size][Tile_size];
				
    int bx = blockIdx.x; 
    int by = blockIdx.y; 
    int tx = threadIdx.x;
    int ty = threadIdx.y;
    						
    // Identify the row and column of the d_P element to work on 
    int Row = by * Tile_size + ty;
    int Col = bx * Tile_size + tx;
    
    
    int Pvalue = 0;
    // Loop over the d_M and d_N tiles required to compute d_P element 
    for (int ph = 0; ph < Width/Tile_size; ++ph) {
    				
        // Collaborative loading of d_M and d_N tiles into shared memory 
        Mds[ty][tx] = d_M[Row*Width + ph*Tile_size + tx];
        Nds[ty][tx] = d_N[(ph*Tile_size + ty)*Width + Col]; 
        __syncthreads();
        						
        for (int k = 0; k < Tile_size; ++k) { 
            Pvalue += Mds[ty][k] * Nds[k][tx];
        						
        }
        __syncthreads();
        						
    }

    d_P[Row*Width + Col] = Pvalue; 
}

int main()
{
	int WIDTH;
    printf("%5d Tile_size ", Tile_size);
    printf("\n INGRESAR TAMAÑO DE LAS MATRICES:");
    scanf("%d",&WIDTH);
    
	int a[WIDTH][WIDTH];
	int b[WIDTH][WIDTH];
	int c[WIDTH][WIDTH] = { 1 };

	for (int y = 0; y < WIDTH; y++) {
		for (int x = 0; x < WIDTH; x++) {
			a[y][x] = rand() % 20;
			b[y][x] = rand() % 20;
		}
	}
	
	//device side data
	int* dev_a = 0;
	int* dev_b = 0;
	int* dev_c = 0;

	//allocate device memory
	cudaMalloc((void**)&dev_a, WIDTH * WIDTH * sizeof(int));
	cudaMalloc((void**)&dev_b, WIDTH * WIDTH * sizeof(int));
	cudaMalloc((void**)&dev_c, WIDTH * WIDTH * sizeof(int));
    
    
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

	//copy from host to device
	cudaMemcpy(dev_a, a, WIDTH * WIDTH * sizeof(int), cudaMemcpyHostToDevice);	//dev_a = a
	cudaMemcpy(dev_b, b, WIDTH * WIDTH * sizeof(int), cudaMemcpyHostToDevice);	//dev_b = b

	//launch a kernel on the GPU with one thread for each element
	dim3 dimGrid((WIDTH/Tile_size) + 1, (WIDTH/Tile_size) + 1, 1);//Number of Blocks required
    dim3 dimBlock(Tile_size, Tile_size, 1);//Number of threads in each block
    
    cudaEventRecord(start);
	MatrixMulKernel << <dimGrid, dimBlock >> > (dev_a, dev_b, dev_c, WIDTH);
	cudaEventRecord(stop);
	CUDA_CHECK(cudaPeekAtLastError());

	//copy from device to host
	cudaMemcpy(c, dev_c, WIDTH * WIDTH * sizeof(int), cudaMemcpyDeviceToHost);
    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    
	//free device memory
	cudaFree(dev_c);
	cudaFree(dev_a);
	cudaFree(dev_b);

	
	printf("%fn <-TIME ", milliseconds);
	return 0;
}

