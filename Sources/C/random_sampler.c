//
//  uwcsampler.c
//  
//
//  Created by Labtanza on 3/25/23.
//
#include <stdlib.h>
#include "random_sampler.h"


uint8_t random_sampler_global_array[36] = { 0x33, 0x33, 0x33, 0x66, 0x66, 0x66, 0x99, 0x99, 0x99,
                                             0xCC, 0xCC, 0xCC, 0xEE, 0xEE, 0xEE, 0xEE, 0x00, 0x00,
                                             0x00, 0xEE, 0x00, 0x00, 0xEE, 0x00, 0x11, 0x11, 0x11
                                          };
size_t width = 3;
size_t height = 3;
size_t bytes_per_pixel = 3;


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

void print_opaque(const void* p, size_t byte_count) {
    printf("printing from pointer %p\n", p);
    for (size_t i=0; i < byte_count; i ++) {
        //printf("i:%zu, v:%02x\t", i,((unsigned char *) p) [i]);
        printf("%02x\t",((unsigned char *) p) [i]);
    }
    printf("\n");
}

//trying to model sysctl example from video a bit more usefully.
int buffer_process(int* settings,
                   u_int settings_count,
                   const size_t* width_ptr,
                   const size_t* height_ptr,
                   size_t bytes_per_pixel,
                   size_t* calculated_size_ptr,
                   const void* input_buffer,
                   void* output_buffer
                   ) {
    
    for (int i = 0; i < settings_count; i ++) {
        printf("fake update setting no: %d\n", settings[i]);
    }
    
    *calculated_size_ptr = *width_ptr * *height_ptr * bytes_per_pixel;
    
    printf("\nINPUT\n");
    //print_opaque(input_buffer, *calculated_size_ptr);
    for (int p = 0; p < *calculated_size_ptr; p++) {
        printf("i:%d, v:%02x\t", p, ((unsigned char*)input_buffer)[p]);
        if ((p+1) % ((*width_ptr * bytes_per_pixel)) == 0) { printf("\n"); }
        ((char*)output_buffer)[p] = ((unsigned char*)input_buffer)[p] + 2;
    }
    printf("\nOUTPUT\n");
    for (int p = 0; p < *calculated_size_ptr; p++) {
        printf("i:%d, v:%02x\t", p, ((unsigned char*)output_buffer)[p]);
        if ((p+1) % ((*width_ptr * bytes_per_pixel)) == 0) { printf("\n"); }
    }
    
    
}

void call_buffer_process_test() {
    int* settings = malloc(3 * sizeof(int));
    settings[0] = 8;
    settings[1] = 12;
    settings[2] = 240877;
    size_t size_result = 0;
    char* output_buffer = malloc(9 * bytes_per_pixel);
    printf("allocated size: %lu\n", 9 * bytes_per_pixel);
    int result = buffer_process(settings,
                                3,
                                &width,
                                &height,
                                bytes_per_pixel,
                                &size_result,
                                random_sampler_global_array,
                                output_buffer
                                );
    
    printf("\ncalculated size: %zu", size_result);
    free(settings);
    free(output_buffer);
}


