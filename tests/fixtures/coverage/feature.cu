__global__ void kernel(float *data) { data[threadIdx.x] = 1.0f; }
void launch(float *data) { kernel<<<1, 32>>>(data); }
