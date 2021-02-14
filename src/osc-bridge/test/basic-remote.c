#include <rtosc/rtosc.h>
#include "../src/bridge.h"
#include "common.h"
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>

float Pfreq     = 12345.0;
int Pfreqrand   = 255;
bool Pcontinous = true;

void print_response(const char *osc, void *vv)
{
    char type = rtosc_type(osc, 0);
    //printf("[callback] got a message '%s':%c data=%p...\n", osc, type, v);

    rtosc_arg_t arg = rtosc_argument(osc, 0);

    if(!vv)
        return;
    void *v = *(void**)vv;


    if(type == 'i')
        *(int*)v = arg.i;
    else if(type == 'T')
        *(bool*)v = true;
    else if(type == 'F')
        *(bool*)v = false;
    else if(type == 'f')
        *(float*)v = arg.f;

    //if(type == 'i')
    //    printf("[callback] value = %d\n", arg.i);
    //else if(type == 'f')
    //    printf("[callback] value = %a\n", (double)arg.f);
    //else if(type == 'T')
    //    printf("[callback] value = true\n");
    //else if(type == 'F')
    //    printf("[callback] value = false\n");
}

float asdf = 0x1.93264cp-2;


//Paths to check for a minimal(ish) example subwindow
const char *paths[] = {
"/part0/kit0/adpars/VoicePar0/FreqLfo/Pfreq",
"/part0/kit0/adpars/VoicePar0/FreqLfo/Pintensity",
"/part0/kit0/adpars/VoicePar0/FreqLfo/Pstartphase",
"/part0/kit0/adpars/VoicePar0/FreqLfo/PLFOtype",
"/part0/kit0/adpars/VoicePar0/FreqLfo/Prandomness",
"/part0/kit0/adpars/VoicePar0/FreqLfo/Pfreqrand",
"/part0/kit0/adpars/VoicePar0/FreqLfo/Pdelay",
"/part0/kit0/adpars/VoicePar0/FreqLfo/Pcontinous",
"/part0/kit0/adpars/VoicePar0/FreqLfo/Pstretch",
};
void test_lfo(schema_t schema, bridge_t *bridge)
{
    for(unsigned i=0; i<sizeof(paths)/sizeof(paths[0]); ++i) {
        uri_t uri = paths[i];
        printf("#Testing address '%s'\n", uri);
        schema_handle_t handle = sm_get(schema, uri);

        assert_true(sm_valid(handle), "Verify Handle", __LINE__);

        //printf("(1#{%s} 2#{%s} 3#{%s} 4#{%s}\n",
        //sm_get_name(handle),    sm_get_short(handle),
        //sm_get_tooltip(handle), sm_get_units(handle));
        br_add_callback(bridge, uri, print_response, NULL);
        void **data = malloc(sizeof(void*));
        if(strstr(uri, "Pfreqrand")) {
            *data = &Pfreqrand;
            br_add_callback(bridge, uri, print_response, (void*)data);
        } else if(strstr(uri, "Pfreq")) {
            *data = &Pfreq;
            br_add_callback(bridge, uri, print_response, (void*)data);
        } else if(strstr(uri, "Pcontinous")) {
            *data = &Pcontinous;
            br_add_callback(bridge, uri, print_response, (void*)data);
        } else
            free(data);
    }
}

int main()
{
    test_plan(17);
    //Define that there is a bridge on localhost:1337
    printf("#Creating Bridge To Remote...\n");
    bridge_t *bridge = br_create("osc.udp://localhost:1337");

    //Get the bridge to obtain the schema
    printf("#Creating Schema For Remote...\n");
    schema_t schema = br_get_schema(bridge, "/schema");
    
    assert_true(1000 <  schema.elements,
            "Schema has around the right number of elements", __LINE__);

    test_lfo(schema, bridge);

    br_recv(bridge, 0);

    assert_int_eq(9, bridge->cache_len,
            "Check Cache Size", __LINE__);
    assert_int_eq(12, bridge->callback_len,
            "Check Callback Size", __LINE__);


    //print_stats(bridge, schema);
    

    int old_pending = br_pending(bridge);
    //printf("STARTING UV RUN...\n");
    struct timeval tv1;
    struct timeval tv2;
    gettimeofday(&tv1, 0);
    int tic = 0;
    while(old_pending) {
        uv_run(bridge->loop, UV_RUN_NOWAIT);
        int new_pending = br_pending(bridge);
        tic++;
        if(old_pending != new_pending)
            old_pending = new_pending;
        else
            usleep(1);
        gettimeofday(&tv2, 0);
        float delta = (tv2.tv_sec-tv1.tv_sec) + 1e-6*(tv2.tv_usec-tv1.tv_usec);
        if(delta > 0.100)
            break;
    }
    gettimeofday(&tv2, 0);
    float delta = (tv2.tv_sec-tv1.tv_sec) + 1e-6*(tv2.tv_usec-tv1.tv_usec);
    printf("#delta time is %f ms\n", delta*1e3);


    assert_int_eq(0, old_pending, "Cache is up-to-date", __LINE__);
    assert_true(delta < 0.100, "Check for timeout", __LINE__);

    assert_flt_eq(0x1.93264cp-2, Pfreq, "Default frequency is set", __LINE__);
    assert_int_eq(0, Pfreqrand, "Default randomness is zero", __LINE__);
    assert_false(Pcontinous, "Default LFO is not continious", __LINE__);

    br_destroy(bridge);
    br_destroy_schema(schema);

    return test_summary();
}
