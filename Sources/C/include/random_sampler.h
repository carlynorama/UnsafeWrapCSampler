//
//  uwcsampler.c.h
//  
//
//  Created by Labtanza on 3/25/23.
//

#ifndef random_sampler_h
#define random_sampler_h

#include <stdio.h>


uint8_t random_sampler_global_array[36];

void seed_random(unsigned int seed);

int random_int();
void random_int_pointer(int* pointer);


void random_array_of_zero_to_one_hundred(int* array, size_t n);
void add_random_value_up_to(int* array, size_t n, int max);

void call_buffer_process_test();
void print_opaque(const void* p, size_t byte_count);

int buffer_process(int* settings,
                   u_int settings_count,
                   const size_t* width_ptr,
                   const size_t* height_ptr,
                   size_t bytes_per_pixel,
                   size_t* calculated_size_ptr,
                   const void* input_buffer,
                   void* output_buffer
                   );


#endif /* random_sampler_h */
