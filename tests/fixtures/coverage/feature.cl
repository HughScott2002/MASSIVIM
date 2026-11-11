__kernel void add(__global float *a) { a[get_global_id(0)] += 1; }
