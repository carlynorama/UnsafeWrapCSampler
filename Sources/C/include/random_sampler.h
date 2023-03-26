//
//  uwcsampler.c.h
//  
//
//  Created by Labtanza on 3/25/23.
//

#ifndef random_sampler_h
#define random_sampler_h

#include <stdio.h>


int* random_sampler_global_array[5];

void seed_random(unsigned int seed);

int random_int();
void random_int_pointer(int* pointer);


void random_array_of_zero_to_one_hundred(int* array, size_t n);
void add_random_value_up_to(int* array, size_t n, int max);


#endif /* random_sampler_h */
