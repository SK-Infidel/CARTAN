#include <string.h>
#include <stdlib.h>
#include <stdio.h>

float cartan_string_eq(const char* s1, const char* s2) {
    if (!s1 || !s2) return 0.0;
    return strcmp(s1, s2) == 0 ? 1.0 : 0.0;
}

char* cartan_string_concat(const char* s1, const char* s2) {
    if (!s1) s1 = "";
    if (!s2) s2 = "";
    char* res = (char*)malloc(strlen(s1) + strlen(s2) + 1);
    strcpy(res, s1);
    strcat(res, s2);
    return res;
}

extern void* cartan_tree_get(void* tree, float idx);
void* debug_tree_get(void* tree, float idx) {
    return cartan_tree_get(tree, idx);
}

float cartan_string_starts_with(const char* s, const char* prefix) {
    if (!s || !prefix) return 0.0;
    return strncmp(s, prefix, strlen(prefix)) == 0 ? 1.0 : 0.0;
}

float cartan_string_length(const char* s) {
    if (!s) return 0.0;
    return (float)strlen(s);
}

char* cartan_float_to_string(float f) {
    char* buf = (char*)malloc(64);
    snprintf(buf, 64, "%g", f);
    return buf;
}
