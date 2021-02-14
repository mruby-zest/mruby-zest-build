#ifndef OSC_BRIDGE_CACHE
#define OSC_BRIDGE_CACHE
#include <stdint.h>

//Forward definitions for rtosc
//This avoids the need for other libs to need any information
//about rtosc
#ifndef RTOSC_H
typedef struct {
    int32_t len;
    uint8_t *data;
} rtosc_blob_t;

typedef union {
    int32_t       i;   //i,c,r
    char          T;   //I,T,F,N
    float         f;   //f
    double        d;   //d
    int64_t       h;   //h
    uint64_t      t;   //t
    uint8_t       m[4];//m
    const char   *s;   //s,S
    rtosc_blob_t  b;   //b
} rtosc_arg_t;
#endif

typedef struct {
    //Path of OSC value
    char *path;
    //TODO condense valid+pending+usable into one variable
    char  valid:1;
    char  pending:1;
    char  usable:1;
    char  force_refresh:1;

    //Type of OSC value stored in cache
    //In the case of multiple values, type is 'v'
    char  type;

    //Time that last request was issued. Useful to:
    //- avoid repeated requests in the case of lost packets
    //- track remote latency
    double request_time;

    //Number of times a value has been requested without a response
    //A high number of requests either indicates high packet loss or that the
    //remote application will not respond to the parameter (i.e. the parameter
    //doesn't exist)
    int   requests;

    //Data stored
    union {
        rtosc_arg_t val;
        struct {
            const char  *vec_type;
            rtosc_arg_t *vec_value;
        };
    };
} param_cache_t;
#endif
