#include <stdio.h>

extern double user_main();

int main(int argc, char** argv) {
    printf("=== CARTAN C LAUNCHER START ===\n");
    fflush(stdout);
    user_main();
    printf("=== CARTAN C LAUNCHER END ===\n");
    fflush(stdout);
    return 0;
}
