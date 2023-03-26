//
//  uwcsampler.c
//  
//
//  Created by Labtanza on 3/25/23.
//
#include <stdlib.h>
#include "random_sampler.h"


int* random_sampler_global_array[5] = { 1, 53, 98, 12, 13 };

void seed_random(unsigned int seed) {
    srand(seed);
}

void random_int_pointer(int* pointer) {
    *pointer = rand();
    
}
//This would be better.
int random_int() {
    return rand();
}


void random_array_of_zero_to_one_hundred(int* array, size_t n) {
    for (int i = 0; i < n; i++)
    {
        array[i] = rand() % 100;
    }
}

void add_random_value_up_to(int* array, size_t n, int max) {
    for (int i = 0; i < n; i++)
    {
        //printf("cfunc before: %d\t", array[i]);
        array[i] = array[i] + (rand() % max);
        //printf("cfunc after: %d\n", array[i]);
    }
}

//trying to model sysctl example from video a bit more usefully.
int buffer_process(int* settings,
                   u_int settings_count,
                   size_t* width_ptr,
                   size_t* height_ptr,
                   size_t bytes_per_pixel,
                   size_t* calculated_size_ptr,
                   void* input_buffer,
                   void* output_buffer
                   ) {
    
    for (int i = 0; i < settings_count; i ++) {
        printf("fake update setting no: %d\n", settings[i]);
    }
    
    *calculated_size_ptr = *width_ptr * *height_ptr * bytes_per_pixel;
    
    printf("\nINPUT\n");
    for (int p; p < *calculated_size_ptr; p++) {
        printf("%02x\t", ((char*)input_buffer)[p]);
        if (p % *width_ptr == 0) { printf("\n"); }
        ((char*)output_buffer)[p] = ((char*)input_buffer)[p] + 2;
    }
    printf("\nOUTPUT\n");
    for (int p; p < *calculated_size_ptr; p++) {
        printf("%02x\t", ((char*)input_buffer)[p]);
        if (p % *width_ptr == 0) { printf("\n"); }
        ((char*)output_buffer)[p] = ((char*)input_buffer)[p] + 2;
    }
    
    
}
