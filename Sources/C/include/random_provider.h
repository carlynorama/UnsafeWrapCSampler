//
//  random_provider.h
//  
//
//  Created by Carlyn Maw on 3/25/23.
//
// NOTE: A const in the function definition makes a
// difference to the Swift Unsafe pointer type.
//
// I went a little overboard and const'd the values as well.
// I have since confirmed that swift does NOT need that to pass
// in let values after all. I have left them in b/c working code works.

// More:
// Modern C compilers are probably smart enough to not copy-on pass
// but on change (TODO, check clang), so not sure that there is
// performance/memory diff with const vs no const on function args
// (promising to be safe) any more.

// For more about const and its usage (C++ discussion)
// https://isocpp.org/wiki/faq/const-correctness#overview-const
//
#ifndef random_provider_h
#define random_provider_h

#include <stdio.h>

//------------------------------------------------------- initializer
void seed_random(unsigned int seed);

//----------------------------------------------------- single values
int random_int();
void random_int_with_result_pointer(int* result);
void random_number_in_range_with_result_pointer(const int min, const int max, int* result);
int random_number_in_range(const int* min, const int* max);
int random_number_base_plus_delta(const int* min, const int* max_delta);


//-----------------------  arrays of random values & modifying arrays
void random_array_of_zero_to_one_hundred(int* array, const size_t n);
void random_array_of_min_to_max(int* array, const size_t n, const int min, const int max);
void add_random_to_all_with_max_on_random(int* array, const size_t n, const int max);
void add_random_to_all_capped(unsigned int* array, const size_t n, unsigned int cap);

void call_buffer_process_test();
int fuzz_buffer(int* settings,
                u_int settings_count,
                const size_t* width_ptr,
                const size_t* height_ptr,
                size_t bytes_per_pixel,
                size_t* calculated_size_ptr,
                uint8_t fuzz_amount,
                const void* input_buffer,
                void* output_buffer
                );


//------------------------------------------- retrieving fixed arrays
uint8_t random_provider_uint8_array[27];
uint32_t random_provider_RGBA_array[9];


//------------------------------------------------ working with void*
void set_all_bits_high(void* array, const size_t n, const size_t type_size);
void set_all_bits_low(void* array, const size_t n, const size_t type_size);
void set_all_bits_random(void* array, const size_t n, const size_t type_size);
void print_opaque(const void* p, const size_t byte_count);


//--------------------------------------------- "Color" (Union Style)

//But Swift works GREAT when you put the full def in the header, so that's what I did for the Union.

//This union is a little endian layout for colors definable with hex layout #RRGGBBAA
//This is NOT compliant with OpenGL and PNG formats RGBA32 as that assumes big endian,
//i.e. they expect RED to be at byte[0], not byte[4]. Little Endian systems should implement
//#AABBGGRR, but that is the opposite of how I'm used to writing hex colors, so yeah not gunna for this.
union CColorRGBA {
    uint32_t full;
    uint8_t bytes[4];
    struct {
        uint8_t alpha;
        uint8_t blue;
        uint8_t green;
        uint8_t red;
    };
};

struct c_color_comp {
    uint8_t alpha;
    uint8_t blue;
    uint8_t green;
    uint8_t red;
};

union CColorRGBA2 {
    uint32_t full;
    uint8_t bytes[4];
    struct c_color_comp components;
};

void random_colors_full_alpha(uint32_t* array, const size_t n);
uint32_t random_color_and_alpha();
uint32_t random_color_full_alpha();
void print_color_info(const uint32_t color_val);
void print_color_components(const uint32_t color_val);


//---------------------------------------------- working with strings
char random_letter();
void print_message(const char* message);
void answer_to_life(char* result);
void build_concise_message(char* result, size_t* length);
void random_scramble(const char* input, char* output, size_t* length);


//---------------------------------------------------- utility prints
void acknowledge_buffer(int* array, const size_t n);
void acknowledge_uint32_buffer(const uint32_t* array, const size_t n);
void acknowledge_uint8_buffer(const uint8_t* array, const size_t n);


//------------------------------------------------- used in MiscHandy
void erased_struct_member_receiver(const int* value_ptr);

//----------------------------------------------- used in TupleBridge
void erased_tuple_receiver(const int* values, const size_t n);

//-------------------------------------------------------------------


//------------------------------------- working with incomplete types
//incomplete struct definitions / Opaque Types like these are imported
//as OpaquePointers. See BridgeColor example for ways to handle that.

//----------------------------------------------  used in BridgeColor

typedef struct opaque_color* OpaqueColor;
typedef struct COpaqueColor COpaqueColor; //<-tricky to work with
                                          //from Swift. If passed
                                          //into a function as a
                                          //pointer, easier.

void test_opaque_color();
uint32_t int_from_opaque_color(OpaqueColor color);
uint32_t int_from_copaque_color_ptr(COpaqueColor* color);

//----------------------------------------------  used in ColorBridge
COpaqueColor* create_pointer_for_ccolor(); //{ //has a malloc// }
void delete_pointer_for_ccolor(COpaqueColor* ptr); //{ //has free// }
void set_color_values(COpaqueColor* c, uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha);
uint8_t ccolor_get_red(COpaqueColor* c);
uint8_t ccolor_get_green(COpaqueColor* c);
uint8_t ccolor_get_blue(COpaqueColor* c);
uint8_t ccolor_get_alpha(COpaqueColor* c);


//-------------------------------------------------------------------
#endif /* random_provider_h */


//-------------------------------------------------------------------
//-------------------------------------------------------------------
