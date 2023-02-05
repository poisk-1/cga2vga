#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

const size_t rom_size = ROM_SIZE_KB * 1024;

int main(int argc, char **argv) {
	if (argc != 3) {
		printf("usage: romify <source> <target>\r\n");
		return 1;
	}

	uint8_t *rom_buffer = malloc(rom_size);
	memset(rom_buffer, 0, rom_size);
	
	if (!rom_buffer) {
		printf("error: can't allocate rom buffer\r\n");
		return 1;
	}

	FILE *src_file = fopen(argv[1], "r");
	
	if (!src_file) {
		printf("error: can't open source file\r\n");
		return 1;
	}

	size_t src_size = fread(rom_buffer, sizeof(uint8_t), rom_size, src_file);

	if (src_size == rom_size) {
		printf("error: source file is larger than rom\r\n");
		return 1;
	}


	FILE *tgt_file = fopen(argv[2], "w");
	
	if (!tgt_file) {
		printf("error: can't open target file\r\n");
		return 1;
	}

        uint8_t blk_size = 1 + ((src_size + 1) >> 9);

	rom_buffer[2] = blk_size;

	uint8_t check_sum = 0;

	for (size_t i = 0; i < src_size; i++) check_sum += rom_buffer[i];

	rom_buffer[src_size] = 0x100 - check_sum;

	fwrite(rom_buffer, sizeof(uint8_t), rom_size, tgt_file);

	free(rom_buffer);

	return 0;
}
