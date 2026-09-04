// src/cartanc/c_runtime.c - Master Cartan C Interop Runtime
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

#if defined(_WIN32) || defined(_WIN64)
#include <windows.h>
#include <shellapi.h>
#endif

#if defined(__has_include)
#if __has_include(<CL/cl.h>)
#define CL_TARGET_OPENCL_VERSION 300
#include <CL/cl.h>
#define CARTAN_HAVE_OPENCL 1
#endif
#elif defined(OPENCL_AVAILABLE)
#define CL_TARGET_OPENCL_VERSION 300
#include <CL/cl.h>
#define CARTAN_HAVE_OPENCL 1
#endif

#ifndef CARTAN_HAVE_OPENCL
typedef void* cl_context;
typedef void* cl_command_queue;
typedef void* cl_program;
typedef void* cl_kernel;
typedef void* cl_mem;
typedef void* cl_device_id;
typedef void* cl_platform_id;
typedef int cl_int;
typedef unsigned int cl_uint;
#define CL_SUCCESS 0
#define CL_DEVICE_TYPE_GPU (1 << 2)
#define CL_DEVICE_NAME 0x102B
#define CL_MEM_READ_WRITE (1 << 0)
#define CL_MEM_WRITE_ONLY (1 << 1)
#define CL_MEM_READ_ONLY (1 << 2)
#define CL_TRUE 1
#define CL_FALSE 0
#define CL_PROGRAM_BUILD_LOG 0x1183
#endif

#ifndef CARTAN_WEAK
#if defined(__clang__) || defined(__GNUC__)
#define CARTAN_WEAK __attribute__((weak))
#else
#define CARTAN_WEAK
#endif
#endif

int g_argc = 0;
char** g_argv = NULL;

// Forward declarations of pure CARTAN runtime functions for geomind C extensions
extern void* cartan_vec_create(void);
extern double cartan_vec_push_f32(void* v_ptr, double val);
extern double cartan_vec_get_f32(void* v_ptr, double idx);
extern double cartan_vec_len(void* v_ptr);
extern double cartan_file_exists(const char* path);
extern double cartan_string_eq(const char* s1, const char* s2);

static char* cartan_strdup(const char* s) {
    if (!s) {
        char* empty = (char*)malloc(1);
        if (empty) empty[0] = '\0';
        return empty;
    }
    size_t len = strlen(s);
    char* copy = (char*)malloc(len + 1);
    if (copy) {
        memcpy(copy, s, len + 1);
    }
    return copy;
}

double c_cartan_string_char_at(const char* s, double idx) {
    if (!s) return 0.0;
    size_t len = strlen(s);
    if (idx < 0 || idx >= len) return 0.0;
    return (double)(unsigned char)s[(size_t)idx];
}

char* cartan_c_memcpy(char* dest, const char* src, double count) {
    if (!dest || !src || count <= 0.0) return dest;
    return (char*)memcpy(dest, src, (size_t)count);
}

double cartan_c_strncmp(const char* s1, const char* s2, double n) {
    if (!s1 || !s2 || n <= 0.0) return 0.0;
    return (double)strncmp(s1, s2, (size_t)n);
}

char* cartan_c_ptr_add(const char* p, double offset) {
    if (!p) return NULL;
    return (char*)(p + (size_t)offset);
}

char* cartan_c_int_to_string(double val) {
    char* buf = (char*)malloc(64);
    if (!buf) return "";
    snprintf(buf, 64, "%.0f", val);
    return buf;
}

char* cartan_c_float_to_string(double val) {
    char* buf = (char*)malloc(64);
    if (!buf) return "";
    if (val == floor(val)) {
        snprintf(buf, 64, "%.1f", val);
    } else {
        snprintf(buf, 64, "%g", val);
        if (!strchr(buf, '.') && (strchr(buf, 'e') || strchr(buf, 'E'))) {
            char temp[64];
            char* ep = strchr(buf, 'e');
            if (!ep) ep = strchr(buf, 'E');
            int prefix = (int)(ep - buf);
            snprintf(temp, 64, "%.*s.0%s", prefix, buf, ep);
            strncpy(buf, temp, 64);
        }
    }
    return buf;
}

void cartan_c_sprintf_hex_byte(char* dest, double b) {
    if (!dest) return;
    snprintf(dest, 4, "\\%02x", (unsigned int)b);
}

#define CARTAN_TREE_MAGIC 0xCA57A47

typedef struct CartanTree {
    uint32_t magic;
    uint32_t ref_count;
    size_t size;
    size_t capacity;
    void** data;
} CartanTree;

void* cartan_c_tree_create(void) {
    CartanTree* t = (CartanTree*)malloc(sizeof(CartanTree));
    t->magic = CARTAN_TREE_MAGIC;
    t->ref_count = 1;
    t->size = 0;
    t->capacity = 16;
    t->data = (void**)malloc(16 * sizeof(void*));
    return t;
}

double cartan_c_tree_len_f(void* t) {
    if (!t) return 0.0;
    if (((CartanTree*)t)->magic == CARTAN_TREE_MAGIC) {
        return (double)((CartanTree*)t)->size;
    }
    return 0.0;
}

void cartan_c_tree_push(void* t, void* item) {
    if (!t) return;
    if (((CartanTree*)t)->magic == CARTAN_TREE_MAGIC) {
        CartanTree* tree = (CartanTree*)t;
        if (tree->size >= tree->capacity) {
            tree->capacity *= 2;
            tree->data = (void**)realloc(tree->data, tree->capacity * sizeof(void*));
        }
        tree->data[tree->size++] = item;
    }
}

void* cartan_c_tree_get(void* t, double idx) {
    if (!t) return NULL;
    size_t i = (size_t)idx;
    if (((CartanTree*)t)->magic == CARTAN_TREE_MAGIC) {
        CartanTree* tree = (CartanTree*)t;
        if (i < tree->size && tree->data != NULL) return tree->data[i];
        return NULL;
    }
    double* d_flat = (double*)t;
    double d0 = d_flat[0];
    uint64_t raw0 = *(uint64_t*)&d_flat[0];
    if (i == 0) {
        if ((raw0 >= 0x3FF0000000000000ULL && raw0 <= 0x406FE00000000000ULL && d0 == (double)(int)d0) || raw0 == 0) {
            return (void*)(intptr_t)(int)d0;
        }
    }
    uint64_t raw_i = *(uint64_t*)&d_flat[i];
    uint64_t exp_i = (raw_i >> 48) & 0xFFFF;
    if (exp_i >= 0x3FF0 && exp_i <= 0x43E0) {
        return (void*)(uintptr_t)(uint64_t)d_flat[i];
    }
    return (void*)(uintptr_t)raw_i;
}

void cartan_c_tree_set(void* t, double idx, void* val) {
    if (!t) return;
    size_t i = (size_t)idx;
    if (((CartanTree*)t)->magic == CARTAN_TREE_MAGIC) {
        CartanTree* tree = (CartanTree*)t;
        if (i >= tree->capacity) {
            size_t new_cap = tree->capacity == 0 ? i + 16 : (i + 1) * 2;
            tree->data = (void**)realloc(tree->data, new_cap * sizeof(void*));
            tree->capacity = new_cap;
        }
        tree->data[i] = val;
        if (i >= tree->size) {
            tree->size = i + 1;
        }
    }
}

void cartan_c_tree_remove(void* t, double idx) {
    if (!t) return;
    size_t i = (size_t)idx;
    if (((CartanTree*)t)->magic == CARTAN_TREE_MAGIC) {
        CartanTree* tree = (CartanTree*)t;
        if (i >= tree->size) return;
        for (size_t j = i; j + 1 < tree->size; j++) {
            tree->data[j] = tree->data[j + 1];
        }
        tree->size--;
    }
}

typedef struct CartanVector {
    double size;
    double capacity;
    double data[];
} CartanVector;

#ifdef CARTAN_LINK_GEOMIND_RUNTIME
#include "geomind_runtime.c"
#endif
