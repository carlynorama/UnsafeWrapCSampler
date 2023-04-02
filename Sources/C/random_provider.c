//
//  uwcsampler.c
//  
//
//  Created by Carlyn Maw on 3/25/23.
//
// This code assumes Little Endian byte order (MacOS).
// To check your system try:
// - `lscpu | grep Endian` in the command line.
// - echo -n I | od -to2 | awk 'FNR==1{ print substr($2,6,1)}'  (return will be 1 for little endian, 0 for big)
// - python3 -c "import sys;print(sys.byteorder)"
//
// The syntax 0xFFCC9966 is Big Endian in that if you assume that the left most byte (the largest) is byte[0] that is "big endian"
// In a little endian system the memory layout would be 66 99 CC FF

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "random_provider.h"

//-------------------------------------------------------------------
//MARK: structs and unions for typedefs
//-------------------------------------------------------------------

//Note: it appears that unions need to be IN THE HEADER to be defined. Using Opaque types do not work correctly?

struct opaque_color {
    uint8_t alpha;
    uint8_t blue;
    uint8_t green;
    uint8_t red;
};

struct COpaqueColor {
    uint8_t alpha;
    uint8_t blue;
    uint8_t green;
    uint8_t red;
};

//-------------------------------------------------------------------
//MARK: Constants
//-------------------------------------------------------------------

uint8_t random_provider_uint8_array[27] = { 0x33, 0x33, 0x33, 0x66, 0x66, 0x66, 0x99, 0x99, 0x99,
                                             0xCC, 0xCC, 0xCC, 0xEE, 0xEE, 0xEE, 0xEE, 0x00, 0x00,
                                             0x00, 0xEE, 0x00, 0x00, 0xEE, 0x00, 0x11, 0x11, 0x11
                                          };
size_t width = 3;
size_t height = 3;
size_t bytes_per_pixel = 3;

uint32_t random_provider_RGBA_array[9] = { 0x333333FF, 0x666666FF, 0x999999FF,
                                    0xCCCCCCFF, 0xEEEEEEFF, 0xEE0000FF,
                                    0x00EE00FF, 0x00EE00FF, 0x111111FF
                                };



const unsigned char valid_alpha[52] = { 0b01000001, 0b01000010, 0b01000011, 0b01000100, 0b01000101, 0b01000110, 0b01000111,
                                        0b01001000, 0b01001001, 0b01001010, 0b01001011, 0b01001100, 0b01001101, 0b01001110,
                                        0b01001111, 0b01010000, 0b01010001, 0b01010010, 0b01010011, 0b01010100, 0b01010101,
                                        0b01010110, 0b01010111, 0b01011000, 0b01011001, 0b01011010,
                                        0b01100001, 0b01100010, 0b01100011, 0b01100100, 0b01100101, 0b01100110, 0b01100111,
                                        0b01101000, 0b01101001, 0b01101010, 0b01101011, 0b01101100, 0b01101101, 0b01101110,
                                        0b01101111, 0b01110000, 0b01110001, 0b01110010, 0b01110011, 0b01110100, 0b01110101,
                                        0b01110110, 0b01110111, 0b01111000, 0b01111001, 0b01111010 };

//-------------------------------------------------------------------
//MARK:  Setup
//-------------------------------------------------------------------

void seed_random(const unsigned int seed) {
    srand(seed);
}

//-------------------------------------------------------------------
//MARK: Single Value
//-------------------------------------------------------------------

int random_int() {
    return rand();
}

void random_int_with_result_pointer(int* result) {
    *result = rand();
    
}

void random_number_in_range_with_result_pointer(const int min, const int max, int* result) {
    //assume can trust max > min
    *result = min + (rand() % (max-min));
}

int random_number_in_range(const int* min, const int* max) {
    return *min + (rand() % (*max-*min));
}

int random_number_base_plus_delta(const int* min, const int* max_delta) {
    return *min + (rand() % (*max_delta));
}


//-------------------------------------------------------------------
//MARK: Making & Editing Arrays with Random Values
//-------------------------------------------------------------------

//Sets values of inout array to 0-100
void random_array_of_zero_to_one_hundred(int* array, const size_t n) {
    for (size_t i = 0; i < n; i++)
    {
        array[i] = rand() % 100;
    }
}

void random_array_of_min_to_max(int* array, const size_t n, const int min, const int max) {
    int delta = max - min;
    for (size_t i = 0; i < n; i++) {
        array[i] = random_number_base_plus_delta(&min, &delta);
    }
}

//Sets values of inout array to their current value + a random number up to max
void add_random_to_all_with_max_on_random(int* array, const size_t n, const int max_delta) {
    for (size_t i = 0; i < n; i++)
    {
        //printf("cfunc before: %d\t", array[i]);
        array[i] = array[i] + (rand() % max_delta);
        //printf("cfunc after: %d\n", array[i]);
    }
}

//assumes you know that cap is already greater than all values in the array.
//array has to be unsigned to calculate cap correctly.
void add_random_to_all_capped(unsigned int* array, const size_t n, const unsigned int cap) {
    for (size_t i = 0; i < n; i++)
    {
        //printf("cfunc before: %d\t", array[i]);
        const int current = array[i];
        int max_delta = cap - current;
        array[i] = current + (rand() % max_delta);
        //printf("cfunc after: %d\n", array[i]);
    }
}

unsigned char char_whiffle(const unsigned char* byte, const unsigned char wiffle) {
    int16_t wiffle_amount = (rand() % (2 * wiffle)) - wiffle;
    int16_t result = *byte + wiffle_amount;
    printf("base byte: %d\twiffle_amount: %d\tresult: %d\n", *byte, wiffle_amount, result);
    
    if (result < 0) { result = 0; }
    else if (result > 255) { result = 255; };
    
    printf("result after clamp: %d\n", result);
    
    return (result & 0xff);
}

//-------------------------------------------------------------------
//MARK: Complex-Function type (fuzz_buffer)
//-------------------------------------------------------------------

// Meant to mimic the example in WWDC 2020 Unsafe Swift talk.

//trying to model sysctl example from video a bit more usefully.
int fuzz_buffer(int* settings,
                   u_int settings_count,
                   const size_t* width_ptr,
                   const size_t* height_ptr,
                   size_t bytes_per_pixel,
                   size_t* calculated_size_ptr,
                   uint8_t fuzz_amount,
                   const void* input_buffer,
                   void* output_buffer
                ) {
    
    for (size_t i = 0; i < settings_count; i ++) {
        printf("fake update setting no: %d\n", settings[i]);
    }
    
    *calculated_size_ptr = *width_ptr * *height_ptr * bytes_per_pixel;
    
    printf("\nINPUT\n");
    //print_opaque(input_buffer, *calculated_size_ptr);
    for (int p = 0; p < *calculated_size_ptr; p++) {
        printf("i:%d, v:%02x\t", p, ((unsigned char*)input_buffer)[p]);
        if ((p+1) % ((*width_ptr * bytes_per_pixel)) == 0) { printf("\n"); }
        //((char*)output_buffer)[p] = ((unsigned char*)input_buffer)[p] + 2;
        //unsigned char test = 100;
        //((unsigned char*)output_buffer)[p] = char_whiffle(&test, 5);
        ((unsigned char*)output_buffer)[p] = char_whiffle(&((unsigned char*)input_buffer)[p], fuzz_amount);
        
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
    int result = fuzz_buffer(settings,
                                3,
                                &width,
                                &height,
                                bytes_per_pixel,
                                &size_result,
                                5,
                                random_provider_uint8_array,
                                output_buffer
                                );
    
    printf("\ncalculated size: %zu", size_result);
    free(settings);
    free(output_buffer);
}


//-------------------------------------------------------------------
//MARK: Working with Void*
//-------------------------------------------------------------------

//This is a C "memory-rebind" that is a bigger deal to do in Swift.
void set_all_bits_high(void* array, const size_t n, const size_t type_size) {
    uint8_t* cast = ((unsigned char *) array);
    
    //Finer grain control for reference.
    for (size_t item = 0; item < n; item ++) {
        for (size_t byte = 0; byte < type_size; byte++) {
            cast[byte + item*type_size] = 255;
        }
    }
}

void set_all_bits_low(void* array, const size_t n, const size_t type_size) {
    uint8_t* cast = ((unsigned char *) array);
    for (size_t byte = 0; byte < type_size * n; byte++) {
        cast[byte] = 0;
    }
}

void set_all_bits_random(void* array, const size_t n, const size_t type_size) {
    uint8_t* cast = ((unsigned char *) array);
    //Finer grain control for reference.
//    for (size_t item = 0; item < n; item ++) {
//        for (size_t byte = 0; byte < type_size; byte++) {
//            cast[byte + item*type_size] = rand() % 255;
//        }
//    }
    for (size_t byte = 0; byte < type_size * n; byte++) {
        cast[byte] = rand() % 255;
    }
}

void print_opaque(const void* p, const size_t byte_count) {
    printf("printing from pointer %p\n", p);
    for (size_t i=0; i < byte_count; i ++) {
        //printf("i:%zu, v:%02x\t", i,((unsigned char *) p) [i]);
        printf("%02x\t",((unsigned char *) p) [i]);
    }
    printf("\n");
}

//-------------------------------------------------------------------
//MARK: Strings
//-------------------------------------------------------------------

char random_letter() {
    return valid_alpha[(rand() % 52)];
}

void print_message(const char* message) {
    printf("I have a message for you... %s\n", message);
}

void answer_to_life(char* result) {
    if (result != NULL) {
        printf("result before assignment: %p, %s\n", result, result);
        sprintf(result, "The answer to life, the universe and everything is %d", rand());
        printf("result after assignment: %p, %s\n", result, result);
    }

}

void build_concise_message(char* result, size_t* length) {
    char* message_str = "abcdefghijklmnopqrstuvwxyz";
    *length = strlen(message_str) + 1;
    if (result != NULL) {
        sprintf(result, "%s", message_str);
    }
    printf("message is %zu chars. result values: %p, \"%s\"\n", *length, result, result);
}

void random_scramble(const char* input, char* output, size_t* length) {
    
    //char* message_str = "abcdefghijklmnopqrstuvwxyz";
    *length = strlen(input) + 1;
    print_opaque(input, *length);
    if (output != NULL) {
        for (size_t i = 0; i < *length-1; i++) {
            //printf("%x ", input[i]);//65;//random_letter();
            output[i] = random_letter();
            //printf("%p\t%x\n", &output[i], output[i]);
        }
    }
    
    printf("message to scramble: %s\n", input);
    //*length = strlen(input) + 1;
    
    //In this code the stride was off all of a sudden?
//    if (output != NULL) {
//        char* tmp[*length];
//        tmp[*length-1] = 0;
//        for (size_t i = 0; i < *length-1; i++) {
//            tmp[i] = random_letter();
//        }
//        print_opaque(tmp, *length);
//        sprintf(output, "%s", *tmp);
//    } else {
//        printf("length is:%zu\n", *length);
//    }
}


//-------------------------------------------------------------------
//MARK: Utility Prints
//-------------------------------------------------------------------



void acknowledge_cint_buffer(const int* array, const size_t n) {
    printf("pointer: %p\n", array);
    for (size_t i = 0; i < n; i++) {
        printf("value %zu: %d\n", i, array[i]);
    }
}

void acknowledge_uint_buffer(const size_t* array, const size_t n) {
    printf("pointer: %p\n", array);
    for (size_t i = 0; i < n; i++) {
        printf("value %zu: %zu\n", i, array[i]);
    }
}

void acknowledge_uint8_buffer(const uint8_t* array, const size_t n) {
    printf("pointer: %p\n", array);
    for (size_t i = 0; i < n; i++) {
        printf("value %zu: %hhu\n", i, array[i]);
    }
}

void acknowledge_uint32_buffer(const uint32_t* array, const size_t n) {
    printf("pointer: %p\n", array);
    for (size_t i = 0; i < n; i++) {
        printf("value %zu: 0x%08x\n", i, array[i]);
    }
}

void acknowledge_char_buffer(const char* array, const size_t n) {
    printf("pointer: %p\n", array);
    for (size_t i = 0; i < n; i++) {
        printf("value %zu: %hhd\n", i, array[i]);
    }
}



//-------------------------------------------------------------------
//MARK: For MiscHandy
//-------------------------------------------------------------------

void erased_struct_member_receiver(const int* value_ptr) {
    printf("I got a number: %d\n", *value_ptr);
}

void erased_tuple_receiver(const int* values, const size_t n) {
    for (size_t i = 0; i < n; i++) {
        printf("%d\t", values[i]);
    }
    printf("\n");
}


//-------------------------------------------------------------------
//MARK: CColorRGBA Functions
//-------------------------------------------------------------------


uint32_t build_color(uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha) {
    union CColorRGBA my_color;
    my_color.alpha = alpha;
    my_color.blue = blue;
    my_color.green = green;
    my_color.red = red;
    return my_color.full;
}

uint32_t random_color_full_alpha() {
    union CColorRGBA my_color;
    my_color.alpha = 255;
    my_color.blue = rand() % 255;
    my_color.green = rand() % 255;
    my_color.red = rand() % 255;
    //printf("color made: 0x%08x\n", my_color.full);
    return my_color.full;
}

void random_colors_full_alpha(uint32_t* array, const size_t n) {
    for (size_t item = 0; item < n; item ++) {
        array[item] = random_color_full_alpha();
        //printf("color received: 0x%08x\n", array[item]);
    }
    acknowledge_uint32_buffer(array, n);
}

void print_color_info(const uint32_t color_val) {
    union CColorRGBA my_color;
    my_color.full = color_val;
    printf("hex: #%08x", my_color.full);
    printf("\nbytes:\t");
    for (size_t i=0; i < 4; i++) {
        printf("index: %lu, value:%d\t", i, my_color.bytes[i]);
    }
    printf("\ncomponents:\t r%03d, g%03d b%03d a%03d",
           my_color.red,
           my_color.green,
           my_color.blue,
           my_color.alpha);
    printf("\n");
}

void print_color_components(const uint32_t color_val) {
    union CColorRGBA my_color;
    my_color.full = color_val;
    printf("hex: #%08x\n", my_color.full);
    printf("\ncomponents:\t r%03d, g%03d b%03d a%03d",
           my_color.red,
           my_color.green,
           my_color.blue,
           my_color.alpha);
    printf("\n");
}

void easy_make_colors_struct(const uint8_t* values, const size_t n) {
    for (size_t i = 0; i < n; i++) {
        printf("%d\t", values[i]);
    }
    printf("\n");
    struct c_color_comp this_color;
    this_color.red = values[3];
    this_color.green = values[2];
    this_color.blue = values[1];
    this_color.alpha = values[0];
    
    printf("r%d\tg%d\tb%d\ta%d\t\n", this_color.red, this_color.green, this_color.blue, this_color.alpha);
}

// ----------- FOR REFERENCE
//void random_colors_full_alpha(uint32_t* array, const size_t n) {
//    uint8_t* cast = ((unsigned char *) array);
//    //Finer grain control for reference.
//    for (size_t item = 0; item < n; item ++) {
//        for (size_t byte = 0; byte < 3; byte++) {
//            cast[byte + item*3] = rand() % 255;
//        }
//        cast[3] = 255;
//    }
//}

//uint32_t random_color_full_alpha() {
//    uint32_t color = 0;
//    for (size_t byte = 0; byte < 3; byte++) {
//        ((unsigned char *) &color)[byte] = rand() % 255;
//    }
//    ((unsigned char *) &color)[3] = 255;
//    return color;
//}

//uint32_t masked_random(uint32_t one_bits_to_zero, uint32_t one_bits_to_one) {
//    uint32_t base = 0;
//    set_all_bits_random((unsigned char *) &base, 1, 4);
//    base = base | one_bits_to_one;
//    base = base & ~one_bits_to_zero;
//    return base;
//}
// ----------- END FOR REFERENCE



//-------------------------------------------------------------------
//MARK: Opaque Pointer Example
//-------------------------------------------------------------------


uint32_t int_from_opaque_color(OpaqueColor color) {
    printf("a%hhu, r%hhu\n", color->alpha, color->red);
    uint32_t tmp = color->alpha;
    tmp += color->blue << 8;
    tmp += color->green << 16;
    tmp += color->red << 24;
    return tmp;
}

void test_opaque_color() {
    OpaqueColor color = malloc(sizeof(uint8_t)*4);
    color->alpha = 255;
    color->blue = 0xCC;
    color->green = 0xFF;
    color->red = 0x33;
    
    uint32_t result = int_from_opaque_color(color);
    
    printf("POpaqueColor Test: 0x%08x", result);
    free(color);
}

//CANNOT be used from Swift easily.
//Swift can only work with pointers to incomplete types.
uint32_t int_from_copaque_color(COpaqueColor color) {
    printf("a%hhu, r%hhu\n", color.alpha, color.red);
    uint32_t tmp = color.alpha;
    tmp += color.blue << 8;
    tmp += color.green << 16;
    tmp += color.red << 24;
    return tmp;
}

//CAN be used from Swift easily.
uint32_t int_from_copaque_color_ptr(COpaqueColor* color) {
    printf("a%hhu, r%hhu\n", color->alpha, color->red);
    uint32_t tmp = color->alpha;
    tmp += color->blue << 8;
    tmp += color->green << 16;
    tmp += color->red << 24;
    return tmp;
}

//------ For Class Style

COpaqueColor* create_pointer_for_ccolor() {
    return malloc(sizeof(COpaqueColor));
}
void delete_pointer_for_ccolor(COpaqueColor* ptr) {
    free(ptr);
}
void set_color_values(COpaqueColor* c, uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha) {
    c->red = red;
    c->green = green;
    c->blue = blue;
    c->alpha = alpha;
}

uint8_t ccolor_get_red(COpaqueColor* c) { return c->red; }
uint8_t ccolor_get_green(COpaqueColor* c) { return c->green; }
uint8_t ccolor_get_blue(COpaqueColor* c) { return c->blue; }
uint8_t ccolor_get_alpha(COpaqueColor* c) { return c->alpha; }
