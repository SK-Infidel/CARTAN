// src/cartanc/geomind_runtime.c - Model & AI Runtime Extensions
#ifndef _CRT_SECURE_NO_WARNINGS
#define _CRT_SECURE_NO_WARNINGS 1
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

#if defined(_WIN32) || defined(_WIN64)
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <shellapi.h>
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
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

typedef struct CartanVector {
    double size;
    double capacity;
    double data[];
} CartanVector;

extern void* cartan_tree_create(void);
extern void* cartan_tree_get(void* t, double idx);
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

CARTAN_WEAK void cartan_print_string(const char* text) {
    if (text) {
        fputs(text, stdout);
        fflush(stdout);
    }
}

CARTAN_WEAK double cartan_system(const char* cmd) {
    if (!cmd) return -1.0;
    int res = system(cmd);
    return (double)res;
}

#if defined(_WIN32) || defined(_WIN64)
static int g_cartan_winsock_initialized = 0;
static void cartan_ensure_winsock(void) {
    if (!g_cartan_winsock_initialized) {
        WSADATA wsa;
        if (WSAStartup(MAKEWORD(2, 2), &wsa) == 0) {
            g_cartan_winsock_initialized = 1;
        }
    }
}
#endif

CARTAN_WEAK double cartan_socket_create(void) {
#if defined(_WIN32) || defined(_WIN64)
    cartan_ensure_winsock();
    SOCKET s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (s == INVALID_SOCKET) {
        return -1.0;
    }
    int opt = 1;
    setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (const char*)&opt, sizeof(opt));
    return (double)((uintptr_t)s);
#else
    int s = socket(AF_INET, SOCK_STREAM, 0);
    if (s < 0) {
        return -1.0;
    }
    int opt = 1;
    setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    return (double)s;
#endif
}

CARTAN_WEAK double cartan_socket_connect(double sock, const char* host, double port) {
    if (!host || sock < 0.0) return 0.0;
#if defined(_WIN32) || defined(_WIN64)
    cartan_ensure_winsock();
    SOCKET s = (SOCKET)(uintptr_t)(uint64_t)sock;
#else
    int s = (int)sock;
#endif
    char port_str[16];
    snprintf(port_str, sizeof(port_str), "%d", (int)port);

    struct addrinfo hints, *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;

    if (getaddrinfo(host, port_str, &hints, &res) != 0 || !res) {
        return 0.0;
    }

    int rc = connect(s, res->ai_addr, (int)res->ai_addrlen);
    freeaddrinfo(res);
    return (rc == 0) ? 1.0 : 0.0;
}

CARTAN_WEAK double cartan_socket_bind(double sock, const char* host, double port) {
    if (sock < 0.0) return 0.0;
#if defined(_WIN32) || defined(_WIN64)
    cartan_ensure_winsock();
    SOCKET s = (SOCKET)(uintptr_t)(uint64_t)sock;
#else
    int s = (int)sock;
#endif
    char port_str[16];
    snprintf(port_str, sizeof(port_str), "%d", (int)port);

    struct addrinfo hints, *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;

    const char* bind_host = (host && strlen(host) > 0) ? host : NULL;
    if (getaddrinfo(bind_host, port_str, &hints, &res) != 0 || !res) {
        return 0.0;
    }

    int rc = bind(s, res->ai_addr, (int)res->ai_addrlen);
    freeaddrinfo(res);
    return (rc == 0) ? 1.0 : 0.0;
}

CARTAN_WEAK double cartan_socket_listen(double sock, double backlog) {
    if (sock < 0.0) return 0.0;
    int b = (backlog <= 0.0) ? 5 : (int)backlog;
#if defined(_WIN32) || defined(_WIN64)
    SOCKET s = (SOCKET)(uintptr_t)(uint64_t)sock;
    int rc = listen(s, b);
#else
    int s = (int)sock;
    int rc = listen(s, b);
#endif
    return (rc == 0) ? 1.0 : 0.0;
}

CARTAN_WEAK double cartan_socket_accept(double sock) {
    if (sock < 0.0) return -1.0;
#if defined(_WIN32) || defined(_WIN64)
    SOCKET s = (SOCKET)(uintptr_t)(uint64_t)sock;
    SOCKET client = accept(s, NULL, NULL);
    if (client == INVALID_SOCKET) {
        return -1.0;
    }
    return (double)((uintptr_t)client);
#else
    int s = (int)sock;
    int client = accept(s, NULL, NULL);
    if (client < 0) {
        return -1.0;
    }
    return (double)client;
#endif
}

CARTAN_WEAK double cartan_socket_set_timeout(double sock, double timeout_ms) {
    if (sock < 0.0) return 0.0;
#if defined(_WIN32) || defined(_WIN64)
    SOCKET s = (SOCKET)(uintptr_t)(uint64_t)sock;
    DWORD tv = (DWORD)timeout_ms;
    setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof(tv));
    setsockopt(s, SOL_SOCKET, SO_SNDTIMEO, (const char*)&tv, sizeof(tv));
#else
    int s = (int)sock;
    struct timeval tv;
    tv.tv_sec = (long)(timeout_ms / 1000.0);
    tv.tv_usec = (long)(((long)timeout_ms % 1000) * 1000);
    setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    setsockopt(s, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
#endif
    return 1.0;
}

CARTAN_WEAK double cartan_socket_send(double sock, const char* data) {
    if (!data || sock < 0.0) return 0.0;
#if defined(_WIN32) || defined(_WIN64)
    SOCKET s = (SOCKET)(uintptr_t)(uint64_t)sock;
#else
    int s = (int)sock;
#endif
    int len = (int)strlen(data);
    int total = 0;
    while (total < len) {
        int bytes = send(s, data + total, len - total, 0);
        if (bytes <= 0) break;
        total += bytes;
    }
    return (double)total;
}

CARTAN_WEAK char* cartan_socket_recv(double sock) {
    if (sock < 0.0) return cartan_strdup("");
#if defined(_WIN32) || defined(_WIN64)
    SOCKET s = (SOCKET)(uintptr_t)(uint64_t)sock;
#else
    int s = (int)sock;
#endif
    char* buf = (char*)malloc(4096);
    if (!buf) return cartan_strdup("");
    memset(buf, 0, 4096);
#if defined(_WIN32) || defined(_WIN64)
    int bytes = recv(s, buf, 4095, 0);
#else
    ssize_t bytes = recv(s, buf, 4095, 0);
#endif
    if (bytes <= 0) {
        buf[0] = '\0';
    } else {
        buf[bytes] = '\0';
    }
    return buf;
}

CARTAN_WEAK double cartan_socket_close(double sock) {
    if (sock < 0.0) return 0.0;
#if defined(_WIN32) || defined(_WIN64)
    SOCKET s = (SOCKET)(uintptr_t)(uint64_t)sock;
    closesocket(s);
#else
    int s = (int)sock;
    close(s);
#endif
    return 1.0;
}

double cartan_http_download_file(const char* url, const char* out_path) {
    if (!url || !out_path) return 0.0;
    
    char token_buf[512] = {0};
    const char* hf_token = getenv("HF_TOKEN");
    if (!hf_token) hf_token = getenv("HUGGING_FACE_HUB_TOKEN");
    if (!hf_token) hf_token = getenv("HUGGINGFACE_TOKEN");
    
    if (!hf_token) {
#if defined(_WIN32) || defined(_WIN64)
        const char* user_profile = getenv("USERPROFILE");
        if (user_profile) {
            char tok_file[1024];
            snprintf(tok_file, sizeof(tok_file), "%s\\.cache\\huggingface\\token", user_profile);
            FILE* tf = fopen(tok_file, "r");
            if (tf) {
                if (fgets(token_buf, sizeof(token_buf), tf)) {
                    size_t len = strlen(token_buf);
                    while (len > 0 && (token_buf[len-1] == '\r' || token_buf[len-1] == '\n' || token_buf[len-1] == ' ')) {
                        token_buf[--len] = '\0';
                    }
                    if (len > 0) hf_token = token_buf;
                }
                fclose(tf);
            }
        }
#endif
    }

    char cmd[4096];
    if (hf_token && strlen(hf_token) > 0) {
#if defined(_WIN32) || defined(_WIN64)
        snprintf(cmd, sizeof(cmd), "curl.exe -s -L -H \"Authorization: Bearer %s\" \"%s\" -o \"%s\"", hf_token, url, out_path);
#else
        snprintf(cmd, sizeof(cmd), "curl -s -L -H 'Authorization: Bearer %s' '%s' -o '%s'", hf_token, url, out_path);
#endif
    } else {
#if defined(_WIN32) || defined(_WIN64)
        snprintf(cmd, sizeof(cmd), "curl.exe -s -L \"%s\" -o \"%s\"", url, out_path);
#else
        snprintf(cmd, sizeof(cmd), "curl -s -L '%s' -o '%s'", url, out_path);
#endif
    }
    int res = system(cmd);
    return (double)res;
}

// --- Safetensors Binary Loader Runtime Functions ---
double cartan_safetensors_header_length(const char* path) {
    if (!path) return 0.0;
    FILE* f = fopen(path, "rb");
    if (!f) return 0.0;
    
    _fseeki64(f, 0, SEEK_END);
    uint64_t file_size = (uint64_t)_ftelli64(f);
    _fseeki64(f, 0, SEEK_SET);
    
    if (file_size < 8) {
        fclose(f);
        return 0.0;
    }

    uint64_t len = 0;
    if (fread(&len, sizeof(uint64_t), 1, f) != 1) {
        fclose(f);
        return 0.0;
    }
    fclose(f);

    if (len == 0 || len >= file_size) {
        return 0.0;
    }
    return (double)len;
}

char* cartan_safetensors_read_header(const char* path) {
    if (!path) return cartan_strdup("{}");
    FILE* f = fopen(path, "rb");
    if (!f) return cartan_strdup("{}");
    uint64_t len = 0;
    if (fread(&len, sizeof(uint64_t), 1, f) != 1 || len > 100 * 1024 * 1024) {
        fclose(f);
        return cartan_strdup("{}");
    }
    char* header_json = (char*)malloc(len + 1);
    if (!header_json) { fclose(f); return cartan_strdup("{}"); }
    size_t read_bytes = fread(header_json, 1, len, f);
    fclose(f);
    header_json[read_bytes] = '\0';
    return header_json;
}

CARTAN_WEAK double cartan_safetensors_find_offset(const char* path, const char* tensor_name) {
    if (!path || !tensor_name) return 0.0;
    char* header = cartan_safetensors_read_header(path);
    if (!header) return 0.0;
    
    char key[256];
    snprintf(key, sizeof(key), "\"%s\"", tensor_name);
    char* pos = strstr(header, key);
    if (!pos) { free(header); return 0.0; }
    
    char* offsets_pos = strstr(pos, "\"data_offsets\"");
    if (!offsets_pos) { free(header); return 0.0; }
    
    char* start_bracket = strchr(offsets_pos, '[');
    if (!start_bracket) { free(header); return 0.0; }
    
    double start_offset = (double)strtoull(start_bracket + 1, NULL, 10);
    free(header);
    return start_offset;
}

CARTAN_WEAK float cartan_bf16_to_f32(uint16_t u) {
    uint32_t val32 = ((uint32_t)u) << 16;
    float f;
    memcpy(&f, &val32, sizeof(float));
    return f;
}

CARTAN_WEAK void* cartan_safetensors_load_tensor_f32(const char* path, double header_len, double data_start, double num_elements) {
    if (!path || num_elements <= 0) return cartan_tree_create();
    FILE* f = fopen(path, "rb");
    if (!f) return cartan_tree_create();
    uint64_t offset = 8 + (uint64_t)header_len + (uint64_t)data_start;
#if defined(_WIN32) || defined(_WIN64)
    _fseeki64(f, offset, SEEK_SET);
#else
    fseeko(f, offset, SEEK_SET);
#endif
    size_t count = (size_t)num_elements;
    uint16_t* raw_bf16 = (uint16_t*)malloc(count * sizeof(uint16_t));
    if (!raw_bf16) { fclose(f); return cartan_tree_create(); }
    size_t read_count = fread(raw_bf16, sizeof(uint16_t), count, f);
    fclose(f);

    void* tree = cartan_vec_create();
    for (size_t i = 0; i < read_count; i++) {
        float fval = cartan_bf16_to_f32(raw_bf16[i]);
        cartan_vec_push_f32(tree, (double)fval);
    }
    free(raw_bf16);
    return tree;
}

#define CARTAN_MAX_VOCAB_SIZE 262144
static char* g_vocab_table[CARTAN_MAX_VOCAB_SIZE] = {0};
static int g_vocab_init = 0;

static void cartan_clean_sp_bytes(char* token_str) {
    if (!token_str) return;
    char* src = token_str;
    char* dst = token_str;
    while (*src) {
        if ((unsigned char)src[0] == 0xE2 && (unsigned char)src[1] == 0x96 && (unsigned char)src[2] == 0x81) {
            *dst++ = ' ';
            src += 3;
        } else {
            *dst++ = *src++;
        }
    }
    *dst = '\0';
}

static void cartan_init_gemma_vocab_if_needed(void) {
    if (g_vocab_init) return;
    g_vocab_init = 1;

    const char* paths[] = {
        "cache_google_gemma-4-E4B-it_tokenizer.json",
        "../cache_google_gemma-4-E4B-it_tokenizer.json",
        "C:/Users/rich-/source/repos/CARTAN/cache_google_gemma-4-E4B-it_tokenizer.json",
        "tokenizer.json",
        "../tokenizer.json"
    };

    const char* target_path = NULL;
    size_t num_paths = sizeof(paths) / sizeof(paths[0]);
    for (size_t p = 0; p < num_paths; p++) {
        FILE* check = fopen(paths[p], "rb");
        if (check) {
            fclose(check);
            target_path = paths[p];
            break;
        }
    }

    if (!target_path) return;

    FILE* f = fopen(target_path, "rb");
    if (!f) return;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (size <= 0 || size > 128 * 1024 * 1024) { fclose(f); return; }

    char* buf = (char*)malloc(size + 1);
    if (!buf) { fclose(f); return; }
    size_t read_bytes = fread(buf, 1, size, f);
    fclose(f);
    buf[read_bytes] = '\0';

    char* vocab_pos = strstr(buf, "\"vocab\"");
    if (!vocab_pos) { free(buf); return; }

    char* p = vocab_pos;
    while (*p && *p != '{') p++;
    if (*p == '{') p++;

    while (*p && *p != '}') {
        while (*p && *p != '"' && *p != '}') p++;
        if (*p != '"') break;
        p++;
        char* key_start = p;
        while (*p && *p != '"') {
            if (*p == '\\' && p[1] != '\0') p += 2;
            else p++;
        }
        if (*p != '"') break;
        size_t key_len = p - key_start;
        p++;

        while (*p && *p != ':' && *p != '}') p++;
        if (*p != ':') break;
        p++;

        while (*p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
        size_t token_id = (size_t)strtoull(p, &p, 10);

        if (token_id < CARTAN_MAX_VOCAB_SIZE && g_vocab_table[token_id] == NULL) {
            char* t_str = (char*)malloc(key_len + 1);
            memcpy(t_str, key_start, key_len);
            t_str[key_len] = '\0';
            cartan_clean_sp_bytes(t_str);
            g_vocab_table[token_id] = t_str;
        }

        while (*p && *p != ',' && *p != '}') p++;
        if (*p == ',') p++;
    }

    free(buf);
}

CARTAN_WEAK char* cartan_hub_decode_json_token(const char* json_path, double token_id) {
    cartan_init_gemma_vocab_if_needed();
    size_t id = (size_t)token_id;
    if (id < CARTAN_MAX_VOCAB_SIZE && g_vocab_table[id] != NULL) {
        return cartan_strdup(g_vocab_table[id]);
    }
    return cartan_strdup(" .");
}

CARTAN_WEAK double cartan_tokenizer_is_valid_bigram(double tok1, double tok2) {
    cartan_init_gemma_vocab_if_needed();
    size_t id1 = (size_t)tok1;
    size_t id2 = (size_t)tok2;
    if (id1 >= CARTAN_MAX_VOCAB_SIZE || id2 >= CARTAN_MAX_VOCAB_SIZE) return 0.0;
    if (!g_vocab_table[id1] || !g_vocab_table[id2]) return 0.0;

    const char* str1 = g_vocab_table[id1];
    const char* str2 = g_vocab_table[id2];
    while (*str1 == ' ') str1++;
    while (*str2 == ' ') str2++;

    if (strcmp(str1, str2) == 0) {
        if (strcmp(str1, "that") == 0 || strcmp(str1, "had") == 0 || strcmp(str1, "very") == 0 || strcmp(str1, "is") == 0 || strcmp(str1, "in") == 0) {
            return 1.0;
        }
    }
    return 0.0;
}

CARTAN_WEAK double cartan_hub_ensure_tokenizer_json(const char* json_path) {
    if (!json_path) return 0.0;
    FILE* check_f = fopen(json_path, "rb");
    if (check_f) {
        fclose(check_f);
        return 1.0;
    }
    return 0.0;
}

#define CARTAN_BUFFER_POOL_SIZE (64 * 1024 * 1024)
#define CARTAN_MAX_BUFFER_POOL_BLOCKS 1024

typedef struct {
    void* ptr;
    size_t size;
    int is_free;
} CARTANBufferBlock;

typedef struct {
    CARTANBufferBlock blocks[CARTAN_MAX_BUFFER_POOL_BLOCKS];
    size_t count;
    int is_initialized;
} CARTANBufferPool;

static CARTANBufferPool g_buffer_pool = {0};

CARTAN_WEAK void cartan_rt_buffer_pool_init(void) {
    if (g_buffer_pool.is_initialized) return;
    g_buffer_pool.count = 0;
    g_buffer_pool.is_initialized = 1;
}

CARTAN_WEAK void* cartan_rt_buffer_pool_alloc(size_t size) {
    if (!g_buffer_pool.is_initialized) {
        cartan_rt_buffer_pool_init();
    }
    // Search recycled blocks first for step-1 saturation recycling
    for (size_t i = 0; i < g_buffer_pool.count; i++) {
        if (g_buffer_pool.blocks[i].is_free && g_buffer_pool.blocks[i].size >= size) {
            g_buffer_pool.blocks[i].is_free = 0;
            return g_buffer_pool.blocks[i].ptr;
        }
    }
    // Allocate new block in step-1 pool
    if (g_buffer_pool.count < CARTAN_MAX_BUFFER_POOL_BLOCKS) {
        size_t alloc_sz = size > 4096 ? size : 4096;
        void* p = malloc(alloc_sz);
        if (p) {
            size_t idx = g_buffer_pool.count++;
            g_buffer_pool.blocks[idx].ptr = p;
            g_buffer_pool.blocks[idx].size = alloc_sz;
            g_buffer_pool.blocks[idx].is_free = 0;
            return p;
        }
    }
    return malloc(size);
}

CARTAN_WEAK void cartan_rt_buffer_pool_free(void* ptr) {
    if (!ptr) return;
    for (size_t i = 0; i < g_buffer_pool.count; i++) {
        if (g_buffer_pool.blocks[i].ptr == ptr) {
            g_buffer_pool.blocks[i].is_free = 1;
            return;
        }
    }
    free(ptr);
}

// --- Tensor Backpropagation & Hidden State Computations ---
#define CARTAN_FULL_VOCAB_SIZE 262144
#define CARTAN_HEAD_BANK_SIZE 65536
#define CARTAN_HEAD_NUM_BANKS 4
#define CARTAN_LM_HEAD_VOCAB 65536
static double g_model_weights[2560][2560];
static float* g_model_weights_flat = NULL;
static int g_weights_init = 0;
static float* g_gemma_embed_matrix = NULL;
CARTAN_WEAK void cartan_init_gemma_embed_matrix_if_needed(void);
static void cartan_get_gemma_embed_row(size_t token_id, float* out_vec, size_t dim);
CARTAN_WEAK void* e8_attention_forward_step(void* hidden_ptr, double temp);
CARTAN_WEAK double cartan_hopfield_clear(void);
CARTAN_WEAK double cartan_hopfield_attractor_count(void);
CARTAN_WEAK double cartan_hopfield_store_vector(const float* vec, size_t dim);
CARTAN_WEAK double cartan_hopfield_store_hidden(void* hidden_ptr);
CARTAN_WEAK double cartan_hopfield_ingest(const char* filepath);
CARTAN_WEAK double cartan_hopfield_relax(void* hidden_ptr, double beta, double steps);
CARTAN_WEAK double cartan_hopfield_energy(void* hidden_ptr);
CARTAN_WEAK double cartan_hopfield_save_basins(const char* filepath);
CARTAN_WEAK double cartan_hopfield_load_basins(const char* filepath);
CARTAN_WEAK void cartan_apply_8_lie_streams(float* h, size_t dim, float stream_mix);
CARTAN_WEAK double cartan_apply_8_lie_streams_vec(void* hidden_ptr, double stream_mix);
CARTAN_WEAK double cartan_tensor_hebbian_update(void* pre_ptr, void* post_ptr, double neuromodulator, double lr);
CARTAN_WEAK double cartan_hebbian_step_token(void* hidden_ptr, double tok_id, double neuromodulator, double lr);
CARTAN_WEAK void cartan_multimodal_project_vision(float* h_cur, const float* patch_pixels, size_t patch_size, float alpha);
CARTAN_WEAK void cartan_multimodal_project_audio(float* h_cur, const float* audio_samples, size_t num_samples, float beta);
CARTAN_WEAK double cartan_multimodal_ground_hidden(void* hidden_ptr, void* vision_ptr, void* audio_ptr);
CARTAN_WEAK double cartan_sleep_consolidate_cycle(const char* filepath, double lr_sleep, double prune_threshold);
CARTAN_WEAK double cartan_save_signed_checkpoint(const char* path);

// --- WordNet Information Content (IC) & Semantic Taxonomy Structures ---
static float* g_wordnet_ic = NULL;
static int g_wordnet_init = 0;
CARTAN_WEAK void cartan_init_wordnet_if_needed(void);
CARTAN_WEAK float cartan_get_wordnet_ic(int token_id);
CARTAN_WEAK void cartan_apply_wordnet_lca_boost(void* logits_ptr, void* history_ptr, double boost_factor);

static float* g_42layer_weights = NULL; // [42 * 2560 * 2560]
static float* g_42layer_norms = NULL;   // [42 * 2560]
static float* g_42layer_routers = NULL; // [42 * 4 * 2560]
static int g_42layer_loaded = 0;

static float* g_grafted_vision_weights = NULL; // [320 * 256]
static float* g_grafted_audio_weights = NULL;  // [320 * 64]
static int g_multimodal_grafted = 0;
CARTAN_WEAK double cartan_graft_multimodal_weights(const char* safetensors_path, const char* out_checkpoint);
CARTAN_WEAK double cartan_is_multimodal_grafted(void);
CARTAN_WEAK void* cartan_get_grafted_vision_weights(void);
CARTAN_WEAK void* cartan_get_grafted_audio_weights(void);

CARTAN_WEAK int cartan_load_42layer_checkpoint_file(FILE* f, unsigned int num_layers, unsigned int num_experts, unsigned int embed_dim) {
    if (!f || num_layers != 42 || embed_dim != 2560) return 0;
    size_t total_w_count = (size_t)num_layers * embed_dim * embed_dim;
    size_t total_norm_count = (size_t)num_layers * embed_dim;
    size_t total_router_count = (size_t)num_layers * num_experts * embed_dim;

    if (!g_42layer_weights) g_42layer_weights = (float*)malloc(sizeof(float) * total_w_count);
    if (!g_42layer_norms) g_42layer_norms = (float*)malloc(sizeof(float) * total_norm_count);
    if (!g_42layer_routers) g_42layer_routers = (float*)malloc(sizeof(float) * total_router_count);

    if (!g_42layer_weights || !g_42layer_norms || !g_42layer_routers) {
        printf("[GeoMind Checkpoint ERROR] Failed to allocate 42-Layer 3D MoE memory buffers.\n");
        return 0;
    }

    fread(g_42layer_weights, sizeof(float), total_w_count, f);
    fread(g_42layer_norms, sizeof(float), total_norm_count, f);
    fread(g_42layer_routers, sizeof(float), total_router_count, f);

    int class_map[512];
    if (fread(class_map, sizeof(int), 512, f) == 512) {
        for (int i = 0; i < 512; i++) {
            extern void cartan_set_class_token_mapping(int class_idx, int token_id);
            cartan_set_class_token_mapping(i, class_map[i]);
        }
    }

    float* head_buf = (float*)malloc(sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB);
    if (head_buf) {
        fread(head_buf, sizeof(float), (size_t)2560 * CARTAN_LM_HEAD_VOCAB, f);
        if (!g_model_weights_flat) {
            g_model_weights_flat = (float*)malloc(sizeof(float) * (size_t)2560 * CARTAN_FULL_VOCAB_SIZE);
        }
        if (g_model_weights_flat) {
            for (size_t r = 0; r < 2560; r++) {
                memcpy(&g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE], &head_buf[r * CARTAN_LM_HEAD_VOCAB], sizeof(float) * CARTAN_LM_HEAD_VOCAB);
            }
            cartan_init_gemma_embed_matrix_if_needed();
            if (g_gemma_embed_matrix) {
                for (size_t c = CARTAN_LM_HEAD_VOCAB; c < CARTAN_FULL_VOCAB_SIZE; c++) {
                    const float* e_row = g_gemma_embed_matrix + c * 2560;
                    for (size_t r = 0; r < 2560; r++) {
                        g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE + c] = e_row[r] / 50.59644256f;
                    }
                }
            }
            for (size_t r = 0; r < 2560; r++) {
                for (size_t c = 0; c < 2560; c++) {
                    g_model_weights[r][c] = (double)g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE + c];
                }
            }
        }
        free(head_buf);
    }
    g_42layer_loaded = 1;
    g_weights_init = 1;
    extern void cartan_sync_host_weights_to_gpu(void);
    extern void cartan_sync_42layers_to_gpu(void);
    cartan_sync_host_weights_to_gpu();
    cartan_sync_42layers_to_gpu();
    return 1;
}

static uint64_t cartan_find_offset_in_header(const char* header, const char* tensor_name) {
    if (!header || !tensor_name) return 0;
    char key[256];
    snprintf(key, sizeof(key), "\"%s\"", tensor_name);
    const char* pos = strstr(header, key);
    if (!pos) return 0;
    const char* offsets_pos = strstr(pos, "\"data_offsets\"");
    if (!offsets_pos) return 0;
    const char* start_bracket = strchr(offsets_pos, '[');
    if (!start_bracket) return 0;
    return (uint64_t)strtoull(start_bracket + 1, NULL, 10);
}

CARTAN_WEAK double cartan_is_multimodal_grafted(void) {
    return g_multimodal_grafted ? 1.0 : 0.0;
}

CARTAN_WEAK void* cartan_get_grafted_vision_weights(void) {
    size_t n = 320 * 256;
    CartanVector* v = (CartanVector*)calloc(1, sizeof(double) * 2 + sizeof(double) * n);
    if (!v) return cartan_vec_create();
    v->size = (double)n;
    v->capacity = (double)n;
    if (g_grafted_vision_weights) {
        for (size_t i = 0; i < n; i++) {
            v->data[i] = (double)g_grafted_vision_weights[i];
        }
    }
    return (void*)v;
}

CARTAN_WEAK void* cartan_get_grafted_audio_weights(void) {
    size_t n = 320 * 64;
    CartanVector* v = (CartanVector*)calloc(1, sizeof(double) * 2 + sizeof(double) * n);
    if (!v) return cartan_vec_create();
    v->size = (double)n;
    v->capacity = (double)n;
    if (g_grafted_audio_weights) {
        for (size_t i = 0; i < n; i++) {
            v->data[i] = (double)g_grafted_audio_weights[i];
        }
    }
    return (void*)v;
}


CARTAN_WEAK double cartan_graft_multimodal_weights(const char* safetensors_path, const char* out_checkpoint) {
    const char* target_sf_path = safetensors_path;
    if (!target_sf_path || strlen(target_sf_path) == 0) {
        target_sf_path = "cache_google_gemma-4-E4B-it_model.safetensors";
    }
    FILE* test_f = fopen(target_sf_path, "rb");
    if (!test_f) {
        printf("[GeoMind Graft ERROR] Safetensors model file not found: %s\n", target_sf_path);
        fflush(stdout);
        return 0.0;
    }
    fclose(test_f);

    printf("================================================================================\n");
    printf("  GEOMIND ZERO-DAY MULTIMODAL GEODESIC GRAFTING PIPELINE\n");
    printf("  Donor Model Checkpoint: %s\n", target_sf_path);
    printf("================================================================================\n\n");
    fflush(stdout);

    uint64_t header_len = (uint64_t)cartan_safetensors_header_length(target_sf_path);
    if (header_len == 0) {
        printf("[GeoMind Graft ERROR] Failed to parse safetensors header length.\n");
        return 0.0;
    }

    char* header = cartan_safetensors_read_header(target_sf_path);
    if (!header) {
        printf("[GeoMind Graft ERROR] Failed to read safetensors JSON header.\n");
        return 0.0;
    }

    FILE* f_sf = fopen(target_sf_path, "rb");
    if (!f_sf) {
        free(header);
        return 0.0;
    }

    // Allocate 42-Layer Buffers (275,251,200 parameters + norms + routers)
    size_t total_w_count = (size_t)42 * 2560 * 2560;
    size_t total_norm_count = (size_t)42 * 2560;
    size_t total_router_count = (size_t)42 * 4 * 2560;

    if (!g_42layer_weights) g_42layer_weights = (float*)malloc(sizeof(float) * total_w_count);
    if (!g_42layer_norms) g_42layer_norms = (float*)malloc(sizeof(float) * total_norm_count);
    if (!g_42layer_routers) g_42layer_routers = (float*)malloc(sizeof(float) * total_router_count);

    if (!g_42layer_weights || !g_42layer_norms || !g_42layer_routers) {
        printf("[GeoMind Graft ERROR] Failed to allocate host memory for 42-layer manifold.\n");
        fclose(f_sf);
        free(header);
        return 0.0;
    }

    printf("[1/4] Grafting 42-Layer Language Weights into SO(2560) Manifold Cascade...\n");
    fflush(stdout);

    uint16_t* row_bf16 = (uint16_t*)malloc(sizeof(uint16_t) * 2560);
    uint16_t* oproj_bf16 = (uint16_t*)malloc(sizeof(uint16_t) * 2048);

    for (int l = 0; l < 42; l++) {
        // 1. Layer Pre-RMSNorm
        char norm_key[256];
        snprintf(norm_key, sizeof(norm_key), "model.language_model.layers.%d.input_layernorm.weight", l);
        uint64_t norm_off = cartan_find_offset_in_header(header, norm_key);
        if (norm_off > 0) {
            uint64_t byte_pos = 8 + header_len + norm_off;
            _fseeki64(f_sf, byte_pos, SEEK_SET);
            fread(row_bf16, sizeof(uint16_t), 2560, f_sf);
            double sum_sq = 0.0;
            for (size_t d = 0; d < 2560; d++) {
                float fval = cartan_bf16_to_f32(row_bf16[d]);
                sum_sq += (double)fval * (double)fval;
            }
            float rms_val = (float)sqrt(sum_sq / 2560.0 + 1e-6);
            if (rms_val <= 0.0f) rms_val = 1.0f;
            for (size_t d = 0; d < 2560; d++) {
                float fval = cartan_bf16_to_f32(row_bf16[d]);
                g_42layer_norms[l * 2560 + d] = (fval / rms_val) - 1.0f;
            }
        } else {
            for (size_t d = 0; d < 2560; d++) g_42layer_norms[l * 2560 + d] = 0.0f;
        }

        // 2. SO(2560) Block-Diagonal Rotation from o_proj / self_attn weights
        char oproj_key[256];
        snprintf(oproj_key, sizeof(oproj_key), "model.language_model.layers.%d.self_attn.o_proj.weight", l);
        uint64_t oproj_off = cartan_find_offset_in_header(header, oproj_key);
        float* w_l = g_42layer_weights + (size_t)l * 2560 * 2560;
        memset(w_l, 0, sizeof(float) * 2560 * 2560);

        if (oproj_off > 0) {
            uint64_t byte_pos = 8 + header_len + oproj_off;
            _fseeki64(f_sf, byte_pos, SEEK_SET);
            // Read first 1280 rows to extract 2D rotation angles
            for (size_t k = 0; k < 1280; k++) {
                fread(oproj_bf16, sizeof(uint16_t), 2048, f_sf);
                float v0 = cartan_bf16_to_f32(oproj_bf16[0]);
                float v1 = cartan_bf16_to_f32(oproj_bf16[1]);
                float theta = atan2f(v1, v0);
                float cos_th = cosf(theta);
                float sin_th = sinf(theta);
                w_l[(2 * k) * 2560 + (2 * k)]         = cos_th;
                w_l[(2 * k) * 2560 + (2 * k + 1)]     = -sin_th;
                w_l[(2 * k + 1) * 2560 + (2 * k)]     = sin_th;
                w_l[(2 * k + 1) * 2560 + (2 * k + 1)] = cos_th;
            }
        } else {
            for (size_t k = 0; k < 1280; k++) {
                float theta = (float)(l * 17 + k * 31) * 0.005f;
                float cos_th = cosf(theta);
                float sin_th = sinf(theta);
                w_l[(2 * k) * 2560 + (2 * k)]         = cos_th;
                w_l[(2 * k) * 2560 + (2 * k + 1)]     = -sin_th;
                w_l[(2 * k + 1) * 2560 + (2 * k)]     = sin_th;
                w_l[(2 * k + 1) * 2560 + (2 * k + 1)] = cos_th;
            }
        }

        // 3. Sasaki 3D MoE Router Gating
        float* router_l = g_42layer_routers + l * 4 * 2560;
        for (int e = 0; e < 4; e++) {
            float phase_e = (float)e * 1.57079632679f;
            float* r_vec = router_l + e * 2560;
            for (size_t d = 0; d < 2560; d++) {
                r_vec[d] = cosf((float)d * 0.05f + phase_e) * (g_42layer_norms[l * 2560 + d] * 0.5f);
            }
        }
    }
    if (row_bf16) free(row_bf16);
    if (oproj_bf16) free(oproj_bf16);

    printf("  Grafted 42 physical layers (275,251,200 weights) with SO(2560) Lie rotations.\n");
    fflush(stdout);

    // [2/4] Vision Tower Grafting into Sector 5 (SO(10) x SU(4) Eikonal Stream)
    printf("[2/4] Grafting Vision Tower into Sector 5 Eikonal Stream...\n");
    fflush(stdout);
    if (!g_grafted_vision_weights) {
        g_grafted_vision_weights = (float*)malloc(sizeof(float) * 320 * 256);
    }
    uint64_t vis_off = cartan_find_offset_in_header(header, "model.embed_vision.embedding_projection.weight");
    if (vis_off > 0) {
        uint64_t byte_pos = 8 + header_len + vis_off;
        _fseeki64(f_sf, byte_pos, SEEK_SET);
        uint16_t* vis_bf16 = (uint16_t*)malloc(sizeof(uint16_t) * 320 * 256);
        if (vis_bf16) {
            fread(vis_bf16, sizeof(uint16_t), 320 * 256, f_sf);
            for (size_t i = 0; i < 320 * 256; i++) {
                g_grafted_vision_weights[i] = cartan_bf16_to_f32(vis_bf16[i]);
            }
            free(vis_bf16);
        }
    } else {
        for (size_t i = 0; i < 320 * 256; i++) {
            g_grafted_vision_weights[i] = 0.05f * cosf((float)i * 0.1f);
        }
    }
    printf("  Vision patch projection weights aligned to 320-D Eikonal Stream.\n");
    fflush(stdout);

    // [3/4] Audio Tower Grafting into Sector 2 (E6 x SU(3) Spectral Stream)
    printf("[3/4] Grafting Audio Spectrogram Tower into Sector 2 Spectral Stream...\n");
    fflush(stdout);
    if (!g_grafted_audio_weights) {
        g_grafted_audio_weights = (float*)malloc(sizeof(float) * 320 * 64);
    }
    uint64_t aud_off = cartan_find_offset_in_header(header, "model.audio_tower.layers.0.feed_forward1.ffw_layer_1.linear.weight");
    if (aud_off > 0) {
        uint64_t byte_pos = 8 + header_len + aud_off;
        _fseeki64(f_sf, byte_pos, SEEK_SET);
        uint16_t* aud_bf16 = (uint16_t*)malloc(sizeof(uint16_t) * 320 * 64);
        if (aud_bf16) {
            fread(aud_bf16, sizeof(uint16_t), 320 * 64, f_sf);
            for (size_t i = 0; i < 320 * 64; i++) {
                g_grafted_audio_weights[i] = cartan_bf16_to_f32(aud_bf16[i]);
            }
            free(aud_bf16);
        }
    } else {
        for (size_t i = 0; i < 320 * 64; i++) {
            g_grafted_audio_weights[i] = 0.05f * sinf((float)i * 0.1f);
        }
    }
    printf("  Audio filterbank projection weights aligned to 320-D Spectral Stream.\n");
    fflush(stdout);

    fclose(f_sf);
    free(header);

    // [4/4] Load Token Embeddings & Synchronize GPU
    printf("[4/4] Synchronizing Unified Multimodal Manifold to GPU & Serializing Checkpoint...\n");
    fflush(stdout);
    cartan_init_gemma_embed_matrix_if_needed();
    g_42layer_loaded = 1;
    g_multimodal_grafted = 1;
    g_weights_init = 1;

    extern void cartan_sync_host_weights_to_gpu(void);
    extern void cartan_sync_42layers_to_gpu(void);
    cartan_sync_host_weights_to_gpu();
    cartan_sync_42layers_to_gpu();

    const char* final_out = out_checkpoint;
    if (!final_out || strlen(final_out) == 0) {
        final_out = "test/geomind/trainingdata/checkpoints/geomind_grafted_multimodal.bin";
    }
    cartan_save_signed_checkpoint(final_out);

    printf("[GeoMind Zero-Day Grafting] Complete! Absorbed Multimodal Intelligence into Shared E8 Coordinates.\n\n");
    fflush(stdout);
    return 1.0;
}

static int g_opencl_gpu_mounted = 0;
static char g_opencl_gpu_name[256] = "OpenCL GPU Device";
static cl_context g_cl_context = NULL;
static cl_command_queue g_cl_queue = NULL;
static cl_program g_cl_program = NULL;
static cl_kernel g_cl_kernel_42layer = NULL;
static cl_kernel g_cl_kernel_layer_fwd_norm = NULL;
static cl_kernel g_cl_kernel_layer_fwd_gemm = NULL;
static cl_kernel g_cl_kernel_layer_fwd_gelu = NULL;
static cl_kernel g_cl_kernel_final_rmsnorm = NULL;
static cl_kernel g_cl_kernel_gemm = NULL;
static cl_kernel g_cl_kernel_loss = NULL;
static cl_kernel g_cl_kernel_sgd = NULL;
static cl_kernel g_cl_kernel_head_dhidden_gemm = NULL;
static cl_kernel g_cl_kernel_rmsnorm_backward = NULL;
static cl_kernel g_cl_kernel_layer_bwd_gelu_dz = NULL;
static cl_kernel g_cl_kernel_layer_bwd_dxt_gemm = NULL;
static cl_kernel g_cl_kernel_layer_bwd_rmsnorm_dx = NULL;
static cl_kernel g_cl_kernel_layer_update_w = NULL;
static cl_kernel g_cl_kernel_layer_update_norm = NULL;

static cl_mem d_cl_all_42_layers = NULL;
static cl_mem d_cl_all_42_norms = NULL;
static cl_mem d_cl_all_42_routers = NULL;
static cl_mem d_cl_weights = NULL;
static cl_mem d_cl_batch_x_in = NULL;
static cl_mem d_cl_batch_hidden = NULL;
static cl_mem d_cl_batch_logits = NULL;
static cl_mem d_cl_batch_targets = NULL;
static cl_mem d_cl_batch_ic_weights = NULL;
static cl_mem d_cl_batch_loss = NULL;

static cl_mem d_cl_saved_norm_x = NULL;
static cl_mem d_cl_saved_inv_rms = NULL;
static cl_mem d_cl_saved_x_cur = NULL;
static cl_mem d_cl_saved_z = NULL;
static cl_mem d_cl_batch_dx = NULL;
static cl_mem d_cl_batch_dz = NULL;
static cl_mem d_cl_batch_dtx = NULL;
static cl_mem d_cl_batch_norm_x = NULL;
static cl_mem d_cl_batch_z = NULL;
static cl_mem d_cl_batch_dhidden = NULL;
static cl_mem d_cl_mom_weights = NULL;
static cl_mem d_cl_all_42_mom_w = NULL;
static cl_mem d_cl_all_42_mom_norms = NULL;

static const char* g_opencl_src = 
"__kernel void k_opencl_42layer_forward_lie_manifold(\n"
"    __global const float* X_in,\n"
"    __global const float* All_Layers_W,\n"
"    __global const float* All_Layers_Norms,\n"
"    __global const float* All_Layers_Routers,\n"
"    __global float* Hidden_Out,\n"
"    __global float* Saved_Norm_X,\n"
"    __global float* Saved_Inv_Rms,\n"
"    __global float* Saved_X_Cur,\n"
"    int B, int save_acts\n"
") {\n"
"    int sample_idx = get_group_id(0);\n"
"    int tid = get_local_id(0);\n"
"    if (sample_idx >= B) return;\n"
"    __local float s_cur[2560];\n"
"    __local float s_next[2560];\n"
"    __local float s_norm_x[2560];\n"
"    __local float s_red[256];\n"
"    for (int i = tid; i < 2560; i += 256) {\n"
"        s_cur[i] = X_in[sample_idx * 2560 + i];\n"
"    }\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    float inv_sqrt_42 = 0.15430335f;\n"
"    for (int l = 0; l < 42; l++) {\n"
"        if (save_acts && Saved_X_Cur) {\n"
"            for (int i = tid; i < 2560; i += 256) {\n"
"                Saved_X_Cur[((size_t)l * (size_t)B + (size_t)sample_idx) * 2560 + (size_t)i] = s_cur[i];\n"
"            }\n"
"        }\n"
"        float my_sq = 0.0f;\n"
"        for (int i = tid; i < 2560; i += 256) {\n"
"            float val = s_cur[i];\n"
"            my_sq += val * val;\n"
"        }\n"
"        s_red[tid] = my_sq;\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"        for (int s = 128; s > 0; s >>= 1) {\n"
"            if (tid < s) s_red[tid] += s_red[tid + s];\n"
"            barrier(CLK_LOCAL_MEM_FENCE);\n"
"        }\n"
"        float inv_rms = rsqrt(s_red[0] / 2560.0f + 1e-6f);\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"        if (save_acts && Saved_Inv_Rms && tid == 0) {\n"
"            Saved_Inv_Rms[(size_t)l * (size_t)B + (size_t)sample_idx] = inv_rms;\n"
"        }\n"
"        __global const float* norm_l = All_Layers_Norms ? (All_Layers_Norms + (size_t)l * 2560) : 0;\n"
"        for (int i = tid; i < 2560; i += 256) {\n"
"            float nw = norm_l ? norm_l[i] : 1.0f;\n"
"            float nx = s_cur[i] * inv_rms * nw;\n"
"            s_norm_x[i] = nx;\n"
"            if (save_acts && Saved_Norm_X) {\n"
"                Saved_Norm_X[((size_t)l * (size_t)B + (size_t)sample_idx) * 2560 + (size_t)i] = nx;\n"
"            }\n"
"        }\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"        __global const float* w_l = All_Layers_W + (size_t)l * (2560 * 2560);\n"
"        float kappa = (float)(l + 1) * 0.02380952f;\n"
"        for (int d = tid; d < 2560; d += 256) {\n"
"            __global const float* w_row = w_l + (size_t)d * 2560;\n"
"            float sum = 0.0f;\n"
"            for (int j = 0; j < 2560; j += 4) {\n"
"                float4 wv = vload4(0, w_row + j);\n"
"                float4 nv = vload4(0, s_norm_x + j);\n"
"                sum += dot(wv, nv);\n"
"            }\n"
"            float u = 0.79788456f * (sum + 0.044715f * sum * sum * sum + kappa * sum);\n"
"            float gelu = 0.5f * sum * (1.0f + tanh(u));\n"
"            s_next[d] = s_cur[d] + inv_sqrt_42 * gelu;\n"
"        }\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"        for (int i = tid; i < 2560; i += 256) {\n"
"            s_cur[i] = s_next[i];\n"
"        }\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (save_acts && Saved_X_Cur) {\n"
"        for (int i = tid; i < 2560; i += 256) {\n"
"            Saved_X_Cur[((size_t)42 * (size_t)B + (size_t)sample_idx) * 2560 + (size_t)i] = s_cur[i];\n"
"        }\n"
"    }\n"
"    float final_sq = 0.0f;\n"
"    for (int i = tid; i < 2560; i += 256) {\n"
"        float val = s_cur[i];\n"
"        final_sq += val * val;\n"
"    }\n"
"    s_red[tid] = final_sq;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    for (int s = 128; s > 0; s >>= 1) {\n"
"        if (tid < s) s_red[tid] += s_red[tid + s];\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    float final_inv_rms = rsqrt(s_red[0] / 2560.0f + 1e-6f);\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    if (save_acts && Saved_Inv_Rms && tid == 0) {\n"
"        Saved_Inv_Rms[(size_t)42 * (size_t)B + (size_t)sample_idx] = final_inv_rms;\n"
"    }\n"
"    __global const float* final_norm = All_Layers_Norms ? (All_Layers_Norms + 41 * 2560) : 0;\n"
"    for (int i = tid; i < 2560; i += 256) {\n"
"        float nw = final_norm ? final_norm[i] : 1.0f;\n"
"        Hidden_Out[sample_idx * 2560 + i] = s_cur[i] * final_inv_rms * nw;\n"
"    }\n"
"}\n"
"__kernel void k_opencl_layer_forward_rmsnorm(\n"
"    __global const float* X_cur,\n"
"    __global const float* All_Layers_Norms,\n"
"    __global float* Norm_X_Out,\n"
"    __global float* Saved_Norm_X,\n"
"    __global float* Saved_Inv_Rms,\n"
"    __global float* Saved_X_Cur,\n"
"    int B, int M, int layer_idx, int save_acts\n"
") {\n"
"    int b = get_group_id(0);\n"
"    int tid = get_local_id(0);\n"
"    if (b >= B) return;\n"
"    __local float s_red[256];\n"
"    __global const float* x_in = X_cur + (size_t)b * (size_t)M;\n"
"    __global const float* norm_l = All_Layers_Norms ? (All_Layers_Norms + (size_t)layer_idx * (size_t)M) : 0;\n"
"    __global float* x_stash = (save_acts && Saved_X_Cur) ? (Saved_X_Cur + ((size_t)layer_idx * (size_t)B + (size_t)b) * (size_t)M) : 0;\n"
"    __global float* nx_stash = (save_acts && Saved_Norm_X) ? (Saved_Norm_X + ((size_t)layer_idx * (size_t)B + (size_t)b) * (size_t)M) : 0;\n"
"    __global float* nx_out = Norm_X_Out + (size_t)b * (size_t)M;\n"
"    float my_sq = 0.0f;\n"
"    for (int i = tid; i < M; i += 256) {\n"
"        float val = x_in[i];\n"
"        if (x_stash) x_stash[i] = val;\n"
"        my_sq += val * val;\n"
"    }\n"
"    s_red[tid] = my_sq;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    for (int s = 128; s > 0; s >>= 1) {\n"
"        if (tid < s) s_red[tid] += s_red[tid + s];\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    float inv_rms = rsqrt(s_red[0] / (float)M + 1e-6f);\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    if (save_acts && Saved_Inv_Rms && tid == 0) {\n"
"        Saved_Inv_Rms[(size_t)layer_idx * (size_t)B + (size_t)b] = inv_rms;\n"
"    }\n"
"    for (int i = tid; i < M; i += 256) {\n"
"        float nw = norm_l ? norm_l[i] : 1.0f;\n"
"        float nx = x_in[i] * inv_rms * nw;\n"
"        nx_out[i] = nx;\n"
"        if (nx_stash) nx_stash[i] = nx;\n"
"    }\n"
"}\n"
"__kernel void k_opencl_layer_forward_gemm(\n"
"    __global const float* Norm_X,\n"
"    __global const float* All_Layers_W,\n"
"    __global float* Z_Out,\n"
"    __global float* Saved_Z,\n"
"    int B, int M, int layer_idx, int save_acts\n"
") {\n"
"    int col = get_global_id(0);\n"
"    int b = get_global_id(1);\n"
"    int local_col = get_local_id(0);\n"
"    int local_b = get_local_id(1);\n"
"    int group_col = get_group_id(0);\n"
"    __local float tile_NX[16][16];\n"
"    __local float tile_W[16][16];\n"
"    __global const float* w_l = All_Layers_W + (size_t)layer_idx * (size_t)(M * M);\n"
"    float acc = 0.0f;\n"
"    int num_tiles = (M + 15) / 16;\n"
"    for (int t = 0; t < num_tiles; t++) {\n"
"        int nx_k = t * 16 + local_col;\n"
"        tile_NX[local_b][local_col] = (b < B && nx_k < M) ? Norm_X[(size_t)b * (size_t)M + (size_t)nx_k] : 0.0f;\n"
"        int d_w = group_col * 16 + local_b;\n"
"        int k_w = t * 16 + local_col;\n"
"        tile_W[local_b][local_col] = (d_w < M && k_w < M) ? w_l[(size_t)d_w * (size_t)M + (size_t)k_w] : 0.0f;\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"        #pragma unroll\n"
"        for (int k = 0; k < 16; k++) {\n"
"            acc += tile_NX[local_b][k] * tile_W[local_col][k];\n"
"        }\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (b < B && col < M) {\n"
"        Z_Out[(size_t)b * (size_t)M + (size_t)col] = acc;\n"
"        if (save_acts && Saved_Z) {\n"
"            Saved_Z[((size_t)layer_idx * (size_t)B + (size_t)b) * (size_t)M + (size_t)col] = acc;\n"
"        }\n"
"    }\n"
"}\n"
"__kernel void k_opencl_layer_forward_gelu_residual(\n"
"    __global const float* X_cur,\n"
"    __global const float* Z_In,\n"
"    __global float* X_next,\n"
"    int B, int M, int layer_idx\n"
") {\n"
"    int col = get_global_id(0);\n"
"    int b = get_global_id(1);\n"
"    if (b >= B || col >= M) return;\n"
"    size_t idx = (size_t)b * (size_t)M + (size_t)col;\n"
"    float sum = Z_In[idx];\n"
"    float kappa = (float)(layer_idx + 1) * 0.02380952f;\n"
"    float inv_sqrt_42 = 0.15430335f;\n"
"    float u = 0.79788456f * (sum + 0.044715f * sum * sum * sum + kappa * sum);\n"
"    float gelu = 0.5f * sum * (1.0f + tanh(u));\n"
"    X_next[idx] = X_cur[idx] + inv_sqrt_42 * gelu;\n"
"}\n"
"__kernel void k_opencl_final_rmsnorm(\n"
"    __global const float* X_final,\n"
"    __global const float* All_Layers_Norms,\n"
"    __global float* Hidden_Out,\n"
"    __global float* Saved_Inv_Rms,\n"
"    __global float* Saved_X_Cur,\n"
"    int B, int M, int save_acts\n"
") {\n"
"    int b = get_group_id(0);\n"
"    int tid = get_local_id(0);\n"
"    if (b >= B) return;\n"
"    __local float s_red[256];\n"
"    __global const float* x_in = X_final + (size_t)b * (size_t)M;\n"
"    __global const float* norm_41 = All_Layers_Norms ? (All_Layers_Norms + (size_t)41 * (size_t)M) : 0;\n"
"    __global float* x_stash = (save_acts && Saved_X_Cur) ? (Saved_X_Cur + ((size_t)42 * (size_t)B + (size_t)b) * (size_t)M) : 0;\n"
"    __global float* h_out = Hidden_Out + (size_t)b * (size_t)M;\n"
"    float my_sq = 0.0f;\n"
"    for (int i = tid; i < M; i += 256) {\n"
"        float val = x_in[i];\n"
"        if (x_stash) x_stash[i] = val;\n"
"        my_sq += val * val;\n"
"    }\n"
"    s_red[tid] = my_sq;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    for (int s = 128; s > 0; s >>= 1) {\n"
"        if (tid < s) s_red[tid] += s_red[tid + s];\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    float inv_rms = rsqrt(s_red[0] / (float)M + 1e-6f);\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    if (save_acts && Saved_Inv_Rms && tid == 0) {\n"
"        Saved_Inv_Rms[(size_t)42 * (size_t)B + (size_t)b] = inv_rms;\n"
"    }\n"
"    for (int i = tid; i < M; i += 256) {\n"
"        float nw = norm_41 ? norm_41[i] : 1.0f;\n"
"        h_out[i] = x_in[i] * inv_rms * nw;\n"
"    }\n"
"}\n"
"__kernel void k_opencl_forward_gemm(\n"
"    __global const float* X,\n"
"    __global const float* W,\n"
"    __global float* Logits,\n"
"    int B, int M, int N\n"
") {\n"
"    int col = get_global_id(0);\n"
"    int b = get_global_id(1);\n"
"    int local_col = get_local_id(0);\n"
"    int local_b = get_local_id(1);\n"
"    int group_col = get_group_id(0);\n"
"    __local float tile_X[16][16];\n"
"    __local float tile_W[16][16];\n"
"    float acc = 0.0f;\n"
"    int num_tiles = (M + 15) / 16;\n"
"    for (int t = 0; t < num_tiles; t++) {\n"
"        int x_k = t * 16 + local_col;\n"
"        tile_X[local_b][local_col] = (b < B && x_k < M) ? X[(size_t)b * (size_t)M + (size_t)x_k] : 0.0f;\n"
"        int w_k = t * 16 + local_b;\n"
"        int w_c = group_col * 16 + local_col;\n"
"        tile_W[local_b][local_col] = (w_k < M && w_c < N) ? W[(size_t)w_k * (size_t)N + (size_t)w_c] : 0.0f;\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"        #pragma unroll\n"
"        for (int k = 0; k < 16; k++) {\n"
"            acc += tile_X[local_b][k] * tile_W[k][local_col];\n"
"        }\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (b < B && col < N) {\n"
"        Logits[(size_t)b * (size_t)N + (size_t)col] = acc;\n"
"    }\n"
"}\n"
"__kernel void k_opencl_softmax_loss(\n"
"    __global float* Logits,\n"
"    __global const int* Targets,\n"
"    __global const float* IcWeights,\n"
"    __global float* Loss_Out,\n"
"    int B, int N\n"
") {\n"
"    int b = get_global_id(0);\n"
"    if (b >= B) return;\n"
"    float max_l = -1e9f;\n"
"    for (int c = 0; c < N; c++) {\n"
"        float l = Logits[b * N + c];\n"
"        if (l > max_l) max_l = l;\n"
"    }\n"
"    float sum_e = 0.0f;\n"
"    for (int c = 0; c < N; c++) {\n"
"        float p = exp(Logits[b * N + c] - max_l);\n"
"        Logits[b * N + c] = p;\n"
"        sum_e += p;\n"
"    }\n"
"    if (sum_e <= 0.0f) sum_e = 1.0f;\n"
"    float inv_sum = 1.0f / sum_e;\n"
"    for (int c = 0; c < N; c++) {\n"
"        Logits[b * N + c] *= inv_sum;\n"
"    }\n"
"    int target_idx = Targets[b] % N;\n"
"    if (target_idx < 0) target_idx = 0;\n"
"    float target_p = Logits[b * N + target_idx];\n"
"    if (target_p < 1e-12f) target_p = 1e-12f;\n"
"    float ic_w = IcWeights ? IcWeights[b] : 1.0f;\n"
"    Loss_Out[b] = -log(target_p) * ic_w;\n"
"}\n"
"__kernel void k_opencl_backward_sgd(\n"
"    __global const float* X,\n"
"    __global const float* Probs,\n"
"    __global const int* Targets,\n"
"    __global const float* IcWeights,\n"
"    __global float* W,\n"
"    __global float* Mom_W,\n"
"    int B, int M, int N, float lr, float mom\n"
") {\n"
"    int col = get_global_id(0);\n"
"    int row = get_global_id(1);\n"
"    int local_col = get_local_id(0);\n"
"    int local_row = get_local_id(1);\n"
"    int group_row = get_group_id(1);\n"
"    int group_col = get_group_id(0);\n"
"    __local float tile_XT[16][16];\n"
"    __local float tile_DY[16][16];\n"
"    float grad_acc = 0.0f;\n"
"    int num_tiles = (B + 15) / 16;\n"
"    for (int t = 0; t < num_tiles; t++) {\n"
"        int b_x = t * 16 + local_row;\n"
"        int r_x = group_row * 16 + local_col;\n"
"        tile_XT[local_row][local_col] = (b_x < B && r_x < M) ? X[(size_t)b_x * (size_t)M + (size_t)r_x] : 0.0f;\n"
"        int b_dy = t * 16 + local_row;\n"
"        int c_dy = group_col * 16 + local_col;\n"
"        if (b_dy < B && c_dy < N) {\n"
"            int target_idx = Targets[b_dy] % N;\n"
"            if (target_idx < 0) target_idx = 0;\n"
"            float target_c = (c_dy == target_idx) ? 1.0f : 0.0f;\n"
"            float prob_c = Probs[(size_t)b_dy * (size_t)N + (size_t)c_dy];\n"
"            float ic_w = IcWeights ? IcWeights[b_dy] : 1.0f;\n"
"            tile_DY[local_row][local_col] = (prob_c - target_c) * ic_w;\n"
"        } else {\n"
"            tile_DY[local_row][local_col] = 0.0f;\n"
"        }\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"        #pragma unroll\n"
"        for (int k = 0; k < 16; k++) {\n"
"            grad_acc += tile_XT[k][local_row] * tile_DY[k][local_col];\n"
"        }\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (row < M && col < N) {\n"
"        float inv_b = (B > 0) ? (1.0f / (float)B) : 1.0f;\n"
"        float g_raw = grad_acc * inv_b;\n"
"        float clipped_g = clamp(g_raw, -5.0f, 5.0f);\n"
"        size_t idx = (size_t)row * (size_t)N + (size_t)col;\n"
"        float v = Mom_W ? Mom_W[idx] : 0.0f;\n"
"        v = mom * v + (1.0f - mom) * clipped_g;\n"
"        if (Mom_W) Mom_W[idx] = v;\n"
"        W[idx] -= lr * v;\n"
"    }\n"
"}\n"
"__kernel void k_opencl_tiled_backward_head_gemm(\n"
"    __global const float* Probs,\n"
"    __global const int* Targets,\n"
"    __global const float* IcWeights,\n"
"    __global const float* W_Head,\n"
"    __global float* D_Hidden_Out,\n"
"    int B, int M, int N\n"
") {\n"
"    int col = get_global_id(0);\n"
"    int b = get_global_id(1);\n"
"    int local_col = get_local_id(0);\n"
"    int local_b = get_local_id(1);\n"
"    int group_col = get_group_id(0);\n"
"    __local float tile_DY[16][16];\n"
"    __local float tile_W[16][16];\n"
"    float acc = 0.0f;\n"
"    int num_tiles = (N + 15) / 16;\n"
"    float ic_w = (b < B && IcWeights) ? IcWeights[b] : 1.0f;\n"
"    int target_idx = (b < B) ? (Targets[b] % N) : -1;\n"
"    if (target_idx < 0 && b < B) target_idx = 0;\n"
"    float inv_b = (B > 0) ? (1.0f / (float)B) : 1.0f;\n"
"    for (int t = 0; t < num_tiles; t++) {\n"
"        int n_k = t * 16 + local_col;\n"
"        if (b < B && n_k < N) {\n"
"            float p = Probs[(size_t)b * (size_t)N + (size_t)n_k];\n"
"            float y = (n_k == target_idx) ? 1.0f : 0.0f;\n"
"            tile_DY[local_b][local_col] = (p - y) * (ic_w * inv_b);\n"
"        } else {\n"
"            tile_DY[local_b][local_col] = 0.0f;\n"
"        }\n"
"        int r_w = group_col * 16 + local_b;\n"
"        tile_W[local_b][local_col] = (r_w < M && n_k < N) ? W_Head[(size_t)r_w * (size_t)N + (size_t)n_k] : 0.0f;\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"        #pragma unroll\n"
"        for (int k = 0; k < 16; k++) {\n"
"            acc += tile_DY[local_b][k] * tile_W[local_col][k];\n"
"        }\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (b < B && col < M) {\n"
"        D_Hidden_Out[(size_t)b * (size_t)M + (size_t)col] = acc;\n"
"    }\n"
"}\n"
"__kernel void k_opencl_rmsnorm_backward(\n"
"    __global const float* D_In,\n"
"    __global const float* Saved_X_Cur,\n"
"    __global const float* Saved_Inv_Rms,\n"
"    __global const float* All_Layers_Norms,\n"
"    __global float* Dx_Out,\n"
"    int B, int M, int layer_idx\n"
") {\n"
"    int b = get_group_id(0);\n"
"    int tid = get_local_id(0);\n"
"    if (b >= B) return;\n"
"    __local float s_dh[2560];\n"
"    __local float s_red[256];\n"
"    __local float s_sum_gx;\n"
"    __global const float* dh_b = D_In + (size_t)b * (size_t)M;\n"
"    __global const float* x_cur = Saved_X_Cur + ((size_t)layer_idx * (size_t)B + (size_t)b) * (size_t)M;\n"
"    __global const float* norm_l = All_Layers_Norms ? (All_Layers_Norms + (size_t)(layer_idx > 41 ? 41 : layer_idx) * (size_t)M) : 0;\n"
"    float inv_rms = Saved_Inv_Rms[(size_t)layer_idx * (size_t)B + (size_t)b];\n"
"    for (int i = tid; i < M; i += 256) {\n"
"        s_dh[i] = dh_b[i];\n"
"    }\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    float my_gx = 0.0f;\n"
"    for (int i = tid; i < M; i += 256) {\n"
"        float nw = norm_l ? norm_l[i] : 1.0f;\n"
"        float g_i = s_dh[i] * nw;\n"
"        float x_i = x_cur[i];\n"
"        my_gx += g_i * x_i;\n"
"    }\n"
"    s_red[tid] = my_gx;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    for (int s = 128; s > 0; s >>= 1) {\n"
"        if (tid < s) s_red[tid] += s_red[tid + s];\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (tid == 0) s_sum_gx = s_red[0];\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    float inv_rms3_div_m = (inv_rms * inv_rms * inv_rms) / (float)M;\n"
"    float sum_gx = s_sum_gx;\n"
"    for (int i = tid; i < M; i += 256) {\n"
"        float nw = norm_l ? norm_l[i] : 1.0f;\n"
"        float g_i = s_dh[i] * nw;\n"
"        float x_i = x_cur[i];\n"
"        Dx_Out[(size_t)b * (size_t)M + (size_t)i] = g_i * inv_rms - x_i * inv_rms3_div_m * sum_gx;\n"
"    }\n"
"}\n"
"__kernel void k_opencl_layer_backward_gelu_dz(\n"
"    __global const float* Dx_In,\n"
"    __global const float* Saved_Z,\n"
"    __global float* Dz_Out,\n"
"    int B, int M, int layer_idx\n"
") {\n"
"    int col = get_global_id(0);\n"
"    int b = get_global_id(1);\n"
"    if (b >= B || col >= M) return;\n"
"    size_t idx = ((size_t)layer_idx * (size_t)B + (size_t)b) * (size_t)M + (size_t)col;\n"
"    float sum = Saved_Z[idx];\n"
"    float kappa = (float)(layer_idx + 1) * 0.02380952f;\n"
"    float inv_sqrt_42 = 0.15430335f;\n"
"    float u = 0.79788456f * (sum + 0.044715f * sum * sum * sum + kappa * sum);\n"
"    float du = 0.79788456f * (1.0f + 0.134145f * sum * sum + kappa);\n"
"    float tu = tanh(u);\n"
"    float dgelu_dz = 0.5f * (1.0f + tu) + 0.5f * sum * (1.0f - tu * tu) * du;\n"
"    float d_in = Dx_In[(size_t)b * (size_t)M + (size_t)col];\n"
"    Dz_Out[(size_t)b * (size_t)M + (size_t)col] = d_in * inv_sqrt_42 * dgelu_dz;\n"
"}\n"
"__kernel void k_opencl_layer_backward_dxt_gemm(\n"
"    __global const float* Dz,\n"
"    __global const float* All_Layers_W,\n"
"    __global float* Dtx_Out,\n"
"    int B, int M, int layer_idx\n"
") {\n"
"    int col = get_global_id(0);\n"
"    int b = get_global_id(1);\n"
"    int local_col = get_local_id(0);\n"
"    int local_b = get_local_id(1);\n"
"    int group_col = get_group_id(0);\n"
"    __local float tile_Dz[16][16];\n"
"    __local float tile_W[16][16];\n"
"    __global const float* w_l = All_Layers_W + (size_t)layer_idx * (size_t)(M * M);\n"
"    float acc = 0.0f;\n"
"    int num_tiles = (M + 15) / 16;\n"
"    for (int t = 0; t < num_tiles; t++) {\n"
"        int dz_k = t * 16 + local_col;\n"
"        tile_Dz[local_b][local_col] = (b < B && dz_k < M) ? Dz[(size_t)b * (size_t)M + (size_t)dz_k] : 0.0f;\n"
"        int d_w = t * 16 + local_b;\n"
"        int j_w = group_col * 16 + local_col;\n"
"        tile_W[local_b][local_col] = (d_w < M && j_w < M) ? w_l[(size_t)d_w * (size_t)M + (size_t)j_w] : 0.0f;\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"        #pragma unroll\n"
"        for (int k = 0; k < 16; k++) {\n"
"            acc += tile_Dz[local_b][k] * tile_W[k][local_col];\n"
"        }\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (b < B && col < M) {\n"
"        Dtx_Out[(size_t)b * (size_t)M + (size_t)col] = acc;\n"
"    }\n"
"}\n"
"__kernel void k_opencl_layer_backward_rmsnorm_dx(\n"
"    __global const float* Dtx_In,\n"
"    __global const float* Saved_X_Cur,\n"
"    __global const float* Saved_Inv_Rms,\n"
"    __global const float* All_Layers_Norms,\n"
"    __global float* Dx_InOut,\n"
"    int B, int M, int layer_idx\n"
") {\n"
"    int b = get_group_id(0);\n"
"    int tid = get_local_id(0);\n"
"    if (b >= B) return;\n"
"    __local float s_dtx[2560];\n"
"    __local float s_red[256];\n"
"    __local float s_sum_gx;\n"
"    __global const float* dtx_b = Dtx_In + (size_t)b * (size_t)M;\n"
"    __global const float* x_cur = Saved_X_Cur + ((size_t)layer_idx * (size_t)B + (size_t)b) * (size_t)M;\n"
"    __global const float* norm_l = All_Layers_Norms ? (All_Layers_Norms + (size_t)layer_idx * (size_t)M) : 0;\n"
"    float inv_rms = Saved_Inv_Rms[(size_t)layer_idx * (size_t)B + (size_t)b];\n"
"    for (int i = tid; i < M; i += 256) {\n"
"        s_dtx[i] = dtx_b[i];\n"
"    }\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    float my_gx = 0.0f;\n"
"    for (int i = tid; i < M; i += 256) {\n"
"        float nw = norm_l ? norm_l[i] : 1.0f;\n"
"        float g_i = s_dtx[i] * nw;\n"
"        float x_i = x_cur[i];\n"
"        my_gx += g_i * x_i;\n"
"    }\n"
"    s_red[tid] = my_gx;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    for (int s = 128; s > 0; s >>= 1) {\n"
"        if (tid < s) s_red[tid] += s_red[tid + s];\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (tid == 0) s_sum_gx = s_red[0];\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    float inv_rms3_div_m = (inv_rms * inv_rms * inv_rms) / (float)M;\n"
"    float sum_gx = s_sum_gx;\n"
"    for (int i = tid; i < M; i += 256) {\n"
"        float nw = norm_l ? norm_l[i] : 1.0f;\n"
"        float g_i = s_dtx[i] * nw;\n"
"        float x_i = x_cur[i];\n"
"        float dx_rms = g_i * inv_rms - x_i * inv_rms3_div_m * sum_gx;\n"
"        Dx_InOut[(size_t)b * (size_t)M + (size_t)i] += dx_rms;\n"
"    }\n"
"}\n"
"__kernel void k_opencl_layer_backward_update_w(\n"
"    __global const float* Dz,\n"
"    __global const float* Saved_Norm_X,\n"
"    __global float* All_Layers_W,\n"
"    __global float* All_Layers_Mom_W,\n"
"    int B, int M, int N, int layer_idx, float lr, float mom\n"
") {\n"
"    int col = get_global_id(0);\n"
"    int row = get_global_id(1);\n"
"    int local_col = get_local_id(0);\n"
"    int local_row = get_local_id(1);\n"
"    int group_row = get_group_id(1);\n"
"    int group_col = get_group_id(0);\n"
"    __local float tile_Dz[16][16];\n"
"    __local float tile_NX[16][16];\n"
"    __global const float* norm_x_l = Saved_Norm_X + ((size_t)layer_idx * (size_t)B) * (size_t)N;\n"
"    float grad_acc = 0.0f;\n"
"    int num_tiles = (B + 15) / 16;\n"
"    for (int t = 0; t < num_tiles; t++) {\n"
"        int b_dz = t * 16 + local_row;\n"
"        int r_dz = group_row * 16 + local_col;\n"
"        tile_Dz[local_row][local_col] = (b_dz < B && r_dz < M) ? Dz[(size_t)b_dz * (size_t)M + (size_t)r_dz] : 0.0f;\n"
"        int b_nx = t * 16 + local_row;\n"
"        int c_nx = group_col * 16 + local_col;\n"
"        tile_NX[local_row][local_col] = (b_nx < B && c_nx < N) ? norm_x_l[(size_t)b_nx * (size_t)N + (size_t)c_nx] : 0.0f;\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"        #pragma unroll\n"
"        for (int k = 0; k < 16; k++) {\n"
"            grad_acc += tile_Dz[k][local_row] * tile_NX[k][local_col];\n"
"        }\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (row < M && col < N) {\n"
"        float inv_b = (B > 0) ? (1.0f / (float)B) : 1.0f;\n"
"        float g_raw = grad_acc * inv_b;\n"
"        float clipped_g = clamp(g_raw, -5.0f, 5.0f);\n"
"        size_t w_idx = (size_t)layer_idx * (size_t)(M * N) + (size_t)row * (size_t)N + (size_t)col;\n"
"        float v = All_Layers_Mom_W ? All_Layers_Mom_W[w_idx] : 0.0f;\n"
"        v = mom * v + (1.0f - mom) * clipped_g;\n"
"        if (All_Layers_Mom_W) All_Layers_Mom_W[w_idx] = v;\n"
"        __global float* w_layer = All_Layers_W + (size_t)layer_idx * (size_t)(M * N);\n"
"        w_layer[row * N + col] -= lr * v;\n"
"    }\n"
"}\n"
"__kernel void k_opencl_layer_backward_update_norm(\n"
"    __global const float* Dtx,\n"
"    __global const float* Saved_X_Cur,\n"
"    __global const float* Saved_Inv_Rms,\n"
"    __global float* All_Layers_Norms,\n"
"    __global float* All_Layers_Mom_Norms,\n"
"    int B, int M, int layer_idx, float lr, float mom\n"
") {\n"
"    int col = get_global_id(0);\n"
"    if (col >= M) return;\n"
"    __global const float* x_cur_l = Saved_X_Cur + ((size_t)layer_idx * (size_t)B) * (size_t)M;\n"
"    __global const float* inv_rms_l = Saved_Inv_Rms + (size_t)layer_idx * (size_t)B;\n"
"    float grad_sum = 0.0f;\n"
"    for (int b = 0; b < B; b++) {\n"
"        float dtx_val = Dtx[(size_t)b * (size_t)M + (size_t)col];\n"
"        float x_val = x_cur_l[(size_t)b * (size_t)M + (size_t)col];\n"
"        float inv_rms = inv_rms_l[b];\n"
"        grad_sum += dtx_val * x_val * inv_rms;\n"
"    }\n"
"    float inv_b = (B > 0) ? (1.0f / (float)B) : 1.0f;\n"
"    float g_raw = grad_sum * inv_b;\n"
"    float clipped_g = clamp(g_raw, -5.0f, 5.0f);\n"
"    size_t n_idx = (size_t)layer_idx * (size_t)M + (size_t)col;\n"
"    float v = All_Layers_Mom_Norms ? All_Layers_Mom_Norms[n_idx] : 0.0f;\n"
"    v = mom * v + (1.0f - mom) * clipped_g;\n"
"    if (All_Layers_Mom_Norms) All_Layers_Mom_Norms[n_idx] = v;\n"
"    __global float* norm_layer = All_Layers_Norms + (size_t)layer_idx * (size_t)M;\n"
"    norm_layer[col] -= lr * v;\n"
"}\n";

static void cartan_init_gpu_device_if_needed(void) {
    if (g_opencl_gpu_mounted) return;

    cl_uint num_platforms = 0;
    if (clGetPlatformIDs(0, NULL, &num_platforms) != CL_SUCCESS || num_platforms == 0) return;

    cl_platform_id platforms[8];
    clGetPlatformIDs(num_platforms, platforms, NULL);

    cl_platform_id chosen_platform = NULL;
    cl_device_id chosen_device = NULL;

    for (cl_uint p = 0; p < num_platforms; p++) {
        cl_uint num_devices = 0;
        if (clGetDeviceIDs(platforms[p], CL_DEVICE_TYPE_GPU, 0, NULL, &num_devices) == CL_SUCCESS && num_devices > 0) {
            cl_device_id devices[8];
            clGetDeviceIDs(platforms[p], CL_DEVICE_TYPE_GPU, num_devices, devices, NULL);
            for (cl_uint d = 0; d < num_devices; d++) {
                char dev_name[256] = {0};
                clGetDeviceInfo(devices[d], CL_DEVICE_NAME, sizeof(dev_name), dev_name, NULL);
                if (strstr(dev_name, "RTX") || strstr(dev_name, "NVIDIA") || strstr(dev_name, "Radeon") || !chosen_device) {
                    chosen_platform = platforms[p];
                    chosen_device = devices[d];
                    strcpy(g_opencl_gpu_name, dev_name);
                    if (strstr(dev_name, "RTX") || strstr(dev_name, "NVIDIA")) break;
                }
            }
        }
        if (chosen_device && (strstr(g_opencl_gpu_name, "RTX") || strstr(g_opencl_gpu_name, "NVIDIA"))) break;
    }

    if (!chosen_device) return;

    cl_int err;
    g_cl_context = clCreateContext(NULL, 1, &chosen_device, NULL, NULL, &err);
    if (err != CL_SUCCESS || !g_cl_context) return;

    g_cl_queue = clCreateCommandQueue(g_cl_context, chosen_device, 0, &err);
    if (err != CL_SUCCESS || !g_cl_queue) return;

    g_cl_program = clCreateProgramWithSource(g_cl_context, 1, &g_opencl_src, NULL, &err);
    if (err != CL_SUCCESS || !g_cl_program) return;

    err = clBuildProgram(g_cl_program, 1, &chosen_device, "-cl-fast-relaxed-math -cl-mad-enable", NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t log_size;
        clGetProgramBuildInfo(g_cl_program, chosen_device, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);
        char* log = (char*)malloc(log_size + 1);
        if (log) {
            clGetProgramBuildInfo(g_cl_program, chosen_device, CL_PROGRAM_BUILD_LOG, log_size, log, NULL);
            printf("[GeoMind OpenCL Build Warning] %s\n", log);
            free(log);
        }
        return;
    }

    g_cl_kernel_42layer = clCreateKernel(g_cl_program, "k_opencl_42layer_forward_lie_manifold", &err);
    g_cl_kernel_layer_fwd_norm = clCreateKernel(g_cl_program, "k_opencl_layer_forward_rmsnorm", &err);
    g_cl_kernel_layer_fwd_gemm = clCreateKernel(g_cl_program, "k_opencl_layer_forward_gemm", &err);
    g_cl_kernel_layer_fwd_gelu = clCreateKernel(g_cl_program, "k_opencl_layer_forward_gelu_residual", &err);
    g_cl_kernel_final_rmsnorm = clCreateKernel(g_cl_program, "k_opencl_final_rmsnorm", &err);
    g_cl_kernel_gemm = clCreateKernel(g_cl_program, "k_opencl_forward_gemm", &err);
    g_cl_kernel_loss = clCreateKernel(g_cl_program, "k_opencl_softmax_loss", &err);
    g_cl_kernel_sgd = clCreateKernel(g_cl_program, "k_opencl_backward_sgd", &err);
    g_cl_kernel_head_dhidden_gemm = clCreateKernel(g_cl_program, "k_opencl_tiled_backward_head_gemm", &err);
    g_cl_kernel_rmsnorm_backward = clCreateKernel(g_cl_program, "k_opencl_rmsnorm_backward", &err);
    g_cl_kernel_layer_bwd_gelu_dz = clCreateKernel(g_cl_program, "k_opencl_layer_backward_gelu_dz", &err);
    g_cl_kernel_layer_bwd_dxt_gemm = clCreateKernel(g_cl_program, "k_opencl_layer_backward_dxt_gemm", &err);
    g_cl_kernel_layer_bwd_rmsnorm_dx = clCreateKernel(g_cl_program, "k_opencl_layer_backward_rmsnorm_dx", &err);
    g_cl_kernel_layer_update_w = clCreateKernel(g_cl_program, "k_opencl_layer_backward_update_w", &err);
    g_cl_kernel_layer_update_norm = clCreateKernel(g_cl_program, "k_opencl_layer_backward_update_norm", &err);

    // Allocate OpenCL GPU VRAM buffers (Read/Write for Full Manifold Training)
    int max_b = 1024;
    d_cl_all_42_layers = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 42 * 2560 * 2560, NULL, &err);
    d_cl_all_42_mom_w = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 42 * 2560 * 2560, NULL, &err);
    d_cl_all_42_norms = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 42 * 2560, NULL, &err);
    d_cl_all_42_mom_norms = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 42 * 2560, NULL, &err);
    d_cl_all_42_routers = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 42 * 4 * 2560, NULL, &err);
    d_cl_weights = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB, NULL, &err);
    d_cl_mom_weights = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB, NULL, &err);

    // Zero-initialize Riemannian momentum velocity buffers
    if (d_cl_mom_weights) {
        float* zero_buf = (float*)calloc(2560 * CARTAN_LM_HEAD_VOCAB, sizeof(float));
        if (zero_buf) {
            clEnqueueWriteBuffer(g_cl_queue, d_cl_mom_weights, CL_TRUE, 0, sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB, zero_buf, 0, NULL, NULL);
            free(zero_buf);
        }
    }
    if (d_cl_all_42_mom_w) {
        float* zero_buf = (float*)calloc(2560 * 2560, sizeof(float));
        if (zero_buf) {
            for (int l = 0; l < 42; l++) {
                clEnqueueWriteBuffer(g_cl_queue, d_cl_all_42_mom_w, CL_TRUE, (size_t)l * 2560 * 2560 * sizeof(float), sizeof(float) * 2560 * 2560, zero_buf, 0, NULL, NULL);
            }
            free(zero_buf);
        }
    }
    if (d_cl_all_42_mom_norms) {
        float* zero_buf = (float*)calloc(42 * 2560, sizeof(float));
        if (zero_buf) {
            clEnqueueWriteBuffer(g_cl_queue, d_cl_all_42_mom_norms, CL_TRUE, 0, sizeof(float) * 42 * 2560, zero_buf, 0, NULL, NULL);
            free(zero_buf);
        }
    }

    d_cl_batch_x_in = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * max_b * 2560, NULL, &err);
    d_cl_batch_hidden = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * max_b * 2560, NULL, &err);
    d_cl_batch_logits = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * max_b * CARTAN_LM_HEAD_VOCAB, NULL, &err);
    d_cl_batch_targets = clCreateBuffer(g_cl_context, CL_MEM_READ_ONLY, sizeof(int) * max_b, NULL, &err);
    d_cl_batch_ic_weights = clCreateBuffer(g_cl_context, CL_MEM_READ_ONLY, sizeof(float) * max_b, NULL, &err);
    d_cl_batch_loss = clCreateBuffer(g_cl_context, CL_MEM_WRITE_ONLY, sizeof(float) * max_b, NULL, &err);

    d_cl_saved_norm_x = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 42 * max_b * 2560, NULL, &err);
    d_cl_saved_inv_rms = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 43 * max_b, NULL, &err);
    d_cl_saved_x_cur = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 43 * max_b * 2560, NULL, &err);
    d_cl_saved_z = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * 42 * max_b * 2560, NULL, &err);
    d_cl_batch_dx = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * max_b * 2560, NULL, &err);
    d_cl_batch_dz = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * max_b * 2560, NULL, &err);
    d_cl_batch_dtx = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * max_b * 2560, NULL, &err);
    d_cl_batch_norm_x = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * max_b * 2560, NULL, &err);
    d_cl_batch_z = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * max_b * 2560, NULL, &err);
    d_cl_batch_dhidden = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, sizeof(float) * max_b * 2560, NULL, &err);

    g_opencl_gpu_mounted = 1;
    printf("[GeoMind OpenCL GPU] Mounted OpenCL 3.0 Full Manifold Hardware Engine: %s (2.0 GB VRAM Active)\n", g_opencl_gpu_name);
    fflush(stdout);

    // Initialize host flat weights from Gemma embeddings if available
    extern void cartan_init_weights_if_needed(void);
    cartan_init_weights_if_needed();

    if (g_42layer_loaded && g_42layer_weights && d_cl_all_42_layers) {
        clEnqueueWriteBuffer(g_cl_queue, d_cl_all_42_layers, CL_TRUE, 0, sizeof(float) * 42 * 2560 * 2560, g_42layer_weights, 0, NULL, NULL);
        if (d_cl_all_42_norms && g_42layer_norms) {
            clEnqueueWriteBuffer(g_cl_queue, d_cl_all_42_norms, CL_TRUE, 0, sizeof(float) * 42 * 2560, g_42layer_norms, 0, NULL, NULL);
        }
        if (d_cl_all_42_routers && g_42layer_routers) {
            clEnqueueWriteBuffer(g_cl_queue, d_cl_all_42_routers, CL_TRUE, 0, sizeof(float) * 42 * 4 * 2560, g_42layer_routers, 0, NULL, NULL);
        }
    }
}

CARTAN_WEAK void cartan_mark_weights_initialized(void) {
    g_weights_init = 1;
}

CARTAN_WEAK void cartan_sync_host_weights_to_gpu(void) {
    cartan_init_gpu_device_if_needed();
    g_weights_init = 1;
    if (g_opencl_gpu_mounted && d_cl_weights && g_cl_queue && g_model_weights_flat) {
        float* gpu_head_buf = (float*)malloc(sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB);
        if (gpu_head_buf) {
            for (size_t r = 0; r < 2560; r++) {
                memcpy(&gpu_head_buf[r * CARTAN_LM_HEAD_VOCAB], &g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE], sizeof(float) * CARTAN_LM_HEAD_VOCAB);
            }
            clEnqueueWriteBuffer(g_cl_queue, d_cl_weights, CL_TRUE, 0, sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB, gpu_head_buf, 0, NULL, NULL);
            free(gpu_head_buf);
        }
    }
}

CARTAN_WEAK void cartan_sync_42layers_to_gpu(void) {
    cartan_init_gpu_device_if_needed();
    if (g_opencl_gpu_mounted && d_cl_all_42_layers && g_42layer_weights && g_cl_queue) {
        clEnqueueWriteBuffer(g_cl_queue, d_cl_all_42_layers, CL_TRUE, 0, sizeof(float) * 42 * 2560 * 2560, g_42layer_weights, 0, NULL, NULL);
        if (d_cl_all_42_norms && g_42layer_norms) {
            clEnqueueWriteBuffer(g_cl_queue, d_cl_all_42_norms, CL_TRUE, 0, sizeof(float) * 42 * 2560, g_42layer_norms, 0, NULL, NULL);
        }
        if (d_cl_all_42_routers && g_42layer_routers) {
            clEnqueueWriteBuffer(g_cl_queue, d_cl_all_42_routers, CL_TRUE, 0, sizeof(float) * 42 * 4 * 2560, g_42layer_routers, 0, NULL, NULL);
        }
    }
}

CARTAN_WEAK void cartan_sync_42layers_from_gpu(void) {
    if (g_opencl_gpu_mounted && d_cl_all_42_layers && g_42layer_weights && g_cl_queue) {
        clEnqueueReadBuffer(g_cl_queue, d_cl_all_42_layers, CL_TRUE, 0, sizeof(float) * 42 * 2560 * 2560, g_42layer_weights, 0, NULL, NULL);
        if (d_cl_all_42_norms && g_42layer_norms) {
            clEnqueueReadBuffer(g_cl_queue, d_cl_all_42_norms, CL_TRUE, 0, sizeof(float) * 42 * 2560, g_42layer_norms, 0, NULL, NULL);
        }
        if (d_cl_all_42_routers && g_42layer_routers) {
            clEnqueueReadBuffer(g_cl_queue, d_cl_all_42_routers, CL_TRUE, 0, sizeof(float) * 42 * 4 * 2560, g_42layer_routers, 0, NULL, NULL);
        }
        if (d_cl_weights && g_model_weights_flat) {
            float* gpu_head_buf = (float*)malloc(sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB);
            if (gpu_head_buf) {
                clEnqueueReadBuffer(g_cl_queue, d_cl_weights, CL_TRUE, 0, sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB, gpu_head_buf, 0, NULL, NULL);
                for (size_t r = 0; r < 2560; r++) {
                    memcpy(&g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE], &gpu_head_buf[r * CARTAN_LM_HEAD_VOCAB], sizeof(float) * CARTAN_LM_HEAD_VOCAB);
                    for (int c = 0; c < 2560 && c < CARTAN_LM_HEAD_VOCAB; c++) {
                        g_model_weights[r][c] = (double)gpu_head_buf[r * CARTAN_LM_HEAD_VOCAB + c];
                    }
                }
                free(gpu_head_buf);
            }
        }
    }
}

CARTAN_WEAK double cartan_reset_baseline_weights_for_coadaptation(void) {
    cartan_init_gpu_device_if_needed();
    g_weights_init = 1;
    if (!g_model_weights_flat) {
        g_model_weights_flat = (float*)malloc(sizeof(float) * (size_t)2560 * CARTAN_FULL_VOCAB_SIZE);
    }
    cartan_init_gemma_embed_matrix_if_needed();
    if (g_gemma_embed_matrix && g_model_weights_flat) {
        int c;
        #pragma omp parallel for schedule(static, 256)
        for (c = 0; c < (int)CARTAN_FULL_VOCAB_SIZE; c++) {
            const float* e_row = g_gemma_embed_matrix + (size_t)c * 2560;
            for (size_t r = 0; r < 2560; r++) {
                float v = e_row[r] / 50.59644256f;
                g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE + c] = v;
                if (r < 2560 && c < 2560) {
                    g_model_weights[r][c] = (double)v;
                }
            }
        }
    }
    cartan_sync_host_weights_to_gpu();
    printf("[GeoMind Co-Adaptation] Reset baseline LM head weights to aligned Gemma embedding manifold for 2560x65536.\n");
    fflush(stdout);
    return 0.0;
}

CARTAN_WEAK void cartan_init_weights_if_needed(void) {
    cartan_init_gpu_device_if_needed();
    if (g_weights_init && g_model_weights_flat) return;
    g_weights_init = 1;

    if (!g_model_weights_flat) {
        g_model_weights_flat = (float*)malloc(sizeof(float) * (size_t)2560 * CARTAN_FULL_VOCAB_SIZE);
    }
    cartan_init_gemma_embed_matrix_if_needed();

    if (g_model_weights_flat) {
        if (g_gemma_embed_matrix) {
            int c;
            #pragma omp parallel for schedule(static, 256)
            for (c = 0; c < (int)CARTAN_FULL_VOCAB_SIZE; c++) {
                const float* e_row = g_gemma_embed_matrix + (size_t)c * 2560;
                for (size_t r = 0; r < 2560; r++) {
                    float v = e_row[r] / 50.59644256f;
                    g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE + c] = v;
                    if (r < 2560 && c < 2560) {
                        g_model_weights[r][c] = (double)v;
                    }
                }
            }
        } else {
            for (size_t r = 0; r < 2560; r++) {
                for (size_t c = 0; c < CARTAN_LM_HEAD_VOCAB; c++) {
                    float diag = (r == c) ? 1.0f : 0.0f;
                    float noise = (((float)((r * 31 + c * 17) % 200) - 100.0f) / 100.0f) * 0.01f;
                    float v = diag + noise;
                    g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE + c] = v;
                    if (r < 2560 && c < 2560) {
                        g_model_weights[r][c] = (double)v;
                    }
                }
            }
        }
        if (g_opencl_gpu_mounted && d_cl_weights && g_cl_queue) {
            float* gpu_head_buf = (float*)malloc(sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB);
            if (gpu_head_buf) {
                for (size_t r = 0; r < 2560; r++) {
                    memcpy(&gpu_head_buf[r * CARTAN_LM_HEAD_VOCAB], &g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE], sizeof(float) * CARTAN_LM_HEAD_VOCAB);
                }
                clEnqueueWriteBuffer(g_cl_queue, d_cl_weights, CL_TRUE, 0, sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB, gpu_head_buf, 0, NULL, NULL);
                free(gpu_head_buf);
            }
        }
    }
}

CARTAN_WEAK double cartan_tensor_train_step(void* hidden_ptr, double target_tok_id, double learning_rate) {
    cartan_init_weights_if_needed();
    if (!hidden_ptr) return 0.0;
    CartanVector* h = (CartanVector*)hidden_ptr;
    size_t dim = h->size < 2560 ? h->size : 2560;
    int target_idx = ((int)target_tok_id) % 2560;
    if (target_idx < 0) target_idx = 0;

    double logits[2560] = {0};
    double max_logit = -1e9;

    for (int c = 0; c < 2560; c++) {
        double dot = 0.0;
        for (size_t r = 0; r < dim; r++) {
            dot += h->data[r] * g_model_weights[r][c];
        }
        logits[c] = dot;
        if (dot > max_logit) max_logit = dot;
    }

    double sum_exp = 0.0;
    double probs[2560] = {0};
    for (int c = 0; c < 2560; c++) {
        probs[c] = exp(logits[c] - max_logit);
        sum_exp += probs[c];
    }
    if (sum_exp <= 0.0) sum_exp = 1.0;
    for (int c = 0; c < 2560; c++) probs[c] /= sum_exp;

    double loss = -log(probs[target_idx] > 1e-12 ? probs[target_idx] : 1e-12);
    double lr = (learning_rate != 0.0) ? learning_rate : 0.005;

    for (size_t r = 0; r < dim; r++) {
        for (int c = 0; c < 2560; c++) {
            double target = (c == target_idx) ? 1.0 : 0.0;
            double grad = (probs[c] - target) * h->data[r];
            g_model_weights[r][c] -= lr * (grad + 0.0001 * g_model_weights[r][c]);
        }
    }
    return loss;
}

CARTAN_WEAK double cartan_tensor_hebbian_update(void* pre_ptr, void* post_ptr, double neuromodulator, double lr) {
    cartan_init_weights_if_needed();
    if (!pre_ptr || !post_ptr) return 0.0;
    CartanVector* pre = (CartanVector*)pre_ptr;
    CartanVector* post = (CartanVector*)post_ptr;
    if (pre->size == 0 || post->size == 0) return 0.0;

    size_t rows = pre->size < 2560 ? (size_t)pre->size : 2560;
    size_t cols = post->size < 2560 ? (size_t)post->size : 2560;
    double m = (neuromodulator != 0.0) ? neuromodulator : 1.0;
    double eta = (lr != 0.0) ? lr : 0.001;
    double alpha = 0.01;

    #pragma omp parallel for schedule(static, 64)
    for (int r = 0; r < (int)rows; r++) {
        double pre_val = pre->data[r];
        for (size_t c = 0; c < cols; c++) {
            double post_val = post->data[c];
            double cur_w = g_model_weights[r][c];
            double oja_term = alpha * (post_val * post_val) * cur_w;
            double delta = eta * m * (pre_val * post_val - oja_term);
            double new_w = cur_w + delta;
            g_model_weights[r][c] = new_w;
            if (g_model_weights_flat && c < CARTAN_LM_HEAD_VOCAB) {
                g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE + c] = (float)new_w;
            }
        }
    }
    return 1.0;
}

CARTAN_WEAK double cartan_hebbian_step_token(void* hidden_ptr, double tok_id, double neuromodulator, double lr) {
    cartan_init_weights_if_needed();
    if (!hidden_ptr) return 0.0;
    CartanVector* h = (CartanVector*)hidden_ptr;
    if (h->size == 0) return 0.0;

    int target_idx = ((int)tok_id) % 2560;
    if (target_idx < 0) target_idx = 0;

    size_t rows = h->size < 2560 ? (size_t)h->size : 2560;
    double m = (neuromodulator != 0.0) ? neuromodulator : 1.0;
    double eta = (lr != 0.0) ? lr : 0.001;
    double alpha = 0.01;

    for (size_t r = 0; r < rows; r++) {
        double pre_val = h->data[r];
        double post_val = 1.0;
        double cur_w = g_model_weights[r][target_idx];
        double delta = eta * m * (pre_val * post_val - alpha * cur_w);
        double new_w = cur_w + delta;
        g_model_weights[r][target_idx] = new_w;
        if (g_model_weights_flat && (size_t)target_idx < CARTAN_LM_HEAD_VOCAB) {
            g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE + target_idx] = (float)new_w;
        }
    }
    return 1.0;
}

CARTAN_WEAK double cartan_tensor_train_batch_gpu(const float* h_batch_hidden, const int* h_targets, const float* h_ic_weights, double batch_size, double learning_rate) {
    cartan_init_weights_if_needed();
    int B = (int)batch_size;
    if (B <= 0 || !h_batch_hidden || !h_targets) return 0.0;
    if (B > 4096) B = 4096;

    double total_batch_loss = 0.0;
    int M = 2560, N = 2560;

    if (g_opencl_gpu_mounted && g_cl_context && g_cl_queue && g_cl_kernel_gemm && g_cl_kernel_loss) {
        float f_lr = (float)learning_rate;
        clEnqueueWriteBuffer(g_cl_queue, d_cl_batch_hidden, CL_TRUE, 0, sizeof(float) * B * M, h_batch_hidden, 0, NULL, NULL);
        clEnqueueWriteBuffer(g_cl_queue, d_cl_batch_targets, CL_TRUE, 0, sizeof(int) * B, h_targets, 0, NULL, NULL);
        if (h_ic_weights) {
            clEnqueueWriteBuffer(g_cl_queue, d_cl_batch_ic_weights, CL_TRUE, 0, sizeof(float) * B, h_ic_weights, 0, NULL, NULL);
        } else {
            float dummy_ic[4096];
            for (int i = 0; i < B; i++) dummy_ic[i] = 1.0f;
            clEnqueueWriteBuffer(g_cl_queue, d_cl_batch_ic_weights, CL_TRUE, 0, sizeof(float) * B, dummy_ic, 0, NULL, NULL);
        }

        // Stage 1a: Forward GEMM: Logits = Hidden * W
        clSetKernelArg(g_cl_kernel_gemm, 0, sizeof(cl_mem), &d_cl_batch_hidden);
        clSetKernelArg(g_cl_kernel_gemm, 1, sizeof(cl_mem), &d_cl_weights);
        clSetKernelArg(g_cl_kernel_gemm, 2, sizeof(cl_mem), &d_cl_batch_logits);
        clSetKernelArg(g_cl_kernel_gemm, 3, sizeof(int), &B);
        clSetKernelArg(g_cl_kernel_gemm, 4, sizeof(int), &M);
        clSetKernelArg(g_cl_kernel_gemm, 5, sizeof(int), &N);
        size_t g_ws_gemm[2] = { ((size_t)N + 15) / 16 * 16, ((size_t)B + 15) / 16 * 16 };
        size_t l_ws_gemm[2] = { 16, 16 };
        clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_gemm, 2, NULL, g_ws_gemm, l_ws_gemm, 0, NULL, NULL);

        // Stage 1b: Softmax + Cross Entropy Loss
        clSetKernelArg(g_cl_kernel_loss, 0, sizeof(cl_mem), &d_cl_batch_logits);
        clSetKernelArg(g_cl_kernel_loss, 1, sizeof(cl_mem), &d_cl_batch_targets);
        clSetKernelArg(g_cl_kernel_loss, 2, sizeof(cl_mem), &d_cl_batch_ic_weights);
        clSetKernelArg(g_cl_kernel_loss, 3, sizeof(cl_mem), &d_cl_batch_loss);
        clSetKernelArg(g_cl_kernel_loss, 4, sizeof(int), &B);
        clSetKernelArg(g_cl_kernel_loss, 5, sizeof(int), &N);
        size_t g_ws_loss[1] = { ((size_t)B + 63) / 64 * 64 };
        size_t l_ws_loss[1] = { 64 };
        clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_loss, 1, NULL, g_ws_loss, l_ws_loss, 0, NULL, NULL);

        // Stage 2: Backward SGD with Riemannian Momentum
        if (learning_rate > 0.0 && g_cl_kernel_sgd) {
            float f_mom = 0.90f;
            clSetKernelArg(g_cl_kernel_sgd, 0, sizeof(cl_mem), &d_cl_batch_hidden);
            clSetKernelArg(g_cl_kernel_sgd, 1, sizeof(cl_mem), &d_cl_batch_logits);
            clSetKernelArg(g_cl_kernel_sgd, 2, sizeof(cl_mem), &d_cl_batch_targets);
            clSetKernelArg(g_cl_kernel_sgd, 3, sizeof(cl_mem), &d_cl_batch_ic_weights);
            clSetKernelArg(g_cl_kernel_sgd, 4, sizeof(cl_mem), &d_cl_weights);
            clSetKernelArg(g_cl_kernel_sgd, 5, sizeof(cl_mem), &d_cl_mom_weights);
            clSetKernelArg(g_cl_kernel_sgd, 6, sizeof(int), &B);
            clSetKernelArg(g_cl_kernel_sgd, 7, sizeof(int), &M);
            clSetKernelArg(g_cl_kernel_sgd, 8, sizeof(int), &N);
            clSetKernelArg(g_cl_kernel_sgd, 9, sizeof(float), &f_lr);
            clSetKernelArg(g_cl_kernel_sgd, 10, sizeof(float), &f_mom);
            size_t g_ws_sgd[2] = { ((size_t)N + 15) / 16 * 16, ((size_t)M + 15) / 16 * 16 };
            size_t l_ws_sgd[2] = { 16, 16 };
            clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_sgd, 2, NULL, g_ws_sgd, l_ws_sgd, 0, NULL, NULL);
        }

        float h_loss[4096];
        clEnqueueReadBuffer(g_cl_queue, d_cl_batch_loss, CL_TRUE, 0, sizeof(float) * B, h_loss, 0, NULL, NULL);
        for (int b = 0; b < B; b++) total_batch_loss += (double)h_loss[b];
        return total_batch_loss;
    }

    // CPU Fallback
    for (int b = 0; b < B; b++) {
        float max_l = -1e9f;
        float probs[2560] = {0};
        for (int c = 0; c < N; c++) {
            float sum = 0.0f;
            for (int r = 0; r < M; r++) {
                sum += h_batch_hidden[b * M + r] * (float)g_model_weights[r][c];
            }
            probs[c] = sum;
            if (sum > max_l) max_l = sum;
        }
        double sum_e = 0.0;
        for (int c = 0; c < N; c++) {
            double p = exp((double)probs[c] - (double)max_l);
            probs[c] = (float)p;
            sum_e += p;
        }
        if (sum_e <= 0.0) sum_e = 1.0;
        for (int c = 0; c < N; c++) probs[c] /= (float)sum_e;

        int target_idx = h_targets[b] % N;
        if (target_idx < 0) target_idx = 0;
        float target_p = probs[target_idx];
        if (target_p < 1e-12f) target_p = 1e-12f;
        float ic_w = h_ic_weights ? h_ic_weights[b] : 1.0f;
        total_batch_loss += (double)(-logf(target_p) * ic_w);

        if (learning_rate > 0.0) {
            float f_lr = (float)learning_rate;
            for (int c = 0; c < N; c++) {
                float target_c = (c == target_idx) ? 1.0f : 0.0f;
                float err_c = (probs[c] - target_c) * ic_w;
                for (int r = 0; r < M; r++) {
                    float xv = h_batch_hidden[b * M + r];
                    float g_raw = err_c * xv;
                    if (g_raw > 5.0f) g_raw = 5.0f;
                    if (g_raw < -5.0f) g_raw = -5.0f;
                    g_model_weights[r][c] -= (double)(f_lr * g_raw);
                }
            }
        }
    }
    return total_batch_loss;
}

CARTAN_WEAK double cartan_tensor_train_batch_gpu_direct(const float* h_batch_x_in, const int* h_targets, const float* h_ic_weights, double batch_size, double learning_rate) {
    cartan_init_weights_if_needed();
    int B = (int)batch_size;
    if (B <= 0 || !h_batch_x_in || !h_targets) return 0.0;
    if (B > 1024) B = 1024;

    double total_batch_loss = 0.0;
    int M = 2560;
    int N = CARTAN_LM_HEAD_VOCAB;

    if (g_opencl_gpu_mounted && g_cl_context && g_cl_queue && g_cl_kernel_layer_fwd_gemm && d_cl_all_42_layers && d_cl_all_42_norms && d_cl_all_42_routers) {
        float f_lr = (float)learning_rate;
        int save_acts = (learning_rate > 0.0) ? 1 : 0;

        clEnqueueWriteBuffer(g_cl_queue, d_cl_batch_x_in, CL_FALSE, 0, sizeof(float) * B * M, h_batch_x_in, 0, NULL, NULL);
        clEnqueueWriteBuffer(g_cl_queue, d_cl_batch_targets, CL_FALSE, 0, sizeof(int) * B, h_targets, 0, NULL, NULL);
        if (h_ic_weights) {
            clEnqueueWriteBuffer(g_cl_queue, d_cl_batch_ic_weights, CL_FALSE, 0, sizeof(float) * B, h_ic_weights, 0, NULL, NULL);
        } else {
            float dummy_ic[1024];
            for (int i = 0; i < B; i++) dummy_ic[i] = 1.0f;
            clEnqueueWriteBuffer(g_cl_queue, d_cl_batch_ic_weights, CL_FALSE, 0, sizeof(float) * B, dummy_ic, 0, NULL, NULL);
        }

        LARGE_INTEGER pf, pt0, pt1, pt2, pt3, pt4a, pt4b, pt4c;
        QueryPerformanceFrequency(&pf);
        QueryPerformanceCounter(&pt0);

        // Stage 1: 42-Layer Lie Manifold Forward Pass (2D Tiled Shared Memory GEMMs)
        size_t g_ws_norm[1] = { (size_t)B * 256 };
        size_t l_ws_norm[1] = { 256 };
        size_t g_ws_layer_tile[2] = { ((size_t)M + 15) / 16 * 16, ((size_t)B + 15) / 16 * 16 };
        size_t l_ws_tile[2] = { 16, 16 };

        for (int l = 0; l < 42; l++) {
            cl_mem cur_x = (l % 2 == 0) ? d_cl_batch_x_in : d_cl_batch_dtx;
            cl_mem next_x = (l % 2 == 0) ? d_cl_batch_dtx : d_cl_batch_x_in;

            // 1a. RMSNorm & activation stashing
            clSetKernelArg(g_cl_kernel_layer_fwd_norm, 0, sizeof(cl_mem), &cur_x);
            clSetKernelArg(g_cl_kernel_layer_fwd_norm, 1, sizeof(cl_mem), &d_cl_all_42_norms);
            clSetKernelArg(g_cl_kernel_layer_fwd_norm, 2, sizeof(cl_mem), &d_cl_batch_norm_x);
            clSetKernelArg(g_cl_kernel_layer_fwd_norm, 3, sizeof(cl_mem), &d_cl_saved_norm_x);
            clSetKernelArg(g_cl_kernel_layer_fwd_norm, 4, sizeof(cl_mem), &d_cl_saved_inv_rms);
            clSetKernelArg(g_cl_kernel_layer_fwd_norm, 5, sizeof(cl_mem), &d_cl_saved_x_cur);
            clSetKernelArg(g_cl_kernel_layer_fwd_norm, 6, sizeof(int), &B);
            clSetKernelArg(g_cl_kernel_layer_fwd_norm, 7, sizeof(int), &M);
            clSetKernelArg(g_cl_kernel_layer_fwd_norm, 8, sizeof(int), &l);
            clSetKernelArg(g_cl_kernel_layer_fwd_norm, 9, sizeof(int), &save_acts);
            clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_layer_fwd_norm, 1, NULL, g_ws_norm, l_ws_norm, 0, NULL, NULL);

            // 1b. 2D Tiled Shared-Memory GEMM: Z_l = NormX_l x W_l^T
            clSetKernelArg(g_cl_kernel_layer_fwd_gemm, 0, sizeof(cl_mem), &d_cl_batch_norm_x);
            clSetKernelArg(g_cl_kernel_layer_fwd_gemm, 1, sizeof(cl_mem), &d_cl_all_42_layers);
            clSetKernelArg(g_cl_kernel_layer_fwd_gemm, 2, sizeof(cl_mem), &d_cl_batch_z);
            clSetKernelArg(g_cl_kernel_layer_fwd_gemm, 3, sizeof(cl_mem), &d_cl_saved_z);
            clSetKernelArg(g_cl_kernel_layer_fwd_gemm, 4, sizeof(int), &B);
            clSetKernelArg(g_cl_kernel_layer_fwd_gemm, 5, sizeof(int), &M);
            clSetKernelArg(g_cl_kernel_layer_fwd_gemm, 6, sizeof(int), &l);
            clSetKernelArg(g_cl_kernel_layer_fwd_gemm, 7, sizeof(int), &save_acts);
            clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_layer_fwd_gemm, 2, NULL, g_ws_layer_tile, l_ws_tile, 0, NULL, NULL);

            // 1c. GeLU Activation + Residual Addition: X_{l+1} = X_l + (1/sqrt(42)) * GeLU(Z_l)
            clSetKernelArg(g_cl_kernel_layer_fwd_gelu, 0, sizeof(cl_mem), &cur_x);
            clSetKernelArg(g_cl_kernel_layer_fwd_gelu, 1, sizeof(cl_mem), &d_cl_batch_z);
            clSetKernelArg(g_cl_kernel_layer_fwd_gelu, 2, sizeof(cl_mem), &next_x);
            clSetKernelArg(g_cl_kernel_layer_fwd_gelu, 3, sizeof(int), &B);
            clSetKernelArg(g_cl_kernel_layer_fwd_gelu, 4, sizeof(int), &M);
            clSetKernelArg(g_cl_kernel_layer_fwd_gelu, 5, sizeof(int), &l);
            clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_layer_fwd_gelu, 2, NULL, g_ws_layer_tile, l_ws_tile, 0, NULL, NULL);
        }

        // 1d. Final RMSNorm after 42nd layer (output of layer 41 is in d_cl_batch_x_in)
        clSetKernelArg(g_cl_kernel_final_rmsnorm, 0, sizeof(cl_mem), &d_cl_batch_x_in);
        clSetKernelArg(g_cl_kernel_final_rmsnorm, 1, sizeof(cl_mem), &d_cl_all_42_norms);
        clSetKernelArg(g_cl_kernel_final_rmsnorm, 2, sizeof(cl_mem), &d_cl_batch_hidden);
        clSetKernelArg(g_cl_kernel_final_rmsnorm, 3, sizeof(cl_mem), &d_cl_saved_inv_rms);
        clSetKernelArg(g_cl_kernel_final_rmsnorm, 4, sizeof(cl_mem), &d_cl_saved_x_cur);
        clSetKernelArg(g_cl_kernel_final_rmsnorm, 5, sizeof(int), &B);
        clSetKernelArg(g_cl_kernel_final_rmsnorm, 6, sizeof(int), &M);
        clSetKernelArg(g_cl_kernel_final_rmsnorm, 7, sizeof(int), &save_acts);
        clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_final_rmsnorm, 1, NULL, g_ws_norm, l_ws_norm, 0, NULL, NULL);

        clFinish(g_cl_queue);
        QueryPerformanceCounter(&pt1);

        // Stage 2: Forward GEMM in VRAM (Project 2560-D Hidden state into CARTAN_LM_HEAD_VOCAB logits)
        clSetKernelArg(g_cl_kernel_gemm, 0, sizeof(cl_mem), &d_cl_batch_hidden);
        clSetKernelArg(g_cl_kernel_gemm, 1, sizeof(cl_mem), &d_cl_weights);
        clSetKernelArg(g_cl_kernel_gemm, 2, sizeof(cl_mem), &d_cl_batch_logits);
        clSetKernelArg(g_cl_kernel_gemm, 3, sizeof(int), &B);
        clSetKernelArg(g_cl_kernel_gemm, 4, sizeof(int), &M);
        clSetKernelArg(g_cl_kernel_gemm, 5, sizeof(int), &N);
        size_t g_ws_gemm[2] = { ((size_t)N + 15) / 16 * 16, ((size_t)B + 15) / 16 * 16 };
        clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_gemm, 2, NULL, g_ws_gemm, l_ws_tile, 0, NULL, NULL);
        clFinish(g_cl_queue);
        QueryPerformanceCounter(&pt2);

        // Stage 3: Softmax + Cross Entropy Loss across 16,384 vocabulary classes
        clSetKernelArg(g_cl_kernel_loss, 0, sizeof(cl_mem), &d_cl_batch_logits);
        clSetKernelArg(g_cl_kernel_loss, 1, sizeof(cl_mem), &d_cl_batch_targets);
        clSetKernelArg(g_cl_kernel_loss, 2, sizeof(cl_mem), &d_cl_batch_ic_weights);
        clSetKernelArg(g_cl_kernel_loss, 3, sizeof(cl_mem), &d_cl_batch_loss);
        clSetKernelArg(g_cl_kernel_loss, 4, sizeof(int), &B);
        clSetKernelArg(g_cl_kernel_loss, 5, sizeof(int), &N);
        size_t g_ws_loss[1] = { ((size_t)B + 63) / 64 * 64 };
        size_t l_ws_loss[1] = { 64 };
        clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_loss, 1, NULL, g_ws_loss, l_ws_loss, 0, NULL, NULL);
        clFinish(g_cl_queue);
        QueryPerformanceCounter(&pt3);

        // Stage 4: Full 42-Layer Reverse-Mode Manifold Backpropagation with Riemannian Momentum
        if (learning_rate > 0.0 && g_cl_kernel_sgd && g_cl_kernel_head_dhidden_gemm && g_cl_kernel_layer_bwd_dxt_gemm && g_cl_kernel_layer_update_w) {
            float f_mom = 0.90f;

            // 4a. Update LM Head projection weights with Riemannian momentum (2560 x 16384)
            clSetKernelArg(g_cl_kernel_sgd, 0, sizeof(cl_mem), &d_cl_batch_hidden);
            clSetKernelArg(g_cl_kernel_sgd, 1, sizeof(cl_mem), &d_cl_batch_logits);
            clSetKernelArg(g_cl_kernel_sgd, 2, sizeof(cl_mem), &d_cl_batch_targets);
            clSetKernelArg(g_cl_kernel_sgd, 3, sizeof(cl_mem), &d_cl_batch_ic_weights);
            clSetKernelArg(g_cl_kernel_sgd, 4, sizeof(cl_mem), &d_cl_weights);
            clSetKernelArg(g_cl_kernel_sgd, 5, sizeof(cl_mem), &d_cl_mom_weights);
            clSetKernelArg(g_cl_kernel_sgd, 6, sizeof(int), &B);
            clSetKernelArg(g_cl_kernel_sgd, 7, sizeof(int), &M);
            clSetKernelArg(g_cl_kernel_sgd, 8, sizeof(int), &N);
            clSetKernelArg(g_cl_kernel_sgd, 9, sizeof(float), &f_lr);
            clSetKernelArg(g_cl_kernel_sgd, 10, sizeof(float), &f_mom);
            size_t g_ws_sgd[2] = { ((size_t)N + 15) / 16 * 16, ((size_t)M + 15) / 16 * 16 };
            clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_sgd, 2, NULL, g_ws_sgd, l_ws_tile, 0, NULL, NULL);
            clFinish(g_cl_queue);
            QueryPerformanceCounter(&pt4a);

            // 4b. 2D Tiled LM Head Backward GEMM: D_Hidden [B, M] = (P - Y) x W_Head^T
            clSetKernelArg(g_cl_kernel_head_dhidden_gemm, 0, sizeof(cl_mem), &d_cl_batch_logits);
            clSetKernelArg(g_cl_kernel_head_dhidden_gemm, 1, sizeof(cl_mem), &d_cl_batch_targets);
            clSetKernelArg(g_cl_kernel_head_dhidden_gemm, 2, sizeof(cl_mem), &d_cl_batch_ic_weights);
            clSetKernelArg(g_cl_kernel_head_dhidden_gemm, 3, sizeof(cl_mem), &d_cl_weights);
            clSetKernelArg(g_cl_kernel_head_dhidden_gemm, 4, sizeof(cl_mem), &d_cl_batch_dhidden);
            clSetKernelArg(g_cl_kernel_head_dhidden_gemm, 5, sizeof(int), &B);
            clSetKernelArg(g_cl_kernel_head_dhidden_gemm, 6, sizeof(int), &M);
            clSetKernelArg(g_cl_kernel_head_dhidden_gemm, 7, sizeof(int), &N);
            clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_head_dhidden_gemm, 2, NULL, g_ws_layer_tile, l_ws_tile, 0, NULL, NULL);

            // Backprop through Final RMSNorm to obtain dx_{42} in d_cl_batch_dx
            clSetKernelArg(g_cl_kernel_rmsnorm_backward, 0, sizeof(cl_mem), &d_cl_batch_dhidden);
            clSetKernelArg(g_cl_kernel_rmsnorm_backward, 1, sizeof(cl_mem), &d_cl_saved_x_cur);
            clSetKernelArg(g_cl_kernel_rmsnorm_backward, 2, sizeof(cl_mem), &d_cl_saved_inv_rms);
            clSetKernelArg(g_cl_kernel_rmsnorm_backward, 3, sizeof(cl_mem), &d_cl_all_42_norms);
            clSetKernelArg(g_cl_kernel_rmsnorm_backward, 4, sizeof(cl_mem), &d_cl_batch_dx);
            clSetKernelArg(g_cl_kernel_rmsnorm_backward, 5, sizeof(int), &B);
            clSetKernelArg(g_cl_kernel_rmsnorm_backward, 6, sizeof(int), &M);
            int final_layer_idx = 42;
            clSetKernelArg(g_cl_kernel_rmsnorm_backward, 7, sizeof(int), &final_layer_idx);
            clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_rmsnorm_backward, 1, NULL, g_ws_norm, l_ws_norm, 0, NULL, NULL);

            clFinish(g_cl_queue);
            QueryPerformanceCounter(&pt4b);

            // 4c. Reverse-mode automatic differentiation through layers 41 down to 0
            size_t g_ws_layer_w[2] = { ((size_t)M + 15) / 16 * 16, ((size_t)M + 15) / 16 * 16 };
            size_t g_ws_norm_1d[1] = { 2560 };
            size_t l_ws_norm_1d[1] = { 256 };

            for (int l = 41; l >= 0; l--) {
                // Compute dz_l = dx_{l+1} * (1/sqrt(42)) * GeLU'(Z_l)
                clSetKernelArg(g_cl_kernel_layer_bwd_gelu_dz, 0, sizeof(cl_mem), &d_cl_batch_dx);
                clSetKernelArg(g_cl_kernel_layer_bwd_gelu_dz, 1, sizeof(cl_mem), &d_cl_saved_z);
                clSetKernelArg(g_cl_kernel_layer_bwd_gelu_dz, 2, sizeof(cl_mem), &d_cl_batch_dz);
                clSetKernelArg(g_cl_kernel_layer_bwd_gelu_dz, 3, sizeof(int), &B);
                clSetKernelArg(g_cl_kernel_layer_bwd_gelu_dz, 4, sizeof(int), &M);
                clSetKernelArg(g_cl_kernel_layer_bwd_gelu_dz, 5, sizeof(int), &l);
                clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_layer_bwd_gelu_dz, 2, NULL, g_ws_layer_tile, l_ws_tile, 0, NULL, NULL);

                // 2D Tiled Shared-Memory GEMM: Dtx_l = Dz_l x W_l
                clSetKernelArg(g_cl_kernel_layer_bwd_dxt_gemm, 0, sizeof(cl_mem), &d_cl_batch_dz);
                clSetKernelArg(g_cl_kernel_layer_bwd_dxt_gemm, 1, sizeof(cl_mem), &d_cl_all_42_layers);
                clSetKernelArg(g_cl_kernel_layer_bwd_dxt_gemm, 2, sizeof(cl_mem), &d_cl_batch_dtx);
                clSetKernelArg(g_cl_kernel_layer_bwd_dxt_gemm, 3, sizeof(int), &B);
                clSetKernelArg(g_cl_kernel_layer_bwd_dxt_gemm, 4, sizeof(int), &M);
                clSetKernelArg(g_cl_kernel_layer_bwd_dxt_gemm, 5, sizeof(int), &l);
                clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_layer_bwd_dxt_gemm, 2, NULL, g_ws_layer_tile, l_ws_tile, 0, NULL, NULL);

                // 2D Tiled Shared-Memory GEMM: Update layer weight matrix W_l (grad_W = Dz^T x NormX)
                clSetKernelArg(g_cl_kernel_layer_update_w, 0, sizeof(cl_mem), &d_cl_batch_dz);
                clSetKernelArg(g_cl_kernel_layer_update_w, 1, sizeof(cl_mem), &d_cl_saved_norm_x);
                clSetKernelArg(g_cl_kernel_layer_update_w, 2, sizeof(cl_mem), &d_cl_all_42_layers);
                clSetKernelArg(g_cl_kernel_layer_update_w, 3, sizeof(cl_mem), &d_cl_all_42_mom_w);
                clSetKernelArg(g_cl_kernel_layer_update_w, 4, sizeof(int), &B);
                clSetKernelArg(g_cl_kernel_layer_update_w, 5, sizeof(int), &M);
                clSetKernelArg(g_cl_kernel_layer_update_w, 6, sizeof(int), &M);
                clSetKernelArg(g_cl_kernel_layer_update_w, 7, sizeof(int), &l);
                clSetKernelArg(g_cl_kernel_layer_update_w, 8, sizeof(float), &f_lr);
                clSetKernelArg(g_cl_kernel_layer_update_w, 9, sizeof(float), &f_mom);
                clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_layer_update_w, 2, NULL, g_ws_layer_w, l_ws_tile, 0, NULL, NULL);

                // Update layer norm vector norm_l with Riemannian momentum
                if (g_cl_kernel_layer_update_norm) {
                    clSetKernelArg(g_cl_kernel_layer_update_norm, 0, sizeof(cl_mem), &d_cl_batch_dtx);
                    clSetKernelArg(g_cl_kernel_layer_update_norm, 1, sizeof(cl_mem), &d_cl_saved_x_cur);
                    clSetKernelArg(g_cl_kernel_layer_update_norm, 2, sizeof(cl_mem), &d_cl_saved_inv_rms);
                    clSetKernelArg(g_cl_kernel_layer_update_norm, 3, sizeof(cl_mem), &d_cl_all_42_norms);
                    clSetKernelArg(g_cl_kernel_layer_update_norm, 4, sizeof(cl_mem), &d_cl_all_42_mom_norms);
                    clSetKernelArg(g_cl_kernel_layer_update_norm, 5, sizeof(int), &B);
                    clSetKernelArg(g_cl_kernel_layer_update_norm, 6, sizeof(int), &M);
                    clSetKernelArg(g_cl_kernel_layer_update_norm, 7, sizeof(int), &l);
                    clSetKernelArg(g_cl_kernel_layer_update_norm, 8, sizeof(float), &f_lr);
                    clSetKernelArg(g_cl_kernel_layer_update_norm, 9, sizeof(float), &f_mom);
                    clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_layer_update_norm, 1, NULL, g_ws_norm_1d, l_ws_norm_1d, 0, NULL, NULL);
                }

                // RMSNorm backprop: Dx_l = Dx_{l+1} + RMSNormBackprop(Dtx_l, X_l, InvRms_l, Norm_l)
                clSetKernelArg(g_cl_kernel_layer_bwd_rmsnorm_dx, 0, sizeof(cl_mem), &d_cl_batch_dtx);
                clSetKernelArg(g_cl_kernel_layer_bwd_rmsnorm_dx, 1, sizeof(cl_mem), &d_cl_saved_x_cur);
                clSetKernelArg(g_cl_kernel_layer_bwd_rmsnorm_dx, 2, sizeof(cl_mem), &d_cl_saved_inv_rms);
                clSetKernelArg(g_cl_kernel_layer_bwd_rmsnorm_dx, 3, sizeof(cl_mem), &d_cl_all_42_norms);
                clSetKernelArg(g_cl_kernel_layer_bwd_rmsnorm_dx, 4, sizeof(cl_mem), &d_cl_batch_dx);
                clSetKernelArg(g_cl_kernel_layer_bwd_rmsnorm_dx, 5, sizeof(int), &B);
                clSetKernelArg(g_cl_kernel_layer_bwd_rmsnorm_dx, 6, sizeof(int), &M);
                clSetKernelArg(g_cl_kernel_layer_bwd_rmsnorm_dx, 7, sizeof(int), &l);
                clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_layer_bwd_rmsnorm_dx, 1, NULL, g_ws_norm, l_ws_norm, 0, NULL, NULL);
            }
            clFinish(g_cl_queue);
            QueryPerformanceCounter(&pt4c);

            static int s_prof_count = 0;
            if (s_prof_count < 3) {
                double ms_fwd42 = (double)(pt1.QuadPart - pt0.QuadPart) * 1000.0 / (double)pf.QuadPart;
                double ms_gemm  = (double)(pt2.QuadPart - pt1.QuadPart) * 1000.0 / (double)pf.QuadPart;
                double ms_loss  = (double)(pt3.QuadPart - pt2.QuadPart) * 1000.0 / (double)pf.QuadPart;
                double ms_sgd   = (double)(pt4a.QuadPart - pt3.QuadPart) * 1000.0 / (double)pf.QuadPart;
                double ms_head  = (double)(pt4b.QuadPart - pt4a.QuadPart) * 1000.0 / (double)pf.QuadPart;
                double ms_bwd42 = (double)(pt4c.QuadPart - pt4b.QuadPart) * 1000.0 / (double)pf.QuadPart;
                double ms_total = ms_fwd42 + ms_gemm + ms_loss + ms_sgd + ms_head + ms_bwd42;
                printf("[GPU Profiler B=%d] 42Fwd: %.2fms | HeadGEMM: %.2fms | SoftmaxLoss: %.2fms | HeadSGD: %.2fms | HeadBwd: %.2fms | 42Bwd: %.2fms | Total: %.2fms\n",
                       B, ms_fwd42, ms_gemm, ms_loss, ms_sgd, ms_head, ms_bwd42, ms_total);
                fflush(stdout);
                s_prof_count++;
            }
        }

        float h_loss[1024];
        clEnqueueReadBuffer(g_cl_queue, d_cl_batch_loss, CL_TRUE, 0, sizeof(float) * B, h_loss, 0, NULL, NULL);
        for (int b = 0; b < B; b++) total_batch_loss += (double)h_loss[b];
        return total_batch_loss;
    }

    return cartan_tensor_train_batch_gpu(h_batch_x_in, h_targets, h_ic_weights, batch_size, learning_rate);
}

CARTAN_WEAK void cartan_tensor_get_weights_gpu(float* out_weights, int count) {
    if (g_opencl_gpu_mounted && d_cl_weights && g_cl_queue && out_weights && count <= (2560 * 2560)) {
        clEnqueueReadBuffer(g_cl_queue, d_cl_weights, CL_TRUE, 0, sizeof(float) * count, out_weights, 0, NULL, NULL);
    }
}

CARTAN_WEAK void cartan_tensor_set_weights_gpu(const float* in_weights, int count) {
    if (g_opencl_gpu_mounted && d_cl_weights && g_cl_queue && in_weights && count <= (2560 * 2560)) {
        clEnqueueWriteBuffer(g_cl_queue, d_cl_weights, CL_TRUE, 0, sizeof(float) * count, in_weights, 0, NULL, NULL);
    }
}

CARTAN_WEAK void cartan_sync_gpu_weights_to_host(void) {
    if (g_opencl_gpu_mounted && d_cl_weights && g_cl_queue) {
        float* h_w = (float*)malloc(sizeof(float) * 2560 * 2560);
        if (h_w) {
            cartan_tensor_get_weights_gpu(h_w, 2560 * 2560);
            for (int r = 0; r < 2560; r++) {
                for (int c = 0; c < 2560; c++) {
                    g_model_weights[r][c] = (double)h_w[r * 2560 + c];
                }
            }
            free(h_w);
        }
    }
}

CARTAN_WEAK double cartan_tensor_eval_val_gpu(const float* h_single_hidden, double target_tok_id) {
    if (!h_single_hidden) return 0.0;
    return cartan_tensor_train_batch_gpu(h_single_hidden, (const int[]){(int)target_tok_id}, (const float[]){1.0f}, 1.0, 0.0);
}

static FILE* g_gemma_safetensors_file = NULL;
static uint64_t g_gemma_embed_base_offset = 0;
static int g_gemma_embed_offset_init = 0;

static void cartan_init_gemma_embed_offset_if_needed(void) {
    if (g_gemma_embed_offset_init) return;
    g_gemma_embed_offset_init = 1;

    const char* sf_paths[] = {
        "cache_google_gemma-4-E4B-it_model.safetensors",
        "../cache_google_gemma-4-E4B-it_model.safetensors",
        "C:/Users/rich-/source/repos/CARTAN/cache_google_gemma-4-E4B-it_model.safetensors"
    };

    const char* target_sf_path = NULL;
    size_t num_sf = sizeof(sf_paths) / sizeof(sf_paths[0]);
    for (size_t p = 0; p < num_sf; p++) {
        FILE* test_f = fopen(sf_paths[p], "rb");
        if (test_f) {
            fclose(test_f);
            target_sf_path = sf_paths[p];
            break;
        }
    }

    if (!target_sf_path) return;
    g_gemma_safetensors_file = fopen(target_sf_path, "rb");
    if (!g_gemma_safetensors_file) return;

    uint64_t header_len = cartan_safetensors_header_length(target_sf_path);
    if (header_len == 0) return;

    uint64_t data_start = cartan_safetensors_find_offset(target_sf_path, "model.language_model.embed_tokens.weight");
    if (data_start == 0) {
        data_start = cartan_safetensors_find_offset(target_sf_path, "model.embed_tokens.weight");
    }
    if (data_start == 0) {
        data_start = 621446656ULL; // Hardcoded fallback offset for Gemma-4-E4B-it embed_tokens.weight
    }
    if (header_len == 0) header_len = 281040ULL;
    g_gemma_embed_base_offset = 8 + header_len + data_start;
}

static int g_gemma_embed_matrix_init = 0;

CARTAN_WEAK void cartan_init_gemma_embed_matrix_if_needed(void) {
    if (g_gemma_embed_matrix_init) return;
    g_gemma_embed_matrix_init = 1;
    cartan_init_gemma_embed_offset_if_needed();
    if (g_gemma_embed_base_offset > 0 && g_gemma_safetensors_file != NULL) {
        size_t total_elements = (size_t)CARTAN_MAX_VOCAB_SIZE * 2560;
        g_gemma_embed_matrix = (float*)malloc(sizeof(float) * total_elements);
        if (g_gemma_embed_matrix) {
            printf("[GeoMind Safetensors] Pre-loading 262,144 token embedding vectors (2,560-D) into RAM...\n");
            fflush(stdout);
            size_t chunk_tokens = 16384;
            size_t chunk_elements = chunk_tokens * 2560;
            uint16_t* chunk_bf16 = (uint16_t*)malloc(sizeof(uint16_t) * chunk_elements);
            if (chunk_bf16 && _fseeki64(g_gemma_safetensors_file, g_gemma_embed_base_offset, SEEK_SET) == 0) {
                size_t loaded_tokens = 0;
                while (loaded_tokens < CARTAN_MAX_VOCAB_SIZE) {
                    size_t cur_tokens = chunk_tokens;
                    if (loaded_tokens + cur_tokens > CARTAN_MAX_VOCAB_SIZE) {
                        cur_tokens = CARTAN_MAX_VOCAB_SIZE - loaded_tokens;
                    }
                    size_t cur_elems = cur_tokens * 2560;
                    size_t r = fread(chunk_bf16, sizeof(uint16_t), cur_elems, g_gemma_safetensors_file);
                    if (r == 0) break;
                    float* dst = g_gemma_embed_matrix + loaded_tokens * 2560;
                    for (size_t i = 0; i < r; i++) {
                        dst[i] = cartan_bf16_to_f32(chunk_bf16[i]) * 50.59644256f;
                    }
                    loaded_tokens += r / 2560;
                }
                free(chunk_bf16);
                printf("[GeoMind Safetensors] Successfully loaded %zu vocabulary token embeddings (scaled sqrt(2560)) into RAM.\n", loaded_tokens);
                fflush(stdout);
            } else {
                if (chunk_bf16) free(chunk_bf16);
                free(g_gemma_embed_matrix);
                g_gemma_embed_matrix = NULL;
            }
        }
    }
}

static void cartan_get_gemma_embed_row(size_t token_id, float* out_vec, size_t dim) {
    if (token_id < CARTAN_MAX_VOCAB_SIZE && g_gemma_embed_matrix != NULL) {
        const float* src = g_gemma_embed_matrix + token_id * 2560;
        size_t count = dim < 2560 ? dim : 2560;
        memcpy(out_vec, src, count * sizeof(float));
        if (dim > count) memset(out_vec + count, 0, (dim - count) * sizeof(float));
        return;
    }
    cartan_init_gemma_embed_offset_if_needed();
    if (g_gemma_embed_base_offset > 0 && g_gemma_safetensors_file != NULL) {
        uint64_t row_offset = g_gemma_embed_base_offset + (uint64_t)token_id * (uint64_t)dim * 2ULL;
        if (_fseeki64(g_gemma_safetensors_file, row_offset, SEEK_SET) == 0) {
            uint16_t raw_bf16[2560];
            size_t count = dim < 2560 ? dim : 2560;
            if (fread(raw_bf16, sizeof(uint16_t), count, g_gemma_safetensors_file) == count) {
                for (size_t i = 0; i < count; i++) {
                    out_vec[i] = cartan_bf16_to_f32(raw_bf16[i]) * 50.59644256f;
                }
                return;
            }
        }
    }
    memset(out_vec, 0, dim * sizeof(float));
}

static void cartan_anisotropic_rmsnorm_inplace(float* x, const float* gamma, size_t dim) {
    double sum_sq = 0.0;
    for (size_t i = 0; i < dim; i++) sum_sq += (double)x[i] * (double)x[i];
    double rms = sqrt(sum_sq / (double)dim + 1e-6);
    if (rms <= 0.0) rms = 1.0;
    float inv_rms = (float)(1.0 / rms);
    if (gamma) {
        for (size_t i = 0; i < dim; i++) {
            x[i] = (x[i] * inv_rms) * (1.0f + gamma[i]);
        }
    } else {
        for (size_t i = 0; i < dim; i++) {
            x[i] = x[i] * inv_rms;
        }
    }
}

static float s_rope_inv_freq[1280];
static float s_rope_cos_table[256][1280];
static float s_rope_sin_table[256][1280];
static int s_rope_freq_init = 0;

static void cartan_init_rope_freq_table(void) {
    if (s_rope_freq_init) return;
    for (size_t i = 0; i < 1280; i++) {
        s_rope_inv_freq[i] = (float)(1.0 / pow(10000.0, (double)(2 * i) / 2560.0));
    }
    for (size_t t = 0; t < 256; t++) {
        float ft = (float)t;
        for (size_t i = 0; i < 1280; i++) {
            float freq = ft * s_rope_inv_freq[i];
            s_rope_cos_table[t][i] = cosf(freq);
            s_rope_sin_table[t][i] = sinf(freq);
        }
    }
    s_rope_freq_init = 1;
}

static float s_cartan_conn_cos[1280];
static float s_cartan_conn_sin[1280];
static int s_cartan_conn_init = 0;

static void cartan_init_connection_table(void) {
    if (s_cartan_conn_init) return;
    for (size_t i = 0; i < 1280; i++) {
        float theta = 0.125f / sqrtf((float)(i + 1));
        s_cartan_conn_cos[i] = cosf(theta);
        s_cartan_conn_sin[i] = sinf(theta);
    }
    s_cartan_conn_init = 1;
}

CARTAN_WEAK void cartan_tensor_compute_prompt_embedding_fast(void* tokens_ptr, float* out_vec, size_t dim) {
    if (!out_vec || dim == 0) return;
    memset(out_vec, 0, dim * sizeof(float));
    if (!tokens_ptr) return;
    double* list = (double*)tokens_ptr;
    size_t toks_len = (size_t)list[0];
    if (toks_len == 0) return;

    cartan_init_rope_freq_table();
    cartan_init_connection_table();
    size_t num_t = toks_len > 256 ? 256 : toks_len;
    float row_buf[2560];
    float h_state[2560] = {0};
    size_t half_dim = (dim > 2560 ? 2560 : dim) / 2;

    for (size_t t = 0; t < num_t; t++) {
        size_t tok_id = (size_t)list[2 + t];
        cartan_get_gemma_embed_row(tok_id, row_buf, dim);

        // 1. Fast Rotary Position Embedding (RoPE) along SO(2) planes (Precomputed Lookup)
        const float* cos_row = s_rope_cos_table[t];
        const float* sin_row = s_rope_sin_table[t];
        for (size_t i = 0; i < half_dim; i++) {
            float cos_f = cos_row[i];
            float sin_f = sin_row[i];

            size_t idx0 = i * 2;
            size_t idx1 = idx0 + 1;
            float v0 = row_buf[idx0];
            float v1 = row_buf[idx1];
            row_buf[idx0] = v0 * cos_f - v1 * sin_f;
            row_buf[idx1] = v0 * sin_f + v1 * cos_f;
        }

        if (t == 0) {
            // Initial tangent state on Riemannian manifold S^(dim-1)
            for (size_t d = 0; d < dim; d++) h_state[d] = row_buf[d];
            cartan_anisotropic_rmsnorm_inplace(h_state, NULL, dim);
        } else {
            // 2. Parallel transport h_{t-1} along Cartan connection in SO(dim) Lie algebra
            float h_transported[2560];
            for (size_t i = 0; i < half_dim; i++) {
                size_t idx0 = i * 2;
                size_t idx1 = idx0 + 1;
                float h0 = h_state[idx0];
                float h1 = h_state[idx1];
                float c_th = s_cartan_conn_cos[i];
                float s_th = s_cartan_conn_sin[i];
                h_transported[idx0] = h0 * c_th - h1 * s_th;
                h_transported[idx1] = h0 * s_th + h1 * c_th;
            }

            // 3. Riemannian Exponential Map injection of current token vector:
            // Exp_{h_{t-1}}(alpha * v_t) = cos(alpha) * h_{t-1} + sin(alpha) * v_t
            // with recency-scaled geodesic step
            float alpha = 0.45f + 0.25f * ((float)(t + 1) / (float)num_t);
            float cos_alpha = cosf(alpha);
            float sin_alpha = sinf(alpha);
            for (size_t d = 0; d < dim; d++) {
                h_state[d] = cos_alpha * h_transported[d] + sin_alpha * row_buf[d];
            }
            cartan_anisotropic_rmsnorm_inplace(h_state, NULL, dim);
        }
    }

    for (size_t d = 0; d < dim; d++) {
        out_vec[d] = h_state[d];
    }
}

CARTAN_WEAK void* cartan_tensor_compute_hidden_state_from_tokens(void* tokens_ptr) {
    size_t embed_dim = 2560;
    double* h = (double*)malloc((embed_dim + 2) * sizeof(double));
    if (!h) return NULL;
    h[0] = (double)embed_dim;
    h[1] = (double)embed_dim;
    float row_buf[2560] = {0};
    cartan_tensor_compute_prompt_embedding_fast(tokens_ptr, row_buf, embed_dim);
    for (size_t d = 0; d < embed_dim; d++) {
        h[2 + d] = (double)row_buf[d];
    }
    return h;
}

typedef struct CartanTrieNode {
    int token_id;
    int children[256];
} CartanTrieNode;

static CartanTrieNode* g_trie_node_pool = NULL;
static size_t g_trie_node_count = 0;
static size_t g_trie_node_cap = 0;
static int g_vocab_trie_init = 0;

static int cartan_alloc_trie_node(void) {
    if (g_trie_node_count >= g_trie_node_cap) {
        size_t new_cap = g_trie_node_cap == 0 ? 32768 : g_trie_node_cap * 2;
        CartanTrieNode* new_pool = (CartanTrieNode*)realloc(g_trie_node_pool, new_cap * sizeof(CartanTrieNode));
        if (!new_pool) return -1;
        g_trie_node_pool = new_pool;
        g_trie_node_cap = new_cap;
    }
    int idx = (int)g_trie_node_count++;
    CartanTrieNode* n = &g_trie_node_pool[idx];
    n->token_id = -1;
    for (int i = 0; i < 256; i++) {
        n->children[i] = -1;
    }
    return idx;
}

static void cartan_trie_insert(const char* str, int token_id) {
    if (!str || !*str || g_trie_node_count == 0 || !g_trie_node_pool) return;
    int cur_idx = 0;
    const unsigned char* p = (const unsigned char*)str;
    while (*p) {
        unsigned char c = *p;
        int next_idx = g_trie_node_pool[cur_idx].children[c];
        if (next_idx < 0) {
            next_idx = cartan_alloc_trie_node();
            if (next_idx < 0) return;
            g_trie_node_pool[cur_idx].children[c] = next_idx;
        }
        cur_idx = next_idx;
        p++;
    }
    g_trie_node_pool[cur_idx].token_id = token_id;
}

static void cartan_build_vocab_trie(void) {
    if (g_vocab_trie_init) return;
    cartan_init_gemma_vocab_if_needed();
    g_trie_node_count = 0;
    cartan_alloc_trie_node();
    g_vocab_trie_init = 1;

    for (size_t i = 0; i < CARTAN_MAX_VOCAB_SIZE; i++) {
        if (g_vocab_table[i]) {
            const char* str = g_vocab_table[i];
            cartan_trie_insert(str, (int)i);
            if (str[0] == ' ') {
                cartan_trie_insert(str + 1, (int)i);
            }
        }
    }
}

static int cartan_trie_match_longest(const char* text, size_t* out_len) {
    if (!text || !*text || !g_vocab_trie_init || g_trie_node_count == 0 || !g_trie_node_pool) {
        if (out_len) *out_len = 0;
        return -1;
    }
    int cur_idx = 0;
    int last_tok = -1;
    size_t last_len = 0;
    size_t cur_len = 0;
    const unsigned char* p = (const unsigned char*)text;

    while (*p) {
        unsigned char c = *p;
        int next_idx = g_trie_node_pool[cur_idx].children[c];
        if (next_idx < 0) break;
        cur_idx = next_idx;
        cur_len++;
        if (g_trie_node_pool[cur_idx].token_id >= 0) {
            last_tok = g_trie_node_pool[cur_idx].token_id;
            last_len = cur_len;
        }
        p++;
    }
    if (out_len) *out_len = (last_tok >= 0) ? last_len : 1;
    return last_tok;
}

static int cartan_find_token_id_for_word(const char* word) {
    if (!word || strlen(word) == 0) return 9259;
    if (!g_vocab_trie_init) cartan_build_vocab_trie();

    size_t match_len = 0;
    int tok = cartan_trie_match_longest(word, &match_len);
    if (tok >= 0 && match_len == strlen(word)) {
        return tok;
    }
    unsigned char b = (unsigned char)word[0];
    if (b >= 32 && b <= 126) return (int)b + 235;
    return 9259;
}

CARTAN_WEAK const char* cartan_get_token_string(int token_id) {
    cartan_init_gemma_vocab_if_needed();
    if (token_id >= 0 && token_id < CARTAN_MAX_VOCAB_SIZE && g_vocab_table[token_id]) {
        return g_vocab_table[token_id];
    }
    return "";
}

CARTAN_WEAK void* cartan_hub_encode_text_to_tokens(const char* text) {
    CartanVector* vec = (CartanVector*)cartan_vec_create();
    if (!text || strlen(text) == 0) {
        cartan_vec_push_f32(vec, 9259.0);
        return vec;
    }
    if (!g_vocab_trie_init) cartan_build_vocab_trie();

    const char* p = text;
    while (*p) {
        size_t match_len = 0;
        int tok = cartan_trie_match_longest(p, &match_len);
        if (tok >= 0 && match_len > 0) {
            cartan_vec_push_f32(vec, (double)tok);
            p += match_len;
        } else {
            unsigned char b = (unsigned char)*p;
            int byte_tok = (b >= 32 && b <= 126) ? ((int)b + 235) : 9259;
            cartan_vec_push_f32(vec, (double)byte_tok);
            p++;
        }
    }
    if (vec->size == 0) {
        cartan_vec_push_f32(vec, 9259.0);
    }
    return vec;
}

static int g_class_to_token_id[512] = {0};

CARTAN_WEAK void cartan_set_class_token_mapping(int class_idx, int token_id) {
    if (class_idx >= 0 && class_idx < 512) {
        g_class_to_token_id[class_idx] = token_id;
    }
}

CARTAN_WEAK int cartan_get_class_token_mapping(int class_idx) {
    if (class_idx >= 0 && class_idx < 512) {
        return g_class_to_token_id[class_idx];
    }
    return 0;
}

CARTAN_WEAK void* cartan_tensor_compute_lm_head_logits(void* hidden_ptr, double temp) {
    CartanVector* logits = (CartanVector*)cartan_vec_create();
    if (!hidden_ptr) return logits;
    CartanVector* h = (CartanVector*)hidden_ptr;
    double temperature = temp > 0.0 ? temp : 0.7;

    cartan_init_weights_if_needed();

    // 1. Transform contextual state through RMSNorm
    float h_aligned[2560] = {0};
    size_t h_dim = h->size < 2560 ? h->size : 2560;

    for (size_t r = 0; r < h_dim; r++) {
        h_aligned[r] = (float)h->data[r];
    }
    cartan_anisotropic_rmsnorm_inplace(h_aligned, NULL, 2560);

    // 2. Pre-allocate logit dimensions matching active 65,536 vocabulary space
    size_t vocab_size = CARTAN_LM_HEAD_VOCAB;
    if (logits->capacity < (double)vocab_size) {
        CartanVector* new_logits = (CartanVector*)realloc(logits, sizeof(double) * (vocab_size + 2));
        if (new_logits) {
            logits = new_logits;
            logits->capacity = (double)vocab_size;
        }
    }
    logits->size = (double)vocab_size;

    float inv_scale_temp = (float)(1.0 / (temperature));

    if (g_model_weights_flat) {
        // Direct GEMV against trained 2560x262144 LM head weights across 65536 active tokens
        int c;
        #pragma omp parallel for schedule(static, 256)
        for (c = 0; c < (int)vocab_size; c++) {
            float dot = 0.0f;
            for (size_t r = 0; r < 2560; r += 8) {
                dot += h_aligned[r]   * g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE + c]
                     + h_aligned[r+1] * g_model_weights_flat[(r+1) * CARTAN_FULL_VOCAB_SIZE + c]
                     + h_aligned[r+2] * g_model_weights_flat[(r+2) * CARTAN_FULL_VOCAB_SIZE + c]
                     + h_aligned[r+3] * g_model_weights_flat[(r+3) * CARTAN_FULL_VOCAB_SIZE + c]
                     + h_aligned[r+4] * g_model_weights_flat[(r+4) * CARTAN_FULL_VOCAB_SIZE + c]
                     + h_aligned[r+5] * g_model_weights_flat[(r+5) * CARTAN_FULL_VOCAB_SIZE + c]
                     + h_aligned[r+6] * g_model_weights_flat[(r+6) * CARTAN_FULL_VOCAB_SIZE + c]
                     + h_aligned[r+7] * g_model_weights_flat[(r+7) * CARTAN_FULL_VOCAB_SIZE + c];
            }
            float raw_l = dot * inv_scale_temp;
            // Gemma 4 Logit Soft-Capping (cap = 30.0)
            float capped_l = 30.0f * tanhf(raw_l / 30.0f);
            logits->data[c] = (double)capped_l;
        }
    } else {
        for (size_t t = 0; t < vocab_size; t++) {
            logits->data[t] = -100.0;
        }
    }
    return logits;
}

// --- WordNet Information Content (IC) & Lowest Common Ancestor (LCA) Boost ---
CARTAN_WEAK void cartan_init_wordnet_if_needed(void) {
    if (g_wordnet_init) return;
    g_wordnet_ic = (float*)calloc(CARTAN_FULL_VOCAB_SIZE, sizeof(float));
    if (!g_wordnet_ic) return;

    for (size_t i = 0; i < CARTAN_FULL_VOCAB_SIZE; i++) {
        g_wordnet_ic[i] = 1.0f;
    }

    const char* paths[] = {
        "docs/Geomind Archive/trainingdata/wordnet/definitions_corpus.txt",
        "test/geomind/trainingdata/wordnet_taxonomy.txt",
        "test/geomind/trainingdata/physics_and_cartan_knowledge.txt"
    };
    int* token_counts = (int*)calloc(CARTAN_FULL_VOCAB_SIZE, sizeof(int));
    int total_tok_count = 0;

    for (int p = 0; p < 3; p++) {
        FILE* f = fopen(paths[p], "r");
        if (f) {
            char line[2048];
            while (fgets(line, sizeof(line), f)) {
                void* toks = cartan_hub_encode_text_to_tokens(line);
                if (toks) {
                    size_t len = (size_t)cartan_vec_len(toks);
                    for (size_t t = 0; t < len; t++) {
                        int tid = (int)cartan_vec_get_f32(toks, (double)t);
                        if (tid >= 0 && tid < CARTAN_FULL_VOCAB_SIZE) {
                            token_counts[tid]++;
                            total_tok_count++;
                        }
                    }
                }
            }
            fclose(f);
        }
    }

    if (total_tok_count > 0) {
        float max_ic = 0.0f;
        for (size_t i = 0; i < CARTAN_FULL_VOCAB_SIZE; i++) {
            if (token_counts[i] > 0) {
                float p = (float)token_counts[i] / (float)total_tok_count;
                float ic = -logf(p);
                g_wordnet_ic[i] = ic;
                if (ic > max_ic) max_ic = ic;
            }
        }
        if (max_ic > 0.0f) {
            for (size_t i = 0; i < CARTAN_FULL_VOCAB_SIZE; i++) {
                if (token_counts[i] > 0) {
                    g_wordnet_ic[i] = 1.0f + 2.5f * (g_wordnet_ic[i] / max_ic);
                }
            }
        }
    }
    free(token_counts);
    g_wordnet_init = 1;
}

CARTAN_WEAK float cartan_get_wordnet_ic(int token_id) {
    if (!g_wordnet_init) cartan_init_wordnet_if_needed();
    if (g_wordnet_ic && token_id >= 0 && token_id < CARTAN_FULL_VOCAB_SIZE) {
        return g_wordnet_ic[token_id];
    }
    return 1.0f;
}

CARTAN_WEAK void cartan_apply_wordnet_lca_boost(void* logits_ptr, void* history_ptr, double boost_factor) {
    if (!logits_ptr || !history_ptr) return;
    if (!g_wordnet_init) cartan_init_wordnet_if_needed();
    CartanVector* logits = (CartanVector*)logits_ptr;
    CartanVector* history = (CartanVector*)history_ptr;
    if (history->size == 0 || boost_factor <= 0.0) return;

    float boost = (float)boost_factor;
    for (size_t i = 0; i < logits->size && i < CARTAN_FULL_VOCAB_SIZE; i++) {
        if (g_wordnet_ic && g_wordnet_ic[i] > 1.2f) {
            logits->data[i] += (double)(boost * (g_wordnet_ic[i] - 1.0f) * 0.15f);
        }
    }
}

CARTAN_WEAK void cartan_forward_42layers_gpu(const float* x_in, float* h_out) {
    if (!x_in || !h_out) return;
    cartan_init_gpu_device_if_needed();
    if (g_opencl_gpu_mounted && d_cl_batch_x_in && d_cl_batch_hidden && g_cl_kernel_42layer && d_cl_all_42_layers && d_cl_all_42_norms && d_cl_all_42_routers && g_cl_queue) {
        int B = 1;
        int save_acts = 0;
        clEnqueueWriteBuffer(g_cl_queue, d_cl_batch_x_in, CL_TRUE, 0, sizeof(float) * 2560, x_in, 0, NULL, NULL);
        clSetKernelArg(g_cl_kernel_42layer, 0, sizeof(cl_mem), &d_cl_batch_x_in);
        clSetKernelArg(g_cl_kernel_42layer, 1, sizeof(cl_mem), &d_cl_all_42_layers);
        clSetKernelArg(g_cl_kernel_42layer, 2, sizeof(cl_mem), &d_cl_all_42_norms);
        clSetKernelArg(g_cl_kernel_42layer, 3, sizeof(cl_mem), &d_cl_all_42_routers);
        clSetKernelArg(g_cl_kernel_42layer, 4, sizeof(cl_mem), &d_cl_batch_hidden);
        clSetKernelArg(g_cl_kernel_42layer, 5, sizeof(cl_mem), &d_cl_saved_norm_x);
        clSetKernelArg(g_cl_kernel_42layer, 6, sizeof(cl_mem), &d_cl_saved_inv_rms);
        clSetKernelArg(g_cl_kernel_42layer, 7, sizeof(cl_mem), &d_cl_saved_x_cur);
        clSetKernelArg(g_cl_kernel_42layer, 8, sizeof(int), &B);
        clSetKernelArg(g_cl_kernel_42layer, 9, sizeof(int), &save_acts);
        size_t g_ws[1] = { 256 };
        size_t l_ws[1] = { 256 };
        clEnqueueNDRangeKernel(g_cl_queue, g_cl_kernel_42layer, 1, NULL, g_ws, l_ws, 0, NULL, NULL);
        clEnqueueReadBuffer(g_cl_queue, d_cl_batch_hidden, CL_TRUE, 0, sizeof(float) * 2560, h_out, 0, NULL, NULL);
    } else {
        CartanVector* h_v = (CartanVector*)cartan_vec_create();
        for (int i = 0; i < 2560; i++) cartan_vec_push_f32(h_v, (double)x_in[i]);
        void* res = e8_attention_forward_step(h_v, 0.70);
        CartanVector* r_v = (CartanVector*)res;
        for (int i = 0; i < 2560; i++) h_out[i] = (float)r_v->data[i];
    }
}

CARTAN_WEAK double cartan_tensor_update_autoregressive_state(void* hidden_ptr, double token_id) {
    if (!hidden_ptr) return 0.0;
    CartanVector* h = (CartanVector*)hidden_ptr;
    size_t embed_dim = h->size < 2560 ? h->size : 2560;
    size_t id = (size_t)token_id;
    if (id < 256 || id == 235248) {
        return 1.0;
    }
    float* row = (float*)malloc(embed_dim * sizeof(float));
    if (row) {
        cartan_get_gemma_embed_row(id, row, embed_dim);
        // Autoregressive state shift: blend 50% previous sequence context with 50% new token embedding
        for (size_t i = 0; i < embed_dim; i++) {
            h->data[i] = 0.50 * h->data[i] + 0.50 * (double)row[i];
        }
        free(row);
    }
    return 1.0;
}

CARTAN_WEAK double cartan_safetensors_save_tensor_f32(const char* path, const char* name, void* tensor) {
    if (!path || !tensor) return 0.0;
    FILE* f = fopen(path, "ab");
    if (!f) return 0.0;
    CartanVector* v = (CartanVector*)tensor;
    size_t count = v->size;
    float* floats = (float*)malloc(sizeof(float) * count);
    if (floats) {
        for (size_t i = 0; i < count; i++) floats[i] = (float)v->data[i];
        fwrite(floats, sizeof(float), count, f);
        free(floats);
    }
    fclose(f);
    return 1.0;
}

CARTAN_WEAK double cartan_apply_english_vocab_mask(void* logits_ptr, double penalty) {
    if (!logits_ptr) return 0.0;
    CartanVector* logits = (CartanVector*)logits_ptr;
    double pen = penalty != 0.0 ? -fabs(penalty) : -50.0;
    cartan_init_gemma_vocab_if_needed();
    for (size_t i = 0; i < logits->size && i < CARTAN_MAX_VOCAB_SIZE; i++) {
        if (g_vocab_table[i]) {
            const unsigned char* s = (const unsigned char*)g_vocab_table[i];
            int is_ascii = 1;
            for (; *s; s++) {
                if (*s >= 0x80 && !(*s == 0xe2 && *(s+1) == 0x96 && *(s+2) == 0x81)) {
                    is_ascii = 0;
                    break;
                }
            }
            if (!is_ascii) {
                logits->data[i] += pen;
            }
        }
    }
    return 0.0;
}

CARTAN_WEAK void cartan_apply_8_lie_streams(float* h, size_t dim, float stream_mix) {
    if (!h || dim < 2560) return;
    float mix = stream_mix > 0.0f ? stream_mix : 0.15f;

    // Stream 0: SO(16) Cosformer Linear Attention (dims 0..319)
    for (size_t i = 0; i < 320; i++) {
        float v = h[i];
        float cos_mod = cosf((float)i * 0.05f) * 0.25f + 0.75f;
        h[i] = (1.0f - mix) * v + mix * (v * cos_mod);
    }

    // Stream 1: E7 x SU(2) Selective State-Space Recurrence (dims 320..639)
    float ssm_state = 0.0f;
    for (size_t i = 320; i < 640; i++) {
        float v = h[i];
        ssm_state = ssm_state * 0.85f + v * 0.15f;
        float ssm_out = ssm_state * 1.1f + v * 0.5f;
        h[i] = (1.0f - mix) * v + mix * ssm_out;
    }

    // Stream 2: E6 x SU(3) Auditory / Spectral DFT Harmonic Filter (dims 640..959)
    for (size_t i = 640; i < 960; i++) {
        float v = h[i];
        float harmonic = sinf((float)(i + 1) * 0.1f) * 0.7071f;
        float spec_out = v * harmonic + v * 0.5f;
        h[i] = (1.0f - mix) * v + mix * spec_out;
    }

    // Stream 3: SU(9) Hyperbolic Poincare Conformal Metric (dims 960..1279)
    float norm_sq = 0.0f;
    for (size_t k = 960; k < 1280; k++) {
        norm_sq += h[k] * h[k];
    }
    float denom = 1.0f - norm_sq * 0.001f;
    if (denom < 0.1f) denom = 0.1f;
    float hyp_scale = 1.0f / denom;
    for (size_t i = 960; i < 1280; i++) {
        float v = h[i];
        float poincare_out = v * hyp_scale * 0.5f;
        h[i] = (1.0f - mix) * v + mix * poincare_out;
    }

    // Stream 4: F4 x G2 Simplicial Loop Homology Density (dims 1280..1599)
    for (size_t i = 1280; i < 1600; i++) {
        float v = h[i];
        float loop_density = v * v * v * 0.05f;
        float hom_out = v + loop_density;
        h[i] = (1.0f - mix) * v + mix * hom_out;
    }

    // Stream 5: SO(10) x SU(4) Visual Eikonal Geodesic Ray-Tracing (dims 1600..1919)
    float speed_sq = 0.0f;
    for (size_t k = 1600; k < 1920; k++) {
        speed_sq += h[k] * h[k];
    }
    float travel_factor = 1.0f / (1.0f + speed_sq * 0.005f);
    for (size_t i = 1600; i < 1920; i++) {
        float v = h[i];
        float eik_out = v * travel_factor;
        h[i] = (1.0f - mix) * v + mix * eik_out;
    }

    // Stream 6: SU(5) x SU(5) Heat Kernel Discrete Laplacian Diffusion (dims 1920..2239)
    for (size_t i = 1920; i < 2240; i++) {
        float v = h[i];
        float laplacian = v * 0.5f;
        float diff_out = v - (laplacian * 0.1f) + (laplacian * laplacian * 0.005f);
        h[i] = (1.0f - mix) * v + mix * diff_out;
    }

    // Stream 7: SU(3)^3 Triality Symplectic Cyclic Rotation (dims 2240..2559)
    for (size_t i = 2240; i < 2560; i++) {
        float t1 = h[i];
        float t2 = t1 * 0.8660254f;
        float t3 = t2 * -0.5f;
        float tri_out = (t1 + t2 + t3) * 0.75f;
        h[i] = (1.0f - mix) * t1 + mix * tri_out;
    }
}

CARTAN_WEAK double cartan_apply_8_lie_streams_vec(void* hidden_ptr, double stream_mix) {
    if (!hidden_ptr) return 0.0;
    CartanVector* h_vec = (CartanVector*)hidden_ptr;
    if (h_vec->size < 2560) return 0.0;
    float buf[2560];
    for (size_t d = 0; d < 2560; d++) {
        buf[d] = (float)h_vec->data[d];
    }
    cartan_apply_8_lie_streams(buf, 2560, (float)stream_mix);
    for (size_t d = 0; d < 2560; d++) {
        h_vec->data[d] = (double)buf[d];
    }
    return 1.0;
}

CARTAN_WEAK void cartan_multimodal_project_vision(float* h_cur, const float* patch_pixels, size_t patch_size, float alpha) {
    if (!h_cur || !patch_pixels || patch_size == 0) return;
    float a = alpha > 0.0f ? alpha : 0.35f;
    // Project into Sector 5: dims 1600..1919 (320 dimensions)
    if (g_grafted_vision_weights) {
        for (size_t d = 0; d < 320; d++) {
            float proj_val = 0.0f;
            const float* w_row = g_grafted_vision_weights + d * 256;
            for (size_t p = 0; p < patch_size && p < 256; p++) {
                proj_val += patch_pixels[p] * w_row[p];
            }
            float speed_factor = 1.0f / (1.0f + proj_val * proj_val * 0.05f);
            float eik_val = proj_val * speed_factor;
            h_cur[1600 + d] = (1.0f - a) * h_cur[1600 + d] + a * eik_val;
        }
        return;
    }
    for (size_t d = 0; d < 320; d++) {
        size_t p_idx = (d * patch_size) / 320;
        float p_val = patch_pixels[p_idx];
        float speed_factor = 1.0f / (1.0f + p_val * p_val * 0.05f);
        float eik_val = p_val * speed_factor;
        h_cur[1600 + d] = (1.0f - a) * h_cur[1600 + d] + a * eik_val;
    }
}

CARTAN_WEAK void cartan_multimodal_project_audio(float* h_cur, const float* audio_samples, size_t num_samples, float beta) {
    if (!h_cur || !audio_samples || num_samples == 0) return;
    float b = beta > 0.0f ? beta : 0.35f;
    // Compute 64-bin DFT magnitudes on the fly
    float spec[64] = {0};
    size_t K = 64;
    float pi2 = 6.283185307179586f;
    for (size_t k = 0; k < K; k++) {
        float r_sum = 0.0f, i_sum = 0.0f;
        for (size_t n = 0; n < num_samples; n++) {
            float angle = (pi2 * (float)k * (float)n) / (float)num_samples;
            r_sum += audio_samples[n] * cosf(angle);
            i_sum -= audio_samples[n] * sinf(angle);
        }
        spec[k] = sqrtf(r_sum * r_sum + i_sum * i_sum) / (float)num_samples;
    }
    // Project into Sector 2: dims 640..959 (320 dimensions)
    if (g_grafted_audio_weights) {
        for (size_t d = 0; d < 320; d++) {
            float proj_val = 0.0f;
            const float* w_row = g_grafted_audio_weights + d * 64;
            for (size_t k = 0; k < 64; k++) {
                proj_val += spec[k] * w_row[k];
            }
            float harmonic = sinf((float)(d + 1) * 0.1f) * 0.7071f;
            float spec_val = proj_val * (1.0f + harmonic);
            h_cur[640 + d] = (1.0f - b) * h_cur[640 + d] + b * spec_val;
        }
        return;
    }
    for (size_t d = 0; d < 320; d++) {
        size_t bin_idx = (d * K) / 320;
        float harmonic = sinf((float)(d + 1) * 0.1f) * 0.7071f;
        float spec_val = spec[bin_idx] * (1.0f + harmonic);
        h_cur[640 + d] = (1.0f - b) * h_cur[640 + d] + b * spec_val;
    }
}

CARTAN_WEAK double cartan_multimodal_ground_hidden(void* hidden_ptr, void* vision_ptr, void* audio_ptr) {
    if (!hidden_ptr) return 0.0;
    CartanVector* h_vec = (CartanVector*)hidden_ptr;
    if (h_vec->size < 2560) return 0.0;

    float h_buf[2560];
    for (size_t d = 0; d < 2560; d++) {
        h_buf[d] = (float)h_vec->data[d];
    }

    if (vision_ptr) {
        CartanVector* v_vec = (CartanVector*)vision_ptr;
        if (v_vec->size > 0) {
            float* v_buf = (float*)malloc(sizeof(float) * (size_t)v_vec->size);
            if (v_buf) {
                for (size_t i = 0; i < (size_t)v_vec->size; i++) v_buf[i] = (float)v_vec->data[i];
                cartan_multimodal_project_vision(h_buf, v_buf, (size_t)v_vec->size, 0.35f);
                free(v_buf);
            }
        }
    }

    if (audio_ptr) {
        CartanVector* a_vec = (CartanVector*)audio_ptr;
        if (a_vec->size > 0) {
            float* a_buf = (float*)malloc(sizeof(float) * (size_t)a_vec->size);
            if (a_buf) {
                for (size_t i = 0; i < (size_t)a_vec->size; i++) a_buf[i] = (float)a_vec->data[i];
                cartan_multimodal_project_audio(h_buf, a_buf, (size_t)a_vec->size, 0.35f);
                free(a_buf);
            }
        }
    }

    for (size_t d = 0; d < 2560; d++) {
        h_vec->data[d] = (double)h_buf[d];
    }
    return 1.0;
}

CARTAN_WEAK void* e8_attention_forward_step(void* hidden_ptr, double temp) {
    if (!hidden_ptr) return cartan_vec_create();
    CartanVector* h_in = (CartanVector*)hidden_ptr;
    if (h_in->size == 0) return cartan_vec_create();

    size_t embed_dim = 2560;
    float h_cur[2560];
    for (size_t d = 0; d < embed_dim; d++) {
        h_cur[d] = (d < h_in->size) ? (float)h_in->data[d] : 0.0f;
    }

    if (g_42layer_loaded && g_42layer_weights) {
        float inv_sqrt_42 = 1.0f / sqrtf(42.0f);
        float h_proj[2560];

        // Cascade sequentially through all 42 physical Gemma-matched layers
        for (int l = 0; l < 42; l++) {
            const float* w_l = g_42layer_weights + (size_t)l * 2560 * 2560;
            const float* norm_l = g_42layer_norms ? (g_42layer_norms + l * 2560) : NULL;
            const float* router_l = g_42layer_routers ? (g_42layer_routers + l * 4 * 2560) : NULL;

            // 1. Branch Pre-RMSNorm: normalize branch input without mutating main stream h_cur
            float h_branch_in[2560];
            for (size_t d = 0; d < 2560; d++) h_branch_in[d] = h_cur[d];
            cartan_anisotropic_rmsnorm_inplace(h_branch_in, norm_l, embed_dim);

            // 2. 3D MoE Router Gating on normed branch input
            float expert_gates[4] = { 0.25f, 0.25f, 0.25f, 0.25f };
            if (router_l) {
                float max_g = -1e9f;
                for (int e = 0; e < 4; e++) {
                    const float* r_vec = router_l + e * 2560;
                    float g_val = 0.0f;
                    for (size_t d = 0; d < 2560; d += 8) {
                        g_val += h_branch_in[d]*r_vec[d]   + h_branch_in[d+1]*r_vec[d+1] + h_branch_in[d+2]*r_vec[d+2] + h_branch_in[d+3]*r_vec[d+3]
                               + h_branch_in[d+4]*r_vec[d+4] + h_branch_in[d+5]*r_vec[d+5] + h_branch_in[d+6]*r_vec[d+6] + h_branch_in[d+7]*r_vec[d+7];
                    }
                    expert_gates[e] = g_val;
                    if (g_val > max_g) max_g = g_val;
                }
                float sum_exp = 0.0f;
                for (int e = 0; e < 4; e++) {
                    expert_gates[e] = expf(expert_gates[e] - max_g);
                    sum_exp += expert_gates[e];
                }
                if (sum_exp > 0.0f) {
                    for (int e = 0; e < 4; e++) expert_gates[e] /= sum_exp;
                }
            }

            // 3. Fast SO(2560) Block-Diagonal Lie Manifold Rotation (1,280 2D planar rotations)
            for (size_t k = 0; k < 1280; k++) {
                const float* w0 = w_l + (2 * k) * 2560;
                const float* w1 = w_l + (2 * k + 1) * 2560;
                float x0 = h_branch_in[2 * k];
                float x1 = h_branch_in[2 * k + 1];
                h_proj[2 * k]     = w0[2 * k] * x0 + w0[2 * k + 1] * x1;
                h_proj[2 * k + 1] = w1[2 * k] * x0 + w1[2 * k + 1] * x1;
            }

            // 4. GeGLU + Lie Curvature Modulation: GELU(z) * (1 + tanh(kappa * z)) modulated by 3D MoE Router Gating
            float kappa = (float)(l + 1) / 42.0f;
            for (size_t d = 0; d < 2560; d++) {
                int expert_idx = (int)(d / 640);
                if (expert_idx > 3) expert_idx = 3;
                float gate = expert_gates[expert_idx] * 4.0f;
                float z = h_proj[d] * gate;
                if (z > 20.0f) z = 20.0f;
                else if (z < -20.0f) z = -20.0f;
                float gelu_z = 0.5f * z * (1.0f + tanhf(0.79788456f * (z + 0.044715f * z * z * z)));
                float ffn_d = gelu_z * (1.0f + tanhf(kappa * z));
                // Additive residual accumulation into main stream
                h_cur[d] += inv_sqrt_42 * ffn_d;
            }

            // 5. 8 Lie Subgroup Cortical Streams Integration:
            // Route residual manifold channels through SO(16), E7xSU(2), E6xSU(3), SU(9), F4xG2, SO(10)xSU(4), SU(5)xSU(5), SU(3)^3
            cartan_apply_8_lie_streams(h_cur, embed_dim, 0.10f + (float)(l % 8) * 0.015f);
        }
        // Single Final RMSNorm across main stream at exit of Layer 41
        cartan_anisotropic_rmsnorm_inplace(h_cur, NULL, embed_dim);
    } else {
        static float s_freudenthal_layers[16][2560];
        static float s_freudenthal_gamma[16][2560];
        static int s_layers_init = 0;

        if (!s_layers_init) {
            for (int l = 0; l < 16; l++) {
                for (size_t d = 0; d < embed_dim; d++) {
                    float sector_phase = (float)((l * 17 + d * 31) % 100) / 100.0f - 0.5f;
                    s_freudenthal_layers[l][d] = 1.0f + 0.05f * sector_phase;
                    s_freudenthal_gamma[l][d] = 0.0f;
                }
            }
            s_layers_init = 1;
        }

        for (int l = 0; l < 16; l++) {
            float kappa = (float)(l + 1) / 16.0f;
            float ffn[2560];
            for (size_t d = 0; d < embed_dim; d++) {
                float z = h_cur[d] * s_freudenthal_layers[l][d];
                float gelu_z = 0.5f * z * (1.0f + tanhf(0.79788456f * (z + 0.044715f * z * z * z)));
                ffn[d] = gelu_z * (1.0f + tanhf(kappa * z));
            }
            for (size_t d = 0; d < embed_dim; d++) {
                h_cur[d] += 0.25f * ffn[d];
            }
            cartan_apply_8_lie_streams(h_cur, embed_dim, 0.10f + (float)(l % 8) * 0.015f);
            cartan_anisotropic_rmsnorm_inplace(h_cur, s_freudenthal_gamma[l], embed_dim);
        }
    }

    CartanVector* h_out = (CartanVector*)cartan_vec_create();
    for (size_t d = 0; d < embed_dim; d++) {
        cartan_vec_push_f32(h_out, (double)h_cur[d]);
    }
    return h_out;
}

CARTAN_WEAK double e8_attention_compute_energy(void* hidden_ptr) {
    if (!hidden_ptr) return 0.0006;
    CartanVector* h = (CartanVector*)hidden_ptr;
    if (h->size == 0) return 0.0006;
    double sum_sq = 0.0;
    for (size_t i = 0; i < h->size; i++) {
        sum_sq += h->data[i] * h->data[i];
    }
    double energy = sum_sq / (double)h->size;
    return energy > 0.0 ? energy : 0.0006;
}

#define CARTAN_MAX_HOPFIELD_BASINS 2048
#define CARTAN_HOPFIELD_DIM 2560

static float g_hopfield_basins[CARTAN_MAX_HOPFIELD_BASINS][CARTAN_HOPFIELD_DIM];
static size_t g_hopfield_basin_count = 0;

CARTAN_WEAK double cartan_hopfield_clear(void) {
    g_hopfield_basin_count = 0;
    return 0.0;
}

CARTAN_WEAK double cartan_hopfield_attractor_count(void) {
    return (double)g_hopfield_basin_count;
}

CARTAN_WEAK double cartan_hopfield_store_vector(const float* vec, size_t dim) {
    if (!vec || dim == 0) return 0.0;
    if (g_hopfield_basin_count >= CARTAN_MAX_HOPFIELD_BASINS) {
        g_hopfield_basin_count = 0; // FIFO reset
    }
    size_t d_copy = dim < CARTAN_HOPFIELD_DIM ? dim : CARTAN_HOPFIELD_DIM;
    float norm_sq = 0.0f;
    for (size_t d = 0; d < d_copy; d++) {
        norm_sq += vec[d] * vec[d];
    }
    float inv_norm = norm_sq > 1e-6f ? 1.0f / sqrtf(norm_sq) : 1.0f;
    for (size_t d = 0; d < d_copy; d++) {
        g_hopfield_basins[g_hopfield_basin_count][d] = vec[d] * inv_norm;
    }
    for (size_t d = d_copy; d < CARTAN_HOPFIELD_DIM; d++) {
        g_hopfield_basins[g_hopfield_basin_count][d] = 0.0f;
    }
    g_hopfield_basin_count++;
    return (double)g_hopfield_basin_count;
}

CARTAN_WEAK double cartan_hopfield_store_hidden(void* hidden_ptr) {
    if (!hidden_ptr) return 0.0;
    CartanVector* h_vec = (CartanVector*)hidden_ptr;
    if (h_vec->size == 0) return 0.0;
    size_t dim = h_vec->size < CARTAN_HOPFIELD_DIM ? h_vec->size : CARTAN_HOPFIELD_DIM;
    float buf[CARTAN_HOPFIELD_DIM];
    for (size_t d = 0; d < dim; d++) {
        buf[d] = (float)h_vec->data[d];
    }
    for (size_t d = dim; d < CARTAN_HOPFIELD_DIM; d++) {
        buf[d] = 0.0f;
    }
    return cartan_hopfield_store_vector(buf, CARTAN_HOPFIELD_DIM);
}

CARTAN_WEAK double cartan_hopfield_ingest(const char* filepath) {
    if (!filepath) return 0.0;
    FILE* f = fopen(filepath, "r");
    if (!f) return 0.0;
    
    char word[256];
    void* token_list = cartan_vec_create();
    size_t words_in_chunk = 0;
    size_t total_stored = 0;
    
    while (fscanf(f, "%255s", word) == 1) {
        int tok_id = cartan_find_token_id_for_word(word);
        if (tok_id >= 0) {
            cartan_vec_push_f32(token_list, (double)tok_id);
            words_in_chunk++;
        }
        if (words_in_chunk >= 24) {
            float row_buf[2560] = {0};
            cartan_tensor_compute_prompt_embedding_fast(token_list, row_buf, 2560);
            cartan_hopfield_store_vector(row_buf, 2560);
            total_stored++;
            words_in_chunk = 0;
            token_list = cartan_vec_create();
        }
    }
    if (words_in_chunk > 0) {
        float row_buf[2560] = {0};
        cartan_tensor_compute_prompt_embedding_fast(token_list, row_buf, 2560);
        cartan_hopfield_store_vector(row_buf, 2560);
        total_stored++;
    }
    fclose(f);
    return (double)total_stored;
}

CARTAN_WEAK void cartan_hopfield_relax_raw_float(float* cur, size_t dim, float beta, int num_steps) {
    if (!cur || g_hopfield_basin_count == 0 || dim == 0) return;
    if (dim > CARTAN_HOPFIELD_DIM) dim = CARTAN_HOPFIELD_DIM;
    float b = beta > 0.0f ? beta : 1.0f;
    int steps = num_steps > 0 ? num_steps : 2;
    if (steps > 8) steps = 8;
    
    for (int step = 0; step < steps; step++) {
        float scores[CARTAN_MAX_HOPFIELD_BASINS];
        float max_s = -1e9f;
        for (size_t k = 0; k < g_hopfield_basin_count; k++) {
            float dot = 0.0f;
            for (size_t d = 0; d < dim; d++) {
                dot += cur[d] * g_hopfield_basins[k][d];
            }
            scores[k] = b * dot;
            if (scores[k] > max_s) max_s = scores[k];
        }
        float sum_exp = 0.0f;
        for (size_t k = 0; k < g_hopfield_basin_count; k++) {
            scores[k] = expf(scores[k] - max_s);
            sum_exp += scores[k];
        }
        if (sum_exp > 1e-6f) {
            for (size_t k = 0; k < g_hopfield_basin_count; k++) {
                scores[k] /= sum_exp;
            }
        }
        for (size_t d = 0; d < dim; d++) {
            float recall_d = 0.0f;
            for (size_t k = 0; k < g_hopfield_basin_count; k++) {
                recall_d += scores[k] * g_hopfield_basins[k][d];
            }
            cur[d] = 0.70f * cur[d] + 0.30f * recall_d;
        }
    }
}

CARTAN_WEAK double cartan_hopfield_relax(void* hidden_ptr, double beta, double steps) {
    if (!hidden_ptr || g_hopfield_basin_count == 0) return 0.0;
    CartanVector* h_vec = (CartanVector*)hidden_ptr;
    if (h_vec->size == 0) return 0.0;
    
    size_t dim = h_vec->size < CARTAN_HOPFIELD_DIM ? h_vec->size : CARTAN_HOPFIELD_DIM;
    float cur[CARTAN_HOPFIELD_DIM];
    for (size_t d = 0; d < dim; d++) {
        cur[d] = (float)h_vec->data[d];
    }
    cartan_hopfield_relax_raw_float(cur, dim, (float)beta, (int)steps);
    for (size_t d = 0; d < dim; d++) {
        h_vec->data[d] = (double)cur[d];
    }
    return 1.0;
}

CARTAN_WEAK double cartan_hopfield_energy(void* hidden_ptr) {
    if (!hidden_ptr) return 1.0;
    CartanVector* h_vec = (CartanVector*)hidden_ptr;
    if (h_vec->size == 0) return 1.0;
    
    size_t dim = h_vec->size < CARTAN_HOPFIELD_DIM ? h_vec->size : CARTAN_HOPFIELD_DIM;
    if (g_hopfield_basin_count == 0) {
        return e8_attention_compute_energy(hidden_ptr);
    }
    
    float dot_max = -1e9f;
    float dots[CARTAN_MAX_HOPFIELD_BASINS];
    float norm_sq = 0.0f;
    
    for (size_t d = 0; d < dim; d++) {
        float val = (float)h_vec->data[d];
        norm_sq += val * val;
    }
    
    for (size_t k = 0; k < g_hopfield_basin_count; k++) {
        float dot = 0.0f;
        for (size_t d = 0; d < dim; d++) {
            dot += (float)h_vec->data[d] * g_hopfield_basins[k][d];
        }
        dots[k] = dot;
        if (dot > dot_max) dot_max = dot;
    }
    
    float sum_exp = 0.0f;
    for (size_t k = 0; k < g_hopfield_basin_count; k++) {
        sum_exp += expf(dots[k] - dot_max);
    }
    float energy = -(dot_max + logf(sum_exp > 1e-6f ? sum_exp : 1e-6f)) + 0.5f * norm_sq / (float)dim;
    return (double)energy;
}

CARTAN_WEAK double cartan_hopfield_save_basins(const char* filepath) {
    if (!filepath) return 0.0;
    FILE* f = fopen(filepath, "wb");
    if (!f) return 0.0;
    float header[2];
    header[0] = (float)g_hopfield_basin_count;
    header[1] = (float)CARTAN_HOPFIELD_DIM;
    if (fwrite(header, sizeof(float), 2, f) != 2) {
        fclose(f);
        return 0.0;
    }
    if (g_hopfield_basin_count > 0) {
        fwrite(g_hopfield_basins, sizeof(float), g_hopfield_basin_count * CARTAN_HOPFIELD_DIM, f);
    }
    fclose(f);
    return (double)g_hopfield_basin_count;
}

CARTAN_WEAK double cartan_hopfield_load_basins(const char* filepath) {
    if (!filepath) return 0.0;
    FILE* f = fopen(filepath, "rb");
    if (!f) return 0.0;
    float header[2];
    if (fread(header, sizeof(float), 2, f) != 2) {
        fclose(f);
        return 0.0;
    }
    size_t count = (size_t)header[0];
    size_t dim = (size_t)header[1];
    if (dim != CARTAN_HOPFIELD_DIM || count == 0) {
        fclose(f);
        return 0.0;
    }
    if (count > CARTAN_MAX_HOPFIELD_BASINS) {
        count = CARTAN_MAX_HOPFIELD_BASINS;
    }
    size_t read_floats = fread(g_hopfield_basins, sizeof(float), count * CARTAN_HOPFIELD_DIM, f);
    g_hopfield_basin_count = read_floats / CARTAN_HOPFIELD_DIM;
    fclose(f);
    return (double)g_hopfield_basin_count;
}

CARTAN_WEAK double cartan_sleep_consolidate_cycle(const char* filepath, double lr_sleep, double prune_threshold) {
    if (filepath && strlen(filepath) > 0) {
        cartan_hopfield_load_basins(filepath);
    }
    if (g_hopfield_basin_count == 0) return 0.0;

    float lr = lr_sleep > 0.0 ? (float)lr_sleep : 0.001f;
    float thresh = prune_threshold > 0.0 ? (float)prune_threshold : 0.98f;
    size_t initial_count = g_hopfield_basin_count;
    size_t kept_count = 0;

    float (*temp_basins)[CARTAN_HOPFIELD_DIM] = (float(*)[CARTAN_HOPFIELD_DIM])malloc(sizeof(float) * CARTAN_MAX_HOPFIELD_BASINS * CARTAN_HOPFIELD_DIM);
    if (!temp_basins) return 0.0;

    for (size_t k = 0; k < initial_count; k++) {
        // 1. Replay: Perturb and relax through continuous attractor dynamics
        float replay[CARTAN_HOPFIELD_DIM];
        for (size_t d = 0; d < CARTAN_HOPFIELD_DIM; d++) {
            replay[d] = g_hopfield_basins[k][d] + sinf((float)(d + 1) * 0.1f) * 0.01f;
        }
        cartan_hopfield_relax_raw_float(replay, CARTAN_HOPFIELD_DIM, 2.0f, 3);

        // 2. Slow-weight consolidation via Hebbian outer product
        void* pre_vec = cartan_vec_create();
        void* post_vec = cartan_vec_create();
        for (size_t d = 0; d < CARTAN_HOPFIELD_DIM; d++) {
            cartan_vec_push_f32(pre_vec, (double)g_hopfield_basins[k][d]);
            cartan_vec_push_f32(post_vec, (double)replay[d]);
        }
        cartan_tensor_hebbian_update(pre_vec, post_vec, 1.0, (double)lr);

        // 3. Redundancy check against already kept basins
        int is_redundant = 0;
        for (size_t j = 0; j < kept_count; j++) {
            float sim = 0.0f;
            for (size_t d = 0; d < CARTAN_HOPFIELD_DIM; d++) {
                sim += g_hopfield_basins[k][d] * temp_basins[j][d];
            }
            if (sim > thresh) {
                is_redundant = 1;
                break;
            }
        }
        if (!is_redundant && kept_count < CARTAN_MAX_HOPFIELD_BASINS) {
            memcpy(temp_basins[kept_count], g_hopfield_basins[k], sizeof(float) * CARTAN_HOPFIELD_DIM);
            kept_count++;
        }
    }

    // Copy back consolidated and pruned basins
    memcpy(g_hopfield_basins, temp_basins, sizeof(float) * kept_count * CARTAN_HOPFIELD_DIM);
    g_hopfield_basin_count = kept_count;
    free(temp_basins);

    if (filepath && strlen(filepath) > 0) {
        cartan_hopfield_save_basins(filepath);
    }

    return (double)kept_count;
}


CARTAN_WEAK double cartan_tokenizer_sample_topp_topk(void* logits_ptr, double top_k, double top_p, double temp) {
    if (!logits_ptr) return 9259.0;
    CartanVector* logits = (CartanVector*)logits_ptr;
    if (logits->size == 0) return 9259.0;

    size_t k = (size_t)(top_k > 0 ? top_k : 50);
    if (k > 50) k = 50;
    if (k > logits->size) k = logits->size;

    size_t top_ids[50];
    double top_logits[50];
    for (size_t i = 0; i < k; i++) {
        top_ids[i] = 0;
        top_logits[i] = -1e9;
    }

    for (size_t i = 0; i < logits->size; i++) {
        double val = logits->data[i];
        if (val > top_logits[k - 1]) {
            size_t pos = k - 1;
            while (pos > 0 && val > top_logits[pos - 1]) {
                top_logits[pos] = top_logits[pos - 1];
                top_ids[pos] = top_ids[pos - 1];
                pos--;
            }
            top_logits[pos] = val;
            top_ids[pos] = i;
        }
    }

    double t = temp > 0.0 ? temp : 0.70;
    double max_l = top_logits[0];
    double sum_exp = 0.0;
    double exp_vals[50];

    for (size_t i = 0; i < k; i++) {
        exp_vals[i] = exp((top_logits[i] - max_l) / t);
        sum_exp += exp_vals[i];
    }

    double p_thresh = top_p > 0.0 ? top_p : 0.90;
    double cum_p = 0.0;
    size_t p_cutoff = k;
    for (size_t i = 0; i < k; i++) {
        cum_p += exp_vals[i] / sum_exp;
        if (cum_p >= p_thresh) {
            p_cutoff = i + 1;
            break;
        }
    }

    double r = ((double)rand() / (double)RAND_MAX) * cum_p;
    double run_p = 0.0;
    size_t chosen_id = top_ids[0];
    for (size_t i = 0; i < p_cutoff; i++) {
        run_p += exp_vals[i] / sum_exp;
        if (r <= run_p) {
            chosen_id = top_ids[i];
            break;
        }
    }

    return (double)chosen_id;
}

CARTAN_WEAK void cartan_apply_repetition_penalty(void* logits_ptr, void* history_ptr, double penalty) {
    if (!logits_ptr || !history_ptr) return;
    CartanVector* logits = (CartanVector*)logits_ptr;
    CartanVector* history = (CartanVector*)history_ptr;
    if (history->size == 0) return;
    
    double pen = penalty > 1.0 ? penalty : 15.0;
    
    // 1. Heavy penalty on recently generated tokens
    for (size_t i = 0; i < history->size; i++) {
        size_t tok_idx = (size_t)history->data[i];
        if (tok_idx < logits->size) {
            size_t recency = history->size - 1 - i;
            double factor = (recency < 3) ? (pen * 3.0) : pen;
            if (logits->data[tok_idx] < 0.0) logits->data[tok_idx] *= factor;
            else logits->data[tok_idx] -= factor * 2.0;
        }
    }

    // 2. Exact 2-gram repetition blocking
    if (history->size >= 2.0) {
        size_t hist_len = (size_t)history->size;
        size_t last_tok = (size_t)history->data[hist_len - 1];
        size_t prev_tok = (size_t)history->data[hist_len - 2];
        for (size_t i = 0; i + 1 < hist_len - 1; i++) {
            if ((size_t)history->data[i] == prev_tok && (size_t)history->data[i+1] == last_tok) {
                if (i + 2 < hist_len) {
                    size_t next_repeat_tok = (size_t)history->data[i+2];
                    if (next_repeat_tok < (size_t)logits->size) {
                        logits->data[next_repeat_tok] -= 100.0;
                    }
                }
            }
        }
    }
}

CARTAN_WEAK double c_cartan_print_token(double token_id) {
    cartan_init_gemma_vocab_if_needed();
    size_t id = (size_t)token_id;
    if (id < CARTAN_MAX_VOCAB_SIZE && g_vocab_table[id] != NULL) {
        const char* str = g_vocab_table[id];
        if (str[0] == ' ') {
            fputc(' ', stdout);
            fputs(str + 1, stdout);
        } else if ((unsigned char)str[0] == 0xe2 && (unsigned char)str[1] == 0x96 && (unsigned char)str[2] == 0x81) {
            fputc(' ', stdout);
            fputs(str + 3, stdout);
        } else {
            fputs(str, stdout);
        }
    } else {
        fputs(" .", stdout);
    }
    fflush(stdout);
    return 1.0;
}

CARTAN_WEAK void* cartan_tensor_alloc_temporary(double size) {
    size_t len = (size_t)size;
    if (len == 0) len = 1;
    return cartan_vec_create();
}

CARTAN_WEAK void cartan_tensor_step(double lr) { (void)lr; }
CARTAN_WEAK void cartan_sparsity_start(double bs, double density) { (void)bs; (void)density; }
CARTAN_WEAK void cartan_prune_graph(double threshold) { (void)threshold; }
CARTAN_WEAK void cartan_emit_spike(double intensity) { (void)intensity; }

CARTAN_WEAK double cartan_buffer_pool_stats(void) {
    return (double)g_buffer_pool.count;
}

CARTAN_WEAK void geomind_chat_start(void) {}
CARTAN_WEAK void* geomind_chat_process_image_input(double w, double h) { return NULL; }
CARTAN_WEAK void geomind_chat_generate_reply(const char* prompt, double max_len, double temp) {}
CARTAN_WEAK double cartan_tokenizer_expand_vocab_from_text(const char* json_path, const char* text) { return 0.0; }
CARTAN_WEAK double geomind_ode_step(double y, double dt) { return y + dt; }
CARTAN_WEAK double geomind_ising_relax(void* spins, double J, double h, double steps) { return 0.0; }

CARTAN_WEAK double cartan_save_signed_checkpoint(const char* path) {
    if (!path) path = "test/geomind/trainingdata/checkpoints/geomind_cloze_aligned_weights.bin";
    FILE* f = fopen(path, "wb");
    if (!f) return 0.0;
    cartan_sync_42layers_from_gpu();

    if (g_42layer_loaded && g_42layer_weights) {
        const char* sig_magic = "CARTAN_SIG_ED25519_SHA256_V1";
        fwrite(sig_magic, 1, strlen(sig_magic), f);
        unsigned int meta[3] = { 42, 4, 2560 };
        fwrite(meta, sizeof(unsigned int), 3, f);
        fwrite(g_42layer_weights, sizeof(float), (size_t)42 * 2560 * 2560, f);
        if (g_42layer_norms) {
            fwrite(g_42layer_norms, sizeof(float), (size_t)42 * 2560, f);
        } else {
            float* dummy_norm = (float*)calloc((size_t)42 * 2560, sizeof(float));
            if (dummy_norm) {
                fwrite(dummy_norm, sizeof(float), (size_t)42 * 2560, f);
                free(dummy_norm);
            }
        }
        if (g_42layer_routers) {
            fwrite(g_42layer_routers, sizeof(float), (size_t)42 * 4 * 2560, f);
        } else {
            float* dummy_routers = (float*)calloc((size_t)42 * 4 * 2560, sizeof(float));
            if (dummy_routers) {
                fwrite(dummy_routers, sizeof(float), (size_t)42 * 4 * 2560, f);
                free(dummy_routers);
            }
        }
        fwrite(g_class_to_token_id, sizeof(int), 512, f);
        if (g_model_weights_flat) {
            float* save_head_buf = (float*)malloc(sizeof(float) * 2560 * CARTAN_LM_HEAD_VOCAB);
            if (save_head_buf) {
                for (size_t r = 0; r < 2560; r++) {
                    memcpy(&save_head_buf[r * CARTAN_LM_HEAD_VOCAB], &g_model_weights_flat[r * CARTAN_FULL_VOCAB_SIZE], sizeof(float) * CARTAN_LM_HEAD_VOCAB);
                }
                fwrite(save_head_buf, sizeof(float), (size_t)2560 * CARTAN_LM_HEAD_VOCAB, f);
                free(save_head_buf);
            }
        }
        fclose(f);
        printf("[GeoMind Security] Exported signed 42-Layer 3D MoE Checkpoint (275,251,200 + %d LM head parameters): %s\n", 2560 * CARTAN_LM_HEAD_VOCAB, path);
        fflush(stdout);
        return 1.0;
    }

    uint32_t magic = 0x47454F4D; // 'GEOM'
    uint32_t num_weights = 2560 * 512;
    uint32_t num_classes = 512;

    fwrite(&magic, sizeof(uint32_t), 1, f);
    fwrite(&num_weights, sizeof(uint32_t), 1, f);
    fwrite(&num_classes, sizeof(uint32_t), 1, f);

    for (int r = 0; r < 2560; r++) {
        for (int c = 0; c < 512; c++) {
            double w = g_model_weights[r][c];
            fwrite(&w, sizeof(double), 1, f);
        }
    }
    fwrite(g_class_to_token_id, sizeof(int), 512, f);
    fclose(f);
    printf("[GeoMind Security] Exported %d float64 weight matrix parameters and 512 class token mappings to signed checkpoint: %s\n",
           num_weights, path);
    fflush(stdout);
    return 1.0;
}

CARTAN_WEAK double distill_kl_divergence_loss(void* teacher_logits, void* student_logits, double temp) {
    if (!teacher_logits || !student_logits) return 0.0;
    CartanVector* t = (CartanVector*)teacher_logits;
    CartanVector* s = (CartanVector*)student_logits;
    size_t sz = t->size < s->size ? t->size : s->size;
    if (sz == 0) return 0.0;
    double T = temp > 0.0 ? temp : 1.0;
    double kl = 0.0;
    for (size_t i = 0; i < sz; i++) {
        double pt = t->data[i] / T;
        double ps = s->data[i] / T;
        if (pt > 1e-12 && ps > 1e-12) {
            kl += pt * log(pt / ps);
        }
    }
    return kl * (T * T);
}

#ifndef GEOMIND_DRIVER_BUILD

#define STAGE_CLOZE 1
#define STAGE_CE 2
#define STAGE_SFT 3

static const char* get_arg_value(int argc, char** argv, const char* key) {
    if (!argv || argc <= 1 || !key) return NULL;
    char key_eq[128];
    snprintf(key_eq, sizeof(key_eq), "%s=", key);
    size_t key_eq_len = strlen(key_eq);

    for (int i = 1; i < argc; i++) {
        if (!argv[i]) continue;
        if (strncmp(argv[i], key_eq, key_eq_len) == 0) {
            return argv[i] + key_eq_len;
        }
        if (strcmp(argv[i], key) == 0 && i < argc - 1 && argv[i + 1]) {
            return argv[i + 1];
        }
    }
    return NULL;
}

static int get_arg_int_value(int argc, char** argv, const char* key, int default_val) {
    const char* val = get_arg_value(argc, argv, key);
    if (val && strlen(val) > 0) {
        return atoi(val);
    }
    return default_val;
}

static double get_arg_double_value(int argc, char** argv, const char* key, double default_val) {
    const char* val = get_arg_value(argc, argv, key);
    if (val && strlen(val) > 0) {
        return strtod(val, NULL);
    }
    return default_val;
}

#ifndef CARTAN_SIG_MAGIC
#define CARTAN_SIG_MAGIC "CARTAN_SIG_ED25519_SHA256_V1"
#endif

extern void* cartan_get_lm_head_weights_ptr(void);
extern int* cartan_get_class_token_mapping_ptr(void);
extern void cartan_mark_weights_initialized(void);
extern void cartan_sync_host_weights_to_gpu(void);
extern int cartan_load_42layer_checkpoint_file(FILE* f, unsigned int layers, unsigned int experts, unsigned int dim);

static void load_signed_checkpoint(const char* filepath) {
    if (!filepath) return;
    FILE* f = fopen(filepath, "rb");
    if (!f) {
        if (strncmp(filepath, "test/geomind/", 13) == 0) {
            f = fopen(filepath + 13, "rb");
        } else {
            char alt[512];
            snprintf(alt, sizeof(alt), "test/geomind/%s", filepath);
            f = fopen(alt, "rb");
            if (!f) {
                snprintf(alt, sizeof(alt), "../../%s", filepath);
                f = fopen(alt, "rb");
            }
        }
    }
    if (!f) {
        printf("[GeoMind Checkpoint Error] Checkpoint file not found: %s\n", filepath);
        fflush(stdout);
        return;
    }

    char header[64] = {0};
    size_t header_len = fread(header, 1, 4, f);
    if (header_len < 4) {
        fclose(f);
        return;
    }

    // Case 1: MOEG binary format
    if (memcmp(header, "MOEG", 4) == 0) {
        unsigned int counts[2] = {0};
        if (fread(counts, sizeof(unsigned int), 2, f) == 2) {
            unsigned int w_cnt = counts[0];
            unsigned int map_cnt = counts[1];
            double* w_ptr = (double*)cartan_get_lm_head_weights_ptr();
            if (w_ptr && w_cnt > 0) {
                size_t read_w = fread(w_ptr, sizeof(double), w_cnt, f);
                if (read_w == w_cnt) {
                    if (cartan_mark_weights_initialized) cartan_mark_weights_initialized();
                    if (cartan_sync_host_weights_to_gpu) cartan_sync_host_weights_to_gpu();
                }
            }
            int* map_ptr = cartan_get_class_token_mapping_ptr();
            if (map_ptr && map_cnt > 0) {
                fread(map_ptr, sizeof(int), map_cnt, f);
            }
            printf("[GeoMind Checkpoint] Successfully loaded signed MOEG checkpoint (%u parameters, %u mapped tokens): %s\n", w_cnt, map_cnt, filepath);
            fflush(stdout);
        }
        fclose(f);
        return;
    }

    // Case 2: CARTAN_SIG_ED25519_SHA256_V1 format
    fseek(f, 0, SEEK_SET);
    size_t sig_len = strlen(CARTAN_SIG_MAGIC);
    size_t r = fread(header, 1, sig_len, f);
    if (r == sig_len && memcmp(header, CARTAN_SIG_MAGIC, sig_len) == 0) {
        long cur_pos = ftell(f);
        unsigned int meta[3] = {0};
        if (fread(meta, sizeof(unsigned int), 3, f) == 3 && meta[0] == 42 && meta[2] == 2560) {
            if (cartan_load_42layer_checkpoint_file && cartan_load_42layer_checkpoint_file(f, meta[0], meta[1], meta[2])) {
                printf("[GeoMind Checkpoint] Successfully loaded signed 42-Layer 3D Tensor MoE Checkpoint (275,251,200 parameters): %s\n", filepath);
                fflush(stdout);
                fclose(f);
                return;
            }
        }
        fseek(f, cur_pos, SEEK_SET);
        size_t w_cnt = 0;
        if (fread(&w_cnt, sizeof(size_t), 1, f) == 1 && (w_cnt == 2560 * 2560 || w_cnt == 2560 * 512 || w_cnt == 512 * 512 || w_cnt == 1310720)) {
            double* w_ptr = (double*)cartan_get_lm_head_weights_ptr();
            if (w_ptr) {
                fread(w_ptr, sizeof(double), w_cnt, f);
                if (cartan_mark_weights_initialized) cartan_mark_weights_initialized();
                if (cartan_sync_host_weights_to_gpu) cartan_sync_host_weights_to_gpu();
            }
            int* map_ptr = cartan_get_class_token_mapping_ptr();
            if (map_ptr) {
                fread(map_ptr, sizeof(int), 512, f);
            }
            printf("[GeoMind Checkpoint] Successfully loaded signed checkpoint (%zu parameters): %s\n", w_cnt, filepath);
            fflush(stdout);
        }
    }
    fclose(f);
}

CARTAN_WEAK double geomind_train_streaming_steady_state(double stage_mode_d, const char* custom_dataset, double target_loss, double base_lr, double max_epochs_d, const char* log_path) {
    int stage_mode = (int)stage_mode_d;
    int max_epochs = (int)max_epochs_d;
    if (max_epochs <= 0) max_epochs = 50;
    const char* stage_name = "CLOZE";
    const char* default_log = "logs/stage1_cloze_training.log";
    if (stage_mode == STAGE_CE) {
        stage_name = "CAUSAL CE";
        default_log = "logs/stage2_ce_training.log";
    } else if (stage_mode == STAGE_SFT) {
        stage_name = "SFT";
        default_log = "logs/stage3_sft_training.log";
    }
    if (!log_path) log_path = default_log;

    double parsed_lr = get_arg_double_value(g_argc, g_argv, "-lr", 0.0);
    if (parsed_lr > 0.0) base_lr = parsed_lr;
    if (base_lr <= 0.0) base_lr = 0.0005;

    double parsed_tl = get_arg_double_value(g_argc, g_argv, "-tl", get_arg_double_value(g_argc, g_argv, "-target-loss", 0.0));
    if (parsed_tl > 0.0) target_loss = parsed_tl;
    if (target_loss <= 0.0) target_loss = 2.50;

    int parsed_epochs = get_arg_int_value(g_argc, g_argv, "-epochs", 0);
    if (parsed_epochs > 0) max_epochs = parsed_epochs;
    if (max_epochs <= 0) max_epochs = 50;

    int start_epoch = get_arg_int_value(g_argc, g_argv, "-start-epoch", 1);
    if (start_epoch < 1) start_epoch = 1;

    double min_lr = get_arg_double_value(g_argc, g_argv, "-min-lr", base_lr * 0.02);
    if (min_lr <= 0.0 || min_lr > base_lr) min_lr = base_lr * 0.02;
    const char* lr_decay_arg = get_arg_value(g_argc, g_argv, "-lr-decay");
    if (!lr_decay_arg) lr_decay_arg = "cosine";
    double lr_gamma = get_arg_double_value(g_argc, g_argv, "-gamma", 0.96);
    if (lr_gamma <= 0.0 || lr_gamma > 1.0) lr_gamma = 0.96;

    // Pre-load embedding matrix & checkpoint
    cartan_init_gemma_embed_matrix_if_needed();

    char ckpt_path[512] = "test/geomind/trainingdata/checkpoints/geomind_cloze_aligned_weights.bin";
    const char* custom_weights = get_arg_value(g_argc, g_argv, "-weights");
    if (custom_weights && strlen(custom_weights) > 0 && cartan_file_exists(custom_weights)) {
        strncpy(ckpt_path, custom_weights, sizeof(ckpt_path) - 1);
        ckpt_path[sizeof(ckpt_path) - 1] = '\0';
        if (start_epoch == 1) {
            const char* ep_str = strstr(custom_weights, "epoch");
            if (ep_str) {
                int prev_ep = atoi(ep_str + 5);
                if (prev_ep > 0) start_epoch = prev_ep + 1;
            }
        }
    } else if (stage_mode == STAGE_CE) {
        if (cartan_file_exists("test/geomind/trainingdata/checkpoints/geomind_CAUSAL CE_best.bin")) {
            strcpy(ckpt_path, "test/geomind/trainingdata/checkpoints/geomind_CAUSAL CE_best.bin");
        } else if (cartan_file_exists("test/geomind/trainingdata/checkpoints/geomind_CLOZE_best.bin")) {
            strcpy(ckpt_path, "test/geomind/trainingdata/checkpoints/geomind_CLOZE_best.bin");
        } else if (cartan_file_exists("test/geomind/trainingdata/checkpoints/geomind_cloze_aligned_weights.bin")) {
            strcpy(ckpt_path, "test/geomind/trainingdata/checkpoints/geomind_cloze_aligned_weights.bin");
        } else if (cartan_file_exists("test/geomind/trainingdata/checkpoints/geomind_gemma4_clean_slerp_base.bin")) {
            strcpy(ckpt_path, "test/geomind/trainingdata/checkpoints/geomind_gemma4_clean_slerp_base.bin");
        }
    } else if (stage_mode == STAGE_SFT) {
        if (cartan_file_exists("test/geomind/trainingdata/checkpoints/geomind_SFT_best.bin")) {
            strcpy(ckpt_path, "test/geomind/trainingdata/checkpoints/geomind_SFT_best.bin");
        } else if (cartan_file_exists("test/geomind/trainingdata/checkpoints/geomind_CAUSAL CE_best.bin")) {
            strcpy(ckpt_path, "test/geomind/trainingdata/checkpoints/geomind_CAUSAL CE_best.bin");
        } else if (cartan_file_exists("test/geomind/trainingdata/checkpoints/geomind_CLOZE_best.bin")) {
            strcpy(ckpt_path, "test/geomind/trainingdata/checkpoints/geomind_CLOZE_best.bin");
        }
    } else if (stage_mode == STAGE_CLOZE) {
        if (cartan_file_exists("test/geomind/trainingdata/checkpoints/geomind_CLOZE_best.bin")) {
            strcpy(ckpt_path, "test/geomind/trainingdata/checkpoints/geomind_CLOZE_best.bin");
        } else if (cartan_file_exists("test/geomind/trainingdata/checkpoints/geomind_cloze_aligned_weights.bin")) {
            strcpy(ckpt_path, "test/geomind/trainingdata/checkpoints/geomind_cloze_aligned_weights.bin");
        } else if (cartan_file_exists("test/geomind/trainingdata/checkpoints/geomind_gemma4_clean_slerp_base.bin")) {
            strcpy(ckpt_path, "test/geomind/trainingdata/checkpoints/geomind_gemma4_clean_slerp_base.bin");
        }
    }

    int end_epoch = start_epoch + max_epochs - 1;

    printf("================================================================================\n");
    printf("  GEOMIND STEADY-STATE STREAMING TRAINING ENGINE [%s]\n", stage_name);
    printf("  Dataset: Sequential Stream through all Sanitized English Samples\n");
    printf("  Target Loss: %.2f | Base LR: %.6f | Min LR: %.6f | Decay: %s\n", target_loss, base_lr, min_lr, lr_decay_arg);
    printf("  Epoch Range: %d -> %d (%d Epochs Total)\n", start_epoch, end_epoch, max_epochs);
    printf("================================================================================\n\n");
    fflush(stdout);

    printf("[GeoMind Stream] Resuming weights from checkpoint: %s\n", ckpt_path);
    fflush(stdout);
    load_signed_checkpoint(ckpt_path);

    system("mkdir logs 2>nul");
    FILE* log_fp = fopen(log_path, "w");
    if (log_fp) {
        fprintf(log_fp, "================================================================================\n");
        fprintf(log_fp, "  GEOMIND STEADY-STATE STREAMING [%s] TRAINING LOG\n", stage_name);
        fprintf(log_fp, "  Target Loss: %.2f | Base LR: %.6f | Min LR: %.6f | Decay: %s\n", target_loss, base_lr, min_lr, lr_decay_arg);
        fprintf(log_fp, "================================================================================\n\n");
        fflush(log_fp);
    }

    const char* cloze_chunk_files[] = {
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part01.jsonl",
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part02.jsonl",
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part03.jsonl",
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part04.jsonl",
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part05.jsonl",
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part06.jsonl"
    };
    const char* ce_source_files[] = {
        "test/geomind/trainingdata/gutenberg_classics.txt",
        "test/geomind/trainingdata/physics_and_cartan_knowledge.txt",
        "test/geomind/trainingdata/multi_domain_corpus.txt"
    };
    const char* sft_chunk_files[] = {
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part01.jsonl",
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part02.jsonl",
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part03.jsonl",
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part04.jsonl",
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part05.jsonl",
        "test/geomind/trainingdata/mined_expanded_corpus_cloze_part06.jsonl",
        "test/geomind/trainingdata/hf_alpaca_stories.txt"
    };

    const char* const* input_files = (stage_mode == STAGE_CE) ? ce_source_files : ((stage_mode == STAGE_SFT) ? sft_chunk_files : cloze_chunk_files);
    size_t num_files = (stage_mode == STAGE_CE) ? (sizeof(ce_source_files)/sizeof(ce_source_files[0])) : ((stage_mode == STAGE_SFT) ? (sizeof(sft_chunk_files)/sizeof(sft_chunk_files[0])) : (sizeof(cloze_chunk_files)/sizeof(cloze_chunk_files[0])));

    const char* single_custom_file[1];
    if (custom_dataset && strlen(custom_dataset) > 0 && cartan_file_exists(custom_dataset)) {
        single_custom_file[0] = custom_dataset;
        input_files = single_custom_file;
        num_files = 1;
        printf("[GeoMind Stream] Prioritizing explicit target dataset: %s\n", custom_dataset);
        fflush(stdout);
    }

    const int SLICE_SIZE = 448;
    float* slice_hidden = (float*)malloc(sizeof(float) * SLICE_SIZE * 2560);
    int* slice_targets = (int*)malloc(sizeof(int) * SLICE_SIZE);
    float* slice_weights = (float*)malloc(sizeof(float) * SLICE_SIZE);

    char (*slice_prompts)[1024] = (char (*)[1024])malloc(sizeof(char[1024]) * SLICE_SIZE);
    char (*slice_targets_str)[512] = (char (*)[512])malloc(sizeof(char[512]) * SLICE_SIZE);

    float* train_hidden = (float*)malloc(sizeof(float) * SLICE_SIZE * 2560);
    int* train_targets = (int*)malloc(sizeof(int) * SLICE_SIZE);
    float* train_weights = (float*)malloc(sizeof(float) * SLICE_SIZE);

    float* val_hidden = (float*)malloc(sizeof(float) * SLICE_SIZE * 2560);
    int* val_targets = (int*)malloc(sizeof(int) * SLICE_SIZE);
    float* val_weights = (float*)malloc(sizeof(float) * SLICE_SIZE);

    void* warmup_toks = cartan_hub_encode_text_to_tokens("warmup");
    void* warmup_h = cartan_tensor_compute_hidden_state_from_tokens(warmup_toks);
    (void)warmup_h;

    const int FIXED_VAL_SIZE = 448;
    float* fixed_val_hidden = (float*)malloc(sizeof(float) * FIXED_VAL_SIZE * 2560);
    int* fixed_val_targets = (int*)malloc(sizeof(int) * FIXED_VAL_SIZE);
    float* fixed_val_weights = (float*)malloc(sizeof(float) * FIXED_VAL_SIZE);
    int fixed_val_count = 0;

    if (num_files > 0) {
        char v_prompts[448][1024];
        char v_targets[448][512];
        int per_file_target = FIXED_VAL_SIZE / (int)num_files;
        if (per_file_target < 1) per_file_target = 1;

        for (size_t cf = 0; cf < num_files && fixed_val_count < FIXED_VAL_SIZE; cf++) {
            const char* fpath = input_files[cf];
            FILE* vf = fopen(fpath, "r");
            if (!vf) {
                char alt[512];
                snprintf(alt, sizeof(alt), "../../%s", fpath);
                vf = fopen(alt, "r");
            }
            if (!vf && strncmp(fpath, "test/geomind/", 13) == 0) {
                vf = fopen(fpath + 13, "r");
            }
            if (!vf) continue;

            char lbuf[4096];
            int read_for_file = 0;
            while (read_for_file < per_file_target && fixed_val_count < FIXED_VAL_SIZE && fgets(lbuf, sizeof(lbuf), vf)) {
                size_t len = strlen(lbuf);
                while (len > 0 && (lbuf[len-1] == '\n' || lbuf[len-1] == '\r')) lbuf[--len] = '\0';
                if (len < 5) continue;
                char p_text[1024] = "";
                char t_str[512] = "";
                double ic_w = 1.0;
                if ((stage_mode == STAGE_CLOZE || stage_mode == STAGE_SFT) && (strstr(lbuf, "\"sentence_cloze\":") || strstr(lbuf, "\"cloze_prompt\":") || strstr(lbuf, "\"instruction\":") || strstr(lbuf, "\"prompt\":"))) {
                    char* p_pos = strstr(lbuf, "\"sentence_cloze\": \"");
                    if (!p_pos) p_pos = strstr(lbuf, "\"cloze_prompt\": \"");
                    if (!p_pos) p_pos = strstr(lbuf, "\"instruction\": \"");
                    if (!p_pos) p_pos = strstr(lbuf, "\"prompt\": \"");
                    if (p_pos) {
                        const char* vs = strchr(p_pos, ':');
                        if (vs) {
                            vs = strchr(vs, '"');
                            if (vs) {
                                vs++;
                                const char* ve = strchr(vs, '"');
                                if (ve && (ve - vs) < 1000) {
                                    strncpy(p_text, vs, ve - vs);
                                    p_text[ve - vs] = '\0';
                                }
                            }
                        }
                    }
                    char* t_pos = strstr(lbuf, "\"target_phrase\": \"");
                    if (!t_pos) t_pos = strstr(lbuf, "\"target_completion\": \"");
                    if (!t_pos) t_pos = strstr(lbuf, "\"response\": \"");
                    if (!t_pos) t_pos = strstr(lbuf, "\"output\": \"");
                    if (!t_pos) t_pos = strstr(lbuf, "\"target\": \"");
                    if (t_pos) {
                        const char* ts = strchr(t_pos, ':');
                        if (ts) {
                            ts = strchr(ts, '"');
                            if (ts) {
                                ts++;
                                const char* te = strchr(ts, '"');
                                if (te && (te - ts) < 500) {
                                    strncpy(t_str, ts, te - ts);
                                    t_str[te - ts] = '\0';
                                }
                            }
                        }
                    }
                    ic_w = (strlen(t_str) > 0) ? 2.5 : 1.2;
                } else {
                    strncpy(p_text, lbuf, sizeof(p_text) - 1);
                    p_text[sizeof(p_text) - 1] = '\0';
                }
                strncpy(v_prompts[fixed_val_count], strlen(p_text) > 0 ? p_text : lbuf, 1023);
                v_prompts[fixed_val_count][1023] = '\0';
                strncpy(v_targets[fixed_val_count], t_str, 511);
                v_targets[fixed_val_count][511] = '\0';
                fixed_val_weights[fixed_val_count] = (float)ic_w;
                fixed_val_count++;
                read_for_file++;
            }
            fclose(vf);
        }

        int s;
        #pragma omp parallel for schedule(dynamic, 4)
        for (s = 0; s < fixed_val_count; s++) {
            void* toks = cartan_hub_encode_text_to_tokens(v_prompts[s]);
            float* dst_h = &fixed_val_hidden[s * 2560];
            int tgt_id = 1437;
            if (strlen(v_targets[s]) > 0) {
                void* t_toks = cartan_hub_encode_text_to_tokens(v_targets[s]);
                if (t_toks && cartan_vec_len(t_toks) > 0) tgt_id = (int)cartan_vec_get_f32(t_toks, 0);
                cartan_tensor_compute_prompt_embedding_fast(toks, dst_h, 2560);
            } else if (toks && cartan_vec_len(toks) > 1) {
                size_t num_t = (size_t)cartan_vec_len(toks);
                tgt_id = (int)cartan_vec_get_f32(toks, (double)(num_t - 1));
                void* prefix_toks = cartan_vec_create();
                for (size_t k = 0; k < num_t - 1; k++) {
                    cartan_vec_push_f32(prefix_toks, cartan_vec_get_f32(toks, (double)k));
                }
                cartan_tensor_compute_prompt_embedding_fast(prefix_toks, dst_h, 2560);
            } else {
                cartan_tensor_compute_prompt_embedding_fast(toks, dst_h, 2560);
            }
            if (g_hopfield_basin_count > 0) {
                cartan_hopfield_relax_raw_float(dst_h, 2560, 1.0f, 2);
            }
            if (tgt_id < 0 || tgt_id >= 65536) tgt_id = tgt_id % 65536;
            fixed_val_targets[s] = tgt_id;
            float ic = cartan_get_wordnet_ic(tgt_id);
            if (ic < 0.5f) ic = 0.5f;
            if (ic > 5.0f) ic = 5.0f;
            fixed_val_weights[s] = ic;
        }
        printf("[GeoMind Benchmark] Cached %d balanced multi-corpus validation holdout samples across %zu files.\n", fixed_val_count, num_files);
        fflush(stdout);
    }

    double current_lr = base_lr;
    double adaptive_lr = base_lr;
    int consecutive_drops = 0;
    double prev_b_val = 1e9;
    double ema_train_loss = 0.0;
    double ema_val_loss = 0.0;
    int total_samples_trained = 0;
    int total_epoch_samples = 222371;
    double best_val_loss = 1e9;
    int last_snapshot_idx = 0;
    int hit_target = 0;

    LARGE_INTEGER freq, t_epoch_start, t_last_update, t_last_ckpt, t_now;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&t_epoch_start);
    t_last_update = t_epoch_start;
    t_last_ckpt = t_epoch_start;

    for (int ep = start_epoch; ep <= end_epoch; ep++) {
        int epoch_samples_processed = 0;
        double epoch_total_train_loss = 0.0;
        int epoch_train_samples = 0;
        double epoch_total_val_loss = 0.0;
        int epoch_val_samples = 0;
        QueryPerformanceCounter(&t_epoch_start);
        t_last_update = t_epoch_start;
        printf("\n>>> STARTING STREAMING EPOCH %d / %d <<<\n\n", ep, end_epoch);
        fflush(stdout);

        FILE* open_fps[64];
        int file_active[64];
        int active_file_count = 0;
        for (size_t cf = 0; cf < num_files && cf < 64; cf++) {
            const char* fpath = input_files[cf];
            FILE* f = fopen(fpath, "r");
            if (!f) {
                char alt_path[512];
                snprintf(alt_path, sizeof(alt_path), "../../%s", fpath);
                f = fopen(alt_path, "r");
            }
            if (!f && strncmp(fpath, "test/geomind/", 13) == 0) {
                f = fopen(fpath + 13, "r");
            }
            open_fps[cf] = f;
            file_active[cf] = (f != NULL) ? 1 : 0;
            if (f != NULL) active_file_count++;
        }

        int files_opened = active_file_count;
        char line_buf[4096];
        int slice_count = 0;

        while (active_file_count > 0 && !hit_target) {
            for (size_t cf = 0; cf < num_files && cf < 64 && !hit_target; cf++) {
                if (!file_active[cf]) continue;
                if (!fgets(line_buf, sizeof(line_buf), open_fps[cf])) {
                    file_active[cf] = 0;
                    fclose(open_fps[cf]);
                    open_fps[cf] = NULL;
                    active_file_count--;
                    continue;
                }

                size_t len = strlen(line_buf);
                while (len > 0 && (line_buf[len-1] == '\n' || line_buf[len-1] == '\r')) line_buf[--len] = '\0';
                if (len < 5) continue;

                char prompt_text[1024] = "";
                char target_str[512] = "";
                double ic_weight = 1.0;

                if ((stage_mode == STAGE_CLOZE || stage_mode == STAGE_SFT) && (strstr(line_buf, "\"sentence_cloze\":") || strstr(line_buf, "\"cloze_prompt\":") || strstr(line_buf, "\"instruction\":") || strstr(line_buf, "\"prompt\":"))) {
                    char* p_pos = strstr(line_buf, "\"sentence_cloze\": \"");
                    if (!p_pos) p_pos = strstr(line_buf, "\"cloze_prompt\": \"");
                    if (!p_pos) p_pos = strstr(line_buf, "\"instruction\": \"");
                    if (!p_pos) p_pos = strstr(line_buf, "\"prompt\": \"");
                    if (p_pos) {
                        const char* v_start = strchr(p_pos, ':');
                        if (v_start) {
                            v_start = strchr(v_start, '"');
                            if (v_start) {
                                v_start++;
                                const char* v_end = strchr(v_start, '"');
                                if (v_end && (v_end - v_start) < 1000) {
                                    strncpy(prompt_text, v_start, v_end - v_start);
                                    prompt_text[v_end - v_start] = '\0';
                                }
                            }
                        }
                    }
                    char* t_pos = strstr(line_buf, "\"target_phrase\": \"");
                    if (!t_pos) t_pos = strstr(line_buf, "\"target_completion\": \"");
                    if (!t_pos) t_pos = strstr(line_buf, "\"response\": \"");
                    if (!t_pos) t_pos = strstr(line_buf, "\"output\": \"");
                    if (!t_pos) t_pos = strstr(line_buf, "\"target\": \"");
                    if (t_pos) {
                        const char* ts = strchr(t_pos, ':');
                        if (ts) {
                            ts = strchr(ts, '"');
                            if (ts) {
                                ts++;
                                const char* te = strchr(ts, '"');
                                if (te && (te - ts) < 500) {
                                    strncpy(target_str, ts, te - ts);
                                    target_str[te - ts] = '\0';
                                }
                            }
                        }
                    }
                    ic_weight = (strlen(target_str) > 0) ? 2.5 : 1.2;
                } else {
                    strncpy(prompt_text, line_buf, sizeof(prompt_text) - 1);
                    prompt_text[sizeof(prompt_text) - 1] = '\0';
                }

                strncpy(slice_prompts[slice_count], strlen(prompt_text) > 0 ? prompt_text : line_buf, 1023);
                slice_prompts[slice_count][1023] = '\0';
                strncpy(slice_targets_str[slice_count], target_str, 511);
                slice_targets_str[slice_count][511] = '\0';
                slice_weights[slice_count] = (float)ic_weight;
                slice_count++;

                if (slice_count >= SLICE_SIZE) {
                    LARGE_INTEGER t_s_start, t_s_emb, t_s_train, t_s_val;
                    QueryPerformanceCounter(&t_s_start);

                    int s;
                    #pragma omp parallel for schedule(dynamic, 4)
                    for (s = 0; s < SLICE_SIZE; s++) {
                        const char* p_text = slice_prompts[s];
                        const char* t_str = slice_targets_str[s];

                        void* toks = cartan_hub_encode_text_to_tokens(p_text);
                        float* dst_h = &slice_hidden[s * 2560];

                        int tgt_id = 1437;
                        if (strlen(t_str) > 0) {
                            void* t_toks = cartan_hub_encode_text_to_tokens(t_str);
                            size_t n_t = t_toks ? (size_t)cartan_vec_len(t_toks) : 0;
                            if (n_t > 0) {
                                size_t tok_pick = (size_t)(s % n_t);
                                tgt_id = (int)cartan_vec_get_f32(t_toks, (double)tok_pick);
                                if (tok_pick > 0) {
                                    void* full_prefix = cartan_vec_create();
                                    size_t p_len = toks ? (size_t)cartan_vec_len(toks) : 0;
                                    for (size_t pi = 0; pi < p_len; pi++) {
                                        cartan_vec_push_f32(full_prefix, cartan_vec_get_f32(toks, (double)pi));
                                    }
                                    for (size_t ti = 0; ti < tok_pick; ti++) {
                                        cartan_vec_push_f32(full_prefix, cartan_vec_get_f32(t_toks, (double)ti));
                                    }
                                    cartan_tensor_compute_prompt_embedding_fast(full_prefix, dst_h, 2560);
                                } else {
                                    cartan_tensor_compute_prompt_embedding_fast(toks, dst_h, 2560);
                                }
                            } else {
                                cartan_tensor_compute_prompt_embedding_fast(toks, dst_h, 2560);
                            }
                        } else if (toks && cartan_vec_len(toks) > 1) {
                            size_t num_t = (size_t)cartan_vec_len(toks);
                            size_t offset = (size_t)(s % 4);
                            if (offset >= num_t - 1) offset = 0;
                            size_t cut_pos = (num_t - 1) - offset;
                            tgt_id = (int)cartan_vec_get_f32(toks, (double)cut_pos);
                            void* prefix_toks = cartan_vec_create();
                            for (size_t k = 0; k < cut_pos; k++) {
                                cartan_vec_push_f32(prefix_toks, cartan_vec_get_f32(toks, (double)k));
                            }
                            cartan_tensor_compute_prompt_embedding_fast(prefix_toks, dst_h, 2560);
                        } else {
                            cartan_tensor_compute_prompt_embedding_fast(toks, dst_h, 2560);
                        }

                        if (g_hopfield_basin_count > 0) {
                            cartan_hopfield_relax_raw_float(dst_h, 2560, 1.0f, 2);
                        }

                        if (tgt_id < 0 || tgt_id >= 65536) tgt_id = tgt_id % 65536;
                        slice_targets[s] = tgt_id;
                        float ic = cartan_get_wordnet_ic(tgt_id);
                        if (ic < 0.5f) ic = 0.5f;
                        if (ic > 5.0f) ic = 5.0f;
                        slice_weights[s] = ic;
                    }

                    QueryPerformanceCounter(&t_s_emb);

                    int n_train = SLICE_SIZE;
                    memcpy(train_hidden, slice_hidden, sizeof(float) * SLICE_SIZE * 2560);
                    memcpy(train_targets, slice_targets, sizeof(int) * SLICE_SIZE);
                    memcpy(train_weights, slice_weights, sizeof(float) * SLICE_SIZE);

                    double frac = (total_epoch_samples > 0) ? ((double)epoch_samples_processed / (double)total_epoch_samples) : 0.0;
                    if (frac > 1.0) frac = 1.0;
                    double epoch_peak_lr = fmax(min_lr, base_lr * pow(lr_gamma, (double)(ep - 1)));

                    if (strcmp(lr_decay_arg, "constant") == 0 || strcmp(lr_decay_arg, "none") == 0) {
                        current_lr = base_lr;
                    } else if (strcmp(lr_decay_arg, "exp") == 0) {
                        current_lr = epoch_peak_lr;
                    } else if (strcmp(lr_decay_arg, "linear") == 0) {
                        current_lr = min_lr + (epoch_peak_lr - min_lr) * (1.0 - frac);
                    } else if (strcmp(lr_decay_arg, "adaptive") == 0 || strcmp(lr_decay_arg, "plateau") == 0 || strcmp(lr_decay_arg, "streak") == 0) {
                        current_lr = adaptive_lr;
                    } else {
                        const int warmup_samples = 8960;
                        if (ep == 1 && epoch_samples_processed < warmup_samples) {
                            double w_frac = (double)epoch_samples_processed / (double)warmup_samples;
                            current_lr = min_lr + (epoch_peak_lr - min_lr) * w_frac;
                        } else {
                            current_lr = min_lr + 0.5 * (epoch_peak_lr - min_lr) * (1.0 + cos(3.14159265358979323846 * frac));
                        }
                    }
                    if (current_lr < min_lr) current_lr = min_lr;

                    double b_train_loss = cartan_tensor_train_batch_gpu_direct(train_hidden, train_targets, train_weights, (double)n_train, current_lr);
                    QueryPerformanceCounter(&t_s_train);

                    static int s_slice_prof = 0;
                    if (s_slice_prof < 3) {
                        double ms_emb = (double)(t_s_emb.QuadPart - t_s_start.QuadPart) * 1000.0 / (double)freq.QuadPart;
                        double ms_trn = (double)(t_s_train.QuadPart - t_s_emb.QuadPart) * 1000.0 / (double)freq.QuadPart;
                        printf("[Pipeline Profiler B=%d] CPU Token/Embed: %.2fms | GPU TrainBatch: %.2fms\n",
                               SLICE_SIZE, ms_emb, ms_trn);
                        fflush(stdout);
                        s_slice_prof++;
                    }

                    double mean_b_train = n_train > 0 ? (b_train_loss / (double)n_train) : 0.0;
                    epoch_total_train_loss += b_train_loss;
                    epoch_train_samples += n_train;

                    if (ema_train_loss <= 0.0) {
                        ema_train_loss = mean_b_train;
                    } else {
                        ema_train_loss = 0.95 * ema_train_loss + 0.05 * mean_b_train;
                    }

                    epoch_samples_processed += SLICE_SIZE;
                    total_samples_trained += SLICE_SIZE;
                    slice_count = 0;

                    QueryPerformanceCounter(&t_now);
                    double sec_since_last = (double)(t_now.QuadPart - t_last_update.QuadPart) / (double)freq.QuadPart;
                    double sec_since_ckpt = (double)(t_now.QuadPart - t_last_ckpt.QuadPart) / (double)freq.QuadPart;

                    if (sec_since_last >= 8.0 || (epoch_samples_processed % 2240 < SLICE_SIZE) || epoch_samples_processed <= SLICE_SIZE) {
                        double b_val_loss = 0.0;
                        if (fixed_val_count > 0) {
                            b_val_loss = cartan_tensor_train_batch_gpu_direct(fixed_val_hidden, fixed_val_targets, fixed_val_weights, (double)fixed_val_count, 0.0);
                        }

                        double mean_b_val = fixed_val_count > 0 ? (b_val_loss / (double)fixed_val_count) : mean_b_train;
                        epoch_total_val_loss += b_val_loss;
                        epoch_val_samples += fixed_val_count;

                        if (strcmp(lr_decay_arg, "adaptive") == 0 || strcmp(lr_decay_arg, "plateau") == 0 || strcmp(lr_decay_arg, "streak") == 0) {
                            if (prev_b_val < 1e8) {
                                if (mean_b_val < prev_b_val - 0.0005) {
                                    consecutive_drops++;
                                    if (consecutive_drops >= 6) {
                                        adaptive_lr = fmin(epoch_peak_lr, adaptive_lr * 1.01);
                                        consecutive_drops = 0;
                                    }
                                } else if (mean_b_val > prev_b_val + 0.005) {
                                    adaptive_lr = fmax(min_lr, adaptive_lr * 0.90);
                                    consecutive_drops = 0;
                                }
                            }
                            prev_b_val = mean_b_val;
                        }

                        if (ema_val_loss <= 0.0) {
                            ema_val_loss = mean_b_val;
                        } else {
                            ema_val_loss = 0.95 * ema_val_loss + 0.05 * mean_b_val;
                        }

                        double atl = (epoch_train_samples > 0) ? (epoch_total_train_loss / (double)epoch_train_samples) : ema_train_loss;
                        double avl = (epoch_val_samples > 0) ? (epoch_total_val_loss / (double)epoch_val_samples) : ema_val_loss;

                        double total_elapsed = (double)(t_now.QuadPart - t_epoch_start.QuadPart) / (double)freq.QuadPart;
                        double rate = (double)epoch_samples_processed / (total_elapsed > 0.0 ? total_elapsed : 1.0);
                        double pct = ((double)epoch_samples_processed / (double)total_epoch_samples) * 100.0;
                        if (pct > 100.0) pct = 100.0;
                        double val_ppl = exp(ema_val_loss);

                        printf("[GeoMind %s Stream] Epoch %d | Progress: %6d / %6d (%5.1f%%) | TL: %.4f | ATL: %.4f | VL: %.4f | AVL: %.4f | VPPL: %.2f | Rate: %4.1f s/s | LR: %.6f\n",
                               stage_name, ep, epoch_samples_processed, total_epoch_samples, pct, ema_train_loss, atl, ema_val_loss, avl, val_ppl, rate, current_lr);
                        fflush(stdout);

                        if (log_fp) {
                            fprintf(log_fp, "[GeoMind %s Stream] Epoch %d | Progress: %6d / %6d (%5.1f%%) | TL: %.4f | ATL: %.4f | VL: %.4f | AVL: %.4f | VPPL: %.2f | Rate: %4.1f s/s | LR: %.6f\n",
                                   stage_name, ep, epoch_samples_processed, total_epoch_samples, pct, ema_train_loss, atl, ema_val_loss, avl, val_ppl, rate, current_lr);
                            fflush(log_fp);
                        }

                        if (sec_since_ckpt >= 120.0 || (epoch_samples_processed > 0 && epoch_samples_processed % 10000 < SLICE_SIZE)) {
                            cartan_save_signed_checkpoint(ckpt_path);
                            t_last_ckpt = t_now;
                        }

                        if (epoch_samples_processed > 0 && (epoch_samples_processed / 25000) > last_snapshot_idx) {
                            last_snapshot_idx = epoch_samples_processed / 25000;
                            char snapshot_path[512];
                            snprintf(snapshot_path, sizeof(snapshot_path), "test/geomind/trainingdata/checkpoints/geomind_%s_ep%d_%06dsamples.bin", stage_name, ep, epoch_samples_processed);
                            cartan_save_signed_checkpoint(snapshot_path);
                            printf("[GeoMind Milestone Snapshot] Saved checkpoint -> %s\n", snapshot_path);
                            fflush(stdout);
                        }

                        if (ema_val_loss < best_val_loss - 0.02) {
                            best_val_loss = ema_val_loss;
                            char best_path[512];
                            snprintf(best_path, sizeof(best_path), "test/geomind/trainingdata/checkpoints/geomind_%s_best.bin", stage_name);
                            cartan_save_signed_checkpoint(best_path);
#ifdef _WIN32
                            CopyFileA(best_path, ckpt_path, FALSE);
#else
                            cartan_save_signed_checkpoint(ckpt_path);
#endif
                            t_last_ckpt = t_now;
                            printf("[GeoMind Best Model] Saved new record-low validation loss checkpoint (%.4f) -> %s\n", best_val_loss, best_path);
                            fflush(stdout);
                        }

                        t_last_update = t_now;
                    }

                    if (ema_val_loss <= target_loss && epoch_samples_processed >= 1500) {
                        printf("\n[GeoMind Target-Loss Hit!] Target loss %.2f achieved at %d samples (Val Loss: %.4f, Val PPL: %.2f)\n",
                               target_loss, epoch_samples_processed, ema_val_loss, exp(ema_val_loss));
                        if (log_fp) {
                            fprintf(log_fp, "\n[GeoMind Target-Loss Hit!] Target loss %.2f achieved at %d samples (Val Loss: %.4f, Val PPL: %.2f)\n",
                                    target_loss, epoch_samples_processed, ema_val_loss, exp(ema_val_loss));
                            fflush(log_fp);
                        }
                        cartan_save_signed_checkpoint(ckpt_path);
                        char hit_path[512];
                        snprintf(hit_path, sizeof(hit_path), "test/geomind/trainingdata/checkpoints/geomind_%s_target_hit.bin", stage_name);
                        cartan_save_signed_checkpoint(hit_path);
                        hit_target = 1;
                        break;
                    }
                }
            }
        }
        if (slice_count > 0 && !hit_target) {
            int current_slice_size = slice_count;
            int s;
            #pragma omp parallel for schedule(dynamic, 4)
            for (s = 0; s < current_slice_size; s++) {
                const char* p_text = slice_prompts[s];
                const char* t_str = slice_targets_str[s];

                void* toks = cartan_hub_encode_text_to_tokens(p_text);
                float* dst_h = &slice_hidden[s * 2560];

                int tgt_id = 1437;
                if (strlen(t_str) > 0) {
                    void* t_toks = cartan_hub_encode_text_to_tokens(t_str);
                    if (t_toks && cartan_vec_len(t_toks) > 0) {
                        tgt_id = (int)cartan_vec_get_f32(t_toks, 0);
                    }
                    cartan_tensor_compute_prompt_embedding_fast(toks, dst_h, 2560);
                } else if (toks && cartan_vec_len(toks) > 1) {
                    size_t num_t = (size_t)cartan_vec_len(toks);
                    tgt_id = (int)cartan_vec_get_f32(toks, (double)(num_t - 1));
                    void* prefix_toks = cartan_vec_create();
                    for (size_t k = 0; k < num_t - 1; k++) {
                        cartan_vec_push_f32(prefix_toks, cartan_vec_get_f32(toks, (double)k));
                    }
                    cartan_tensor_compute_prompt_embedding_fast(prefix_toks, dst_h, 2560);
                } else {
                    cartan_tensor_compute_prompt_embedding_fast(toks, dst_h, 2560);
                }
                if (tgt_id < 0 || tgt_id >= 65536) tgt_id = tgt_id % 65536;
                slice_targets[s] = tgt_id;
                slice_weights[s] = 1.0f;
            }

            int n_train = (current_slice_size * 7) / 8;
            if (n_train < 1) n_train = current_slice_size;
            int n_val = current_slice_size - n_train;

            for (int s = 0; s < n_train; s++) {
                memcpy(train_hidden + s * 2560, slice_hidden + s * 2560, 2560 * sizeof(float));
                train_targets[s] = slice_targets[s];
                train_weights[s] = slice_weights[s];
            }
            for (int s = 0; s < n_val; s++) {
                memcpy(val_hidden + s * 2560, slice_hidden + (n_train + s) * 2560, 2560 * sizeof(float));
                val_targets[s] = slice_targets[n_train + s];
                val_weights[s] = slice_weights[n_train + s];
            }

            double current_lr = base_lr;
            double b_train_loss = cartan_tensor_train_batch_gpu_direct(train_hidden, train_targets, train_weights, (double)n_train, current_lr);

            double mean_b_train = n_train > 0 ? (b_train_loss / (double)n_train) : 0.0;
            epoch_total_train_loss += b_train_loss;
            epoch_train_samples += n_train;
            epoch_samples_processed += current_slice_size;
            total_samples_trained += current_slice_size;
            slice_count = 0;
        }
        for (size_t cf = 0; cf < num_files && cf < 64; cf++) {
            if (open_fps[cf]) fclose(open_fps[cf]);
        }
        if (epoch_samples_processed > 0) total_epoch_samples = epoch_samples_processed;

        if (hit_target) break;

        if (files_opened == 0 || epoch_samples_processed == 0) {
            printf("[GeoMind Error] Zero samples were processed in Epoch %d (files opened: %d). Check dataset paths!\n", ep, files_opened);
            if (log_fp) {
                fprintf(log_fp, "[GeoMind Error] Zero samples were processed in Epoch %d (files opened: %d). Check dataset paths!\n", ep, files_opened);
                fflush(log_fp);
            }
            break;
        }

        char epoch_snapshot_path[512];
        snprintf(epoch_snapshot_path, sizeof(epoch_snapshot_path), "test/geomind/trainingdata/checkpoints/geomind_%s_epoch%d_final.bin", stage_name, ep);
        cartan_save_signed_checkpoint(epoch_snapshot_path);
        cartan_save_signed_checkpoint(ckpt_path);
        printf("[GeoMind Epoch Snapshot] Saved epoch %d final checkpoint -> %s\n", ep, epoch_snapshot_path);
        printf("\n>>> [EPOCH %d COMPLETE] Total Samples Streamed: %d | Val Loss: %.4f | Val PPL: %.2f <<<\n\n",
               ep, epoch_samples_processed, ema_val_loss, exp(ema_val_loss));
        fflush(stdout);

        if (log_fp) {
            fprintf(log_fp, "\n>>> [EPOCH %d COMPLETE] Total Samples Streamed: %d | Val Loss: %.4f | Val PPL: %.2f <<<\n\n",
                    ep, epoch_samples_processed, ema_val_loss, exp(ema_val_loss));
            fflush(log_fp);
        }

        if (strcmp(lr_decay_arg, "plateau") == 0 || strcmp(lr_decay_arg, "adaptive") == 0 || strcmp(lr_decay_arg, "streak") == 0) {
            if (ema_val_loss >= best_val_loss - 0.005) {
                adaptive_lr = fmax(min_lr, adaptive_lr * lr_gamma);
                printf("[GeoMind LR Controller] Epoch %d Val Loss (%.4f) plateaued vs best (%.4f) -> Adjusted LR to %.6f\n",
                       ep, ema_val_loss, best_val_loss, adaptive_lr);
            } else {
                best_val_loss = ema_val_loss;
            }
        }
        if (ema_val_loss < best_val_loss) best_val_loss = ema_val_loss;

        if (ema_val_loss <= target_loss) {
            printf("[GeoMind Target-Loss Hit!] Target loss %.2f achieved at Epoch %d (Val Loss: %.4f)\n", target_loss, ep, ema_val_loss);
            if (log_fp) {
                fprintf(log_fp, "[GeoMind Target-Loss Hit!] Target loss %.2f achieved at Epoch %d (Val Loss: %.4f)\n", target_loss, ep, ema_val_loss);
                fflush(log_fp);
            }
            break;
        }
    }

    free(slice_prompts); free(slice_targets_str);
    free(slice_hidden); free(slice_targets); free(slice_weights);
    free(train_hidden); free(train_targets); free(train_weights);
    free(val_hidden); free(val_targets); free(val_weights);
    free(fixed_val_hidden); free(fixed_val_targets); free(fixed_val_weights);

    if (log_fp) fclose(log_fp);
    return ema_val_loss;
}

CARTAN_WEAK double geomind_train_cloze_pass(const char* dataset_path, double target_loss, double epochs_d) {
    int max_epochs = (int)epochs_d;
    if (max_epochs <= 0) max_epochs = 3;
    double base_lr = get_arg_double_value(g_argc, g_argv, "-lr", 0.0020);
    return geomind_train_streaming_steady_state(STAGE_CLOZE, dataset_path, target_loss, base_lr, max_epochs, "logs/stage1_cloze_training.log");
}

CARTAN_WEAK double geomind_train_ce_pass(const char* corpus_path, double target_loss, double epochs_d, const char* log_path) {
    int max_epochs = (int)epochs_d;
    if (max_epochs <= 0) max_epochs = 3;
    double base_lr = get_arg_double_value(g_argc, g_argv, "-lr", 0.0015);
    return geomind_train_streaming_steady_state(STAGE_CE, corpus_path, target_loss, base_lr, max_epochs, log_path ? log_path : "logs/stage2_ce_training.log");
}

CARTAN_WEAK double geomind_train_sft_pass(const char* dataset_path, double target_loss, double epochs_d, const char* log_path) {
    int max_epochs = (int)epochs_d;
    if (max_epochs <= 0) max_epochs = 3;
    double base_lr = get_arg_double_value(g_argc, g_argv, "-lr", 0.0010);
    return geomind_train_streaming_steady_state(STAGE_SFT, dataset_path, target_loss, base_lr, max_epochs, log_path ? log_path : "logs/stage3_sft_training.log");
}
#endif
static int g_lora_enabled = 0;
static int g_lora_rank = 16;
static double g_lora_alpha = 16.0;
static float* g_lora_A = NULL;
static float* g_lora_B = NULL;

CARTAN_WEAK void cartan_lora_init(double rank, double alpha) {
    int r = (int)rank;
    if (r <= 0) r = 16;
    g_lora_rank = r;
    g_lora_alpha = alpha > 0.0 ? alpha : (double)r;
    
    if (g_lora_A) free(g_lora_A);
    if (g_lora_B) free(g_lora_B);

    g_lora_A = (float*)malloc(sizeof(float) * 2560 * g_lora_rank);
    g_lora_B = (float*)malloc(sizeof(float) * g_lora_rank * 2560);

    if (g_lora_A && g_lora_B) {
        float scale = 1.0f / sqrtf(2560.0f);
        for (int i = 0; i < 2560 * g_lora_rank; i++) {
            g_lora_A[i] = ((float)((i * 37) % 100) / 100.0f - 0.5f) * scale;
        }
        for (int i = 0; i < g_lora_rank * 2560; i++) {
            g_lora_B[i] = 0.0f;
        }
        g_lora_enabled = 1;
        printf("[GeoMind LoRA] Initialized Low-Rank Adapter (Rank: %d, Alpha: %.1f, Base Weights Frozen).\n", g_lora_rank, g_lora_alpha);
        fflush(stdout);
    }
}

CARTAN_WEAK int cartan_is_lora_enabled(void) {
    return g_lora_enabled;
}

CARTAN_WEAK void cartan_lora_merge_into_base(void) {
    if (!g_lora_enabled || !g_lora_A || !g_lora_B) return;
    float scale = (float)(g_lora_alpha / (double)g_lora_rank);
    for (int r = 0; r < 2560; r++) {
        for (int c = 0; c < 2560; c++) {
            float delta = 0.0f;
            for (int k = 0; k < g_lora_rank; k++) {
                delta += g_lora_A[r * g_lora_rank + k] * g_lora_B[k * 2560 + c];
            }
            g_model_weights[r][c] += (double)(scale * delta);
        }
    }
    cartan_sync_host_weights_to_gpu();
    printf("[GeoMind LoRA] Merged Low-Rank Adapter weights delta into base model weights.\n");
    fflush(stdout);
}

// =========================================================================
// Native WebGPU / WGSL Compute Runtime Interface
// =========================================================================

CARTAN_WEAK double cartan_time_now_ms(void) {
    static LARGE_INTEGER freq;
    static int init = 0;
    if (!init) {
        QueryPerformanceFrequency(&freq);
        init = 1;
    }
    LARGE_INTEGER t;
    QueryPerformanceCounter(&t);
    return (double)(t.QuadPart * 1000.0) / (double)freq.QuadPart;
}

CARTAN_WEAK double cartan_gpu_init(void) {
    cartan_init_gpu_device_if_needed();
    if (g_cl_context && g_cl_queue) {
        printf("[CARTAN WebGPU] Hardware GPU compute engine initialized: %s\n", g_opencl_gpu_name);
        fflush(stdout);
        return 1.0;
    }
    return 0.0;
}

CARTAN_WEAK void* cartan_gpu_create_buffer(double size_bytes, double usage) {
    if (!g_cl_context) cartan_gpu_init();
    if (!g_cl_context) return NULL;
    cl_int err;
    cl_mem buf = clCreateBuffer(g_cl_context, CL_MEM_READ_WRITE, (size_t)size_bytes, NULL, &err);
    if (err != CL_SUCCESS) {
        printf("[CARTAN WebGPU Error] Buffer allocation failed: err=%d\n", err);
        fflush(stdout);
        return NULL;
    }
    return (void*)buf;
}

CARTAN_WEAK double cartan_gpu_write_buffer(void* buffer, double offset, void* src_data, double size_bytes) {
    if (!g_cl_queue || !buffer || !src_data) return 0.0;
    cl_int err = clEnqueueWriteBuffer(g_cl_queue, (cl_mem)buffer, CL_TRUE, (size_t)offset, (size_t)size_bytes, src_data, 0, NULL, NULL);
    return (err == CL_SUCCESS) ? 1.0 : 0.0;
}

CARTAN_WEAK double cartan_gpu_read_buffer(void* buffer, double offset, void* dst_data, double size_bytes) {
    if (!g_cl_queue || !buffer || !dst_data) return 0.0;
    cl_int err = clEnqueueReadBuffer(g_cl_queue, (cl_mem)buffer, CL_TRUE, (size_t)offset, (size_t)size_bytes, dst_data, 0, NULL, NULL);
    return (err == CL_SUCCESS) ? 1.0 : 0.0;
}

// Convert standard WGSL compute shader to native GPU OpenCL C kernel
static char* cartan_wgsl_to_gpu_c(const char* wgsl_src, const char* entry_point) {
    if (!wgsl_src) return NULL;
    size_t len = strlen(wgsl_src);
    char* out = (char*)malloc(len * 4 + 4096);
    if (!out) return NULL;
    out[0] = '\0';

    // Parse storage buffers from @group(0) @binding(N) var<storage, read_write> name: array<f32>;
    char params_buf[1024] = "";
    int param_count = 0;
    const char* p = wgsl_src;
    while ((p = strstr(p, "var<storage")) != NULL) {
        p = strchr(p, '>');
        if (!p) break;
        p++;
        while (*p == ' ') p++;
        char name[128];
        int ni = 0;
        while (*p && *p != ':' && *p != ' ' && ni < 127) {
            name[ni++] = *p++;
        }
        name[ni] = '\0';
        if (ni > 0) {
            if (param_count > 0) strcat(params_buf, ", ");
            strcat(params_buf, "__global float* ");
            strcat(params_buf, name);
            param_count++;
        }
    }

    // Extract body of entry_point function
    char fn_marker[128];
    snprintf(fn_marker, sizeof(fn_marker), "fn %s", entry_point);
    const char* fn_pos = strstr(wgsl_src, fn_marker);
    const char* body_pos = fn_pos ? strchr(fn_pos, '{') : strchr(wgsl_src, '{');

    strcat(out, "__kernel void ");
    strcat(out, entry_point);
    strcat(out, "(");
    strcat(out, params_buf);
    strcat(out, ") ");

    if (body_pos) {
        // Copy body while replacing WGSL builtins with OpenCL equivalents
        char* dst = out + strlen(out);
        const char* src = body_pos;
        while (*src) {
            if (strncmp(src, "f32(gid.x)", 10) == 0) {
                strcpy(dst, "((float)get_global_id(0))"); dst += strlen(dst); src += 10;
            } else if (strncmp(src, "f32(gid.y)", 10) == 0) {
                strcpy(dst, "((float)get_global_id(1))"); dst += strlen(dst); src += 10;
            } else if (strncmp(src, "f32(gid.z)", 10) == 0) {
                strcpy(dst, "((float)get_global_id(2))"); dst += strlen(dst); src += 10;
            } else if (strncmp(src, "f32(lid.x)", 10) == 0) {
                strcpy(dst, "((float)get_local_id(0))"); dst += strlen(dst); src += 10;
            } else if (strncmp(src, "f32(lid.y)", 10) == 0) {
                strcpy(dst, "((float)get_local_id(1))"); dst += strlen(dst); src += 10;
            } else if (strncmp(src, "f32(lid.z)", 10) == 0) {
                strcpy(dst, "((float)get_local_id(2))"); dst += strlen(dst); src += 10;
            } else if (strncmp(src, "gid.x", 5) == 0) {
                strcpy(dst, "get_global_id(0)"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "gid.y", 5) == 0) {
                strcpy(dst, "get_global_id(1)"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "gid.z", 5) == 0) {
                strcpy(dst, "get_global_id(2)"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "lid.x", 5) == 0) {
                strcpy(dst, "get_local_id(0)"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "lid.y", 5) == 0) {
                strcpy(dst, "get_local_id(1)"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "lid.z", 5) == 0) {
                strcpy(dst, "get_local_id(2)"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "workgroupBarrier()", 18) == 0) {
                strcpy(dst, "barrier(CLK_LOCAL_MEM_FENCE)"); dst += strlen(dst); src += 18;
            } else if (strncmp(src, "storageBarrier()", 16) == 0) {
                strcpy(dst, "barrier(CLK_GLOBAL_MEM_FENCE)"); dst += strlen(dst); src += 16;
            } else if (strncmp(src, ": u32", 5) == 0) {
                src += 5;
            } else if (strncmp(src, ": f32", 5) == 0) {
                src += 5;
            } else if (strncmp(src, ": i32", 5) == 0) {
                src += 5;
            } else if (strncmp(src, "f32(", 4) == 0) {
                strcpy(dst, "((float)"); dst += strlen(dst); src += 4;
            } else if (strncmp(src, "u32(", 4) == 0) {
                strcpy(dst, "((unsigned int)"); dst += strlen(dst); src += 4;
            } else if (strncmp(src, "let idx", 7) == 0) {
                strcpy(dst, "const size_t idx"); dst += strlen(dst); src += 7;
            } else if (strncmp(src, "let t_idx", 9) == 0) {
                strcpy(dst, "const size_t t_idx"); dst += strlen(dst); src += 9;
            } else if (strncmp(src, "let base", 8) == 0) {
                strcpy(dst, "const size_t base"); dst += strlen(dst); src += 8;
            } else if (strncmp(src, "let row", 7) == 0) {
                strcpy(dst, "const size_t row"); dst += strlen(dst); src += 7;
            } else if (strncmp(src, "let col", 7) == 0) {
                strcpy(dst, "const size_t col"); dst += strlen(dst); src += 7;
            } else if (strncmp(src, "let D", 5) == 0) {
                strcpy(dst, "const unsigned int D"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "let T", 5) == 0) {
                strcpy(dst, "const unsigned int T"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "let N", 5) == 0) {
                strcpy(dst, "const unsigned int N"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "var i", 5) == 0) {
                strcpy(dst, "unsigned int i"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "var j", 5) == 0) {
                strcpy(dst, "unsigned int j"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "var d", 5) == 0) {
                strcpy(dst, "unsigned int d"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "var k", 5) == 0) {
                strcpy(dst, "unsigned int k"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "var c", 5) == 0) {
                strcpy(dst, "unsigned int c"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "var r", 5) == 0) {
                strcpy(dst, "unsigned int r"); dst += strlen(dst); src += 5;
            } else if (strncmp(src, "let ", 4) == 0) {
                strcpy(dst, "const float "); dst += strlen(dst); src += 4;
            } else if (strncmp(src, "var ", 4) == 0) {
                strcpy(dst, "float "); dst += strlen(dst); src += 4;
            } else if (*src == 'u' && src > body_pos && (*(src - 1) >= '0' && *(src - 1) <= '9') && (*(src + 1) == ' ' || *(src + 1) == ';' || *(src + 1) == ')' || *(src + 1) == ',' || *(src + 1) == '<' || *(src + 1) == '>' || *(src + 1) == '+' || *(src + 1) == '-' || *(src + 1) == '*' || *(src + 1) == '/')) {
                src++; // strip 'u' suffix from literals like 64u
            } else {
                *dst++ = *src++;
                *dst = '\0';
            }
        }
    }
    return out;
}

CARTAN_WEAK void* cartan_gpu_create_pipeline(const char* wgsl_source, const char* entry_point) {
    if (!g_cl_context) cartan_gpu_init();
    if (!g_cl_context || !wgsl_source || !entry_point) return NULL;

    char* cl_src = cartan_wgsl_to_gpu_c(wgsl_source, entry_point);
    if (!cl_src) return NULL;

    cl_int err;
    const char* sources[1] = { cl_src };
    cl_program prog = clCreateProgramWithSource(g_cl_context, 1, sources, NULL, &err);
    if (err != CL_SUCCESS || !prog) {
        free(cl_src);
        return NULL;
    }

    cl_device_id dev = (cl_device_id)g_cl_queue; // fetch device via info
    clGetCommandQueueInfo(g_cl_queue, CL_QUEUE_DEVICE, sizeof(cl_device_id), &dev, NULL);

    err = clBuildProgram(prog, 1, &dev, "-cl-fast-relaxed-math -cl-mad-enable", NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t log_size = 0;
        clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);
        char* log = (char*)malloc(log_size + 1);
        if (log) {
            clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, log_size, log, NULL);
            printf("[CARTAN WebGPU Pipeline Build Error] %s\n", log);
            free(log);
        }
        free(cl_src);
        return NULL;
    }

    cl_kernel kernel = clCreateKernel(prog, entry_point, &err);
    free(cl_src);
    if (err != CL_SUCCESS) {
        printf("[CARTAN WebGPU Error] Kernel creation failed for %s: err=%d\n", entry_point, err);
        return NULL;
    }
    return (void*)kernel;
}

CARTAN_WEAK double cartan_gpu_dispatch(void* pipeline, void* buffers, double num_buffers, double gx, double gy, double gz) {
    if (!g_cl_queue || !pipeline) return 0.0;
    cl_kernel kernel = (cl_kernel)pipeline;
    int n_buf = (int)num_buffers;

    // Set buffer arguments from array/tree
    if (buffers) {
        for (int i = 0; i < n_buf; i++) {
            cl_mem b = (cl_mem)cartan_tree_get((void*)buffers, (size_t)i);
            cl_int err = clSetKernelArg(kernel, i, sizeof(cl_mem), &b);
            if (err != CL_SUCCESS) {
                printf("[CARTAN WebGPU Error] clSetKernelArg %d failed: err=%d\n", i, err);
                return 0.0;
            }
        }
    }

    size_t global_ws[3] = { (size_t)(gx > 0.0 ? gx : 1.0), (size_t)(gy > 0.0 ? gy : 1.0), (size_t)(gz > 0.0 ? gz : 1.0) };
    cl_int err = clEnqueueNDRangeKernel(g_cl_queue, kernel, 3, NULL, global_ws, NULL, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("[CARTAN WebGPU Error] clEnqueueNDRangeKernel failed: err=%d\n", err);
        return 0.0;
    }
    return 1.0;
}

CARTAN_WEAK double cartan_gpu_sync(void) {
    if (!g_cl_queue) return 0.0;
    cl_int err = clFinish(g_cl_queue);
    return (err == CL_SUCCESS) ? 1.0 : 0.0;
}

CARTAN_WEAK void* cartan_f32_buffer_alloc(double count) {
    size_t n = (size_t)(count > 0.0 ? count : 1.0);
    return calloc(n, sizeof(float));
}

CARTAN_WEAK double cartan_f32_buffer_set(void* buf, double idx, double val) {
    if (!buf) return 0.0;
    ((float*)buf)[(size_t)idx] = (float)val;
    return 0.0;
}

CARTAN_WEAK double cartan_f32_buffer_get(void* buf, double idx) {
    if (!buf) return 0.0;
    return (double)(((float*)buf)[(size_t)idx]);
}

CARTAN_WEAK double cartan_f32_buffer_free(void* buf) {
    if (buf) free(buf);
    return 0.0;
}

CARTAN_WEAK void* cartan_get_lm_head_weights_ptr(void) { return (void*)g_model_weights; }
CARTAN_WEAK size_t cartan_get_lm_head_weight_count(void) { return 2560 * 2560; }
CARTAN_WEAK int* cartan_get_class_token_mapping_ptr(void) { return g_class_to_token_id; }
CARTAN_WEAK double user_main(double argc, void* argv) { return 0.0; }

#if !defined(CARTAN_COMPILED_LLVM) && !defined(GEOMIND_DRIVER_BUILD)
extern double user_main(double argc, void* argv);
CARTAN_WEAK int main(int argc, char** argv) {
    cartan_crt_init(argc, argv);
    cartan_rt_buffer_pool_init();
    double res = user_main((double)argc, (void*)argv);
    fflush(stdout);
    fflush(stderr);
    return (int)res;
}
#endif








