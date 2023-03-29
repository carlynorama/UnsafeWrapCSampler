//
//  uwcsampler.c
//  
//
//  Created by Labtanza on 3/25/23.
//
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "random_sampler.h"


uint8_t random_sampler_global_array[27] = { 0x33, 0x33, 0x33, 0x66, 0x66, 0x66, 0x99, 0x99, 0x99,
                                             0xCC, 0xCC, 0xCC, 0xEE, 0xEE, 0xEE, 0xEE, 0x00, 0x00,
                                             0x00, 0xEE, 0x00, 0x00, 0xEE, 0x00, 0x11, 0x11, 0x11
                                          };
size_t width = 3;
size_t height = 3;
size_t bytes_per_pixel = 3;

uint32_t random_sampler_RGBA[9] = { 0x333333FF, 0x666666FF, 0x999999FF,
                                    0xCCCCCCFF, 0xEEEEEEFF, 0xEE0000FF,
                                    0x00EE00FF, 0x00EE00FF, 0x111111FF
                                };


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



void set_all_bits_high(void* test, size_t count, size_t type_size) {
    uint8_t* cast = ((unsigned char *) test);
    //What's actually needed
    //for (size_t byte = 0; byte < type_size * count; byte++) {
    //    cast[byte] = 255;
    //}
    
    //Finer grain control for reference.
    for (size_t item = 0; item < count; item ++) {
        for (size_t byte = 0; byte < type_size; byte++) {
            cast[byte + item*type_size] = 255;
        }
    }
}

//MARK: ------------------------------------------- Buffer Process Example

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




//MARK: ------------------------------------------- Working with Strings

void print_message(const char* message) {
    printf("I have a message for you... %s", message);
}

void build_message(char* result) {
    printf("result before assignment: %p, %s\n", result, result);
    sprintf(result, "The meaning of life is %d", rand());
    printf("result after assignment: %p, %s\n", result, result);
}

void build_concise_message(char* result, size_t* length) {
    char* message_str = "abcdefghijklmnopqrstuvwxyz";
    *length = strlen(message_str) + 1;
    if (result != NULL) {
        sprintf(result, "%s", message_str);
    }
    printf("message is %zu chars. result values: %p, \"%s\"\n", *length, result, result);
}

//MARK: ------------------------------------------- Printing Functions

void print_opaque(const void* p, size_t byte_count) {
    printf("printing from pointer %p\n", p);
    for (size_t i=0; i < byte_count; i ++) {
        //printf("i:%zu, v:%02x\t", i,((unsigned char *) p) [i]);
        printf("%02x\t",((unsigned char *) p) [i]);
    }
    printf("\n");
}

void acknowledge_buffer(int* array, size_t n) {
    printf("pointer: %p\n", array);
    for (int i = 0; i < n; i++) {
        printf("value %d: %d\n", i, array[i]);
    }
}



//MARK: ------------------------------------------- Raw Proof of Concepts

void erased_struct_member_receiver(const int* value_ptr) {
    printf("I got a number: %d\n", *value_ptr);
}

void erased_tuple_receiver(const int* values, size_t count) {
    for (size_t i = 0; i < count; i++) {
        printf("%d\t", values[i]);
    }
    printf("\n");
}
