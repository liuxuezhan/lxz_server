#ifndef _FFCTX_H_
#define _FFCTX_H_

	typedef struct {
		unsigned int sd;
		int dis1;
		int dis2;
		int index;
		int carry;  
		unsigned int buffer[64];
	} AddiKey;


	typedef struct {
		unsigned int sd;
		int index;
		AddiKey addikey[3];
		unsigned char buffer[0x1000];
	} Ctx;

	void ctx_init(unsigned int sd, Ctx *ctx);
	void ctx_encode(Ctx *ctx, void *buffer, int len);

#endif

