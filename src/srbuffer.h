#ifndef soluna_srbuffer_h
#define soluna_srbuffer_h

#include <stdint.h>

#define MAX_SR 4096

struct sr_mat {
	float v[4];
};

struct sr_buffer {
	int n;
	int dirty;
	int current_n;
	uint8_t current_frame;
	uint8_t frame[MAX_SR];
	uint16_t cache[MAX_SR];
	uint32_t key[MAX_SR];
	struct sr_mat data[MAX_SR];
};

void srbuffer_init(struct sr_buffer *SR);
int srbuffer_add(struct sr_buffer *SR, uint32_t sr);
void * srbuffer_commit(struct sr_buffer *SR, int *sz);

#endif
