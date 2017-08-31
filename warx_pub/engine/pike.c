#include "pike.h"
#define GENIUS_NUMBER 0x05027919

static void linearity(unsigned int *code)
{
    unsigned int key = *code;
    *code = (((( key >> 31 )
            ^ ( key >> 6  )
            ^ ( key >> 4  )
            ^ ( key >> 2  )
            ^ ( key >> 1  )
            ^   key       )
            &   0x00000001 )
            <<  31         )
            | ( key >> 1   );
}


static void addikey_next(AddiKey *addikey)
{
    int i1, i2;
    ++addikey->index;
    addikey->index &= 0x03F;

    i1 = ((addikey->index | 0x40) - addikey->dis1) & 0x03F;
    i2 = ((addikey->index | 0x40) - addikey->dis2) & 0x03F;

    addikey->buffer[addikey->index] =  addikey->buffer[i1] + addikey->buffer[i2];
    addikey->carry = (addikey->buffer[addikey->index] < addikey->buffer[i1]) || (addikey->buffer[addikey->index] < addikey->buffer[i2]) ;
}


static void ctx_generate(Ctx *ctx)
{
    int i, j, flag, carry;
    for(i = 0; i < 1024; ++i) {
        carry = ctx->addikey[0].carry + ctx->addikey[1].carry + ctx->addikey[2].carry;
        if (carry ==0 || carry == 3) {
            addikey_next(&ctx->addikey[0]);
            addikey_next(&ctx->addikey[1]);
            addikey_next(&ctx->addikey[2]);
        } else {
            flag = 0;
            if(carry == 2) flag = 1;
            for(j = 0; j < 3; ++j) {
                if(ctx->addikey[j].carry == flag)  addikey_next(&ctx->addikey[j]);
            }
        }

        *(unsigned int *)(&ctx->buffer[i*4]) =  ctx->addikey[0].buffer[ctx->addikey[0].index]
                                               ^ ctx->addikey[1].buffer[ctx->addikey[1].index]
                                               ^ ctx->addikey[2].buffer[ctx->addikey[2].index];
    }
    ctx->index = 0;
}


void ctx_init(unsigned int sd, Ctx *ctx)
{
    unsigned int tmp;
    int i, j, k;

    ctx->sd = sd ^ GENIUS_NUMBER;
    
    ctx->addikey[0].sd = ctx->sd;
    linearity(&ctx->addikey[0].sd);
    ctx->addikey[0].dis1 = 55;
    ctx->addikey[0].dis2 = 24;


    ctx->addikey[1].sd =   ((ctx->sd & 0xAAAAAAAA) >> 1)|( (ctx->sd & 0x55555555) <<1 );
    linearity(&ctx->addikey[1].sd);
    ctx->addikey[1].dis1 = 57;
    ctx->addikey[1].dis2 = 7;
    
    ctx->addikey[2].sd =  ~(((ctx->sd & 0xF0F0F0F0) >> 4)|( (ctx->sd & 0x0F0F0F0F) <<4 ));
    linearity(&ctx->addikey[2].sd);
    ctx->addikey[2].dis1 = 58;
    ctx->addikey[2].dis2 = 19;


    for(i = 0; i < 3; ++i) {
        tmp = ctx->addikey[i].sd;
        for(j = 0; j < 64; ++j) {
            for(k = 0; k < 32; ++k) {
                linearity(&tmp);
            }
            ctx->addikey[i].buffer[j] = tmp;
        }
        ctx->addikey[i].carry = 0;
        ctx->addikey[i].index = 63;
    }

    ctx->index = 4096;
}


void ctx_encode(Ctx *ctx, void *buffer, int len)
{
    unsigned char *data;
    unsigned char *ptr;
    int i, remnant;


    if(len <= 0)  return;
    if(!buffer) return;

    data=(unsigned char *)buffer;
    ptr = 0;

    do {
        remnant = 4096 - ctx->index;
        if (remnant <= 0) {
            ctx_generate(ctx);
            continue;
        }
        
        if (remnant > len) remnant = len;
        len -= remnant;

        ptr = ctx->buffer + ctx->index;
        
        for(i=0; i < remnant - 3; i+=4, data+=4, ptr+=4) {
            *(unsigned int *)data ^= *(unsigned int *)ptr;            
        }
        
        for(; i < remnant; ++i, ++data, ++ptr) {
            *data ^= *ptr;
        }
        
        ctx->index += remnant;       
    } while (len>0);        
}

/*
char *App;
int main(int argc, char *argv[])
{
    App = argv[0];
    Ctx ctx;
    //ctx_init(1234567, &ctx);
    ctx_init(51257067, &ctx);
    ctx_generate(&ctx);

    int i, idx;
    unsigned int code;
    for (idx = 0; idx < 1024; ++idx) {
        for(i = 0; i < 1024; ++i) {
            code = *(unsigned int*)&ctx.buffer[i * 4];
            if (idx == 0) 
                LOG("%04d: %04d : %lu", idx, i, code);
        }
        ctx_generate(&ctx);
    }
    return 1;
}
*/


