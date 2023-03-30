//
//  random_provider.h
//  
//
//  Created by Carlyn Maw on 3/25/23.
//
// NOTE: The const in the header file makes a difference to the Swift Unsafe pointer type.
//
#ifndef random_provider_h
#define random_provider_h

#include <stdio.h>

typedef union c_color * CColor;


uint8_t random_provider_global_array[27];
uint32_t random_provider_RGBA[9];


void seed_random(unsigned int seed);

int random_int();
void random_int_with_result_pointer(int* result);
void random_number_in_range_with_result_pointer(const int min, const int max, int* result);
int random_number_in_range(const int* min, const int* max);
int random_number_base_plus_delta(const int* min, const int* max_delta);


void random_array_of_zero_to_one_hundred(int* array, const size_t n);
void random_array_of_min_to_max(int* array, const size_t n, const int min, const int max);
void add_random_to_all_with_max_on_random(int* array, const size_t n, const int max);
void add_random_to_all_capped(unsigned int* array, const size_t n, const int cap);


void set_all_bits_high(void* array, const size_t n, const size_t type_size);
void set_all_bits_low(void* array, const size_t n, const size_t type_size);
void set_all_bits_random(void* array, const size_t n, const size_t type_size);

void random_colors_full_alpha(uint32_t* array, const size_t n);
uint32_t random_color_and_alpha();
uint32_t random_color_full_alpha();
void print_color_info(const uint32_t color_val);
void print_color_components(const uint32_t color_val);

void call_buffer_process_test();
int buffer_process(int* settings,
                   u_int settings_count,
                   const size_t* width_ptr,
                   const size_t* height_ptr,
                   size_t bytes_per_pixel,
                   size_t* calculated_size_ptr,
                   const void* input_buffer,
                   void* output_buffer
                   );


char random_letter();
void print_message(const char* message);
void answer_to_life(char* result);
void build_concise_message(char* result, size_t* length);
void random_scramble(const char* input, char* output, size_t* length);


void print_opaque(const void* p, const size_t byte_count);
void acknowledge_buffer(int* array, const size_t n);
void acknowledge_uint32_buffer(const uint32_t* array, const size_t n);

void erased_tuple_receiver(const int* values, const size_t n);
void erased_struct_member_receiver(const int* value_ptr);

#endif /* random_provider_h */
