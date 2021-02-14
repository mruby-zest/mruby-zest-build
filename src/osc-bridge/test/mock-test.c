#include <rtosc/rtosc.h>
#include "../src/bridge.h"
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <unistd.h>
#include "common.h"

int  v1 = 0xff;
int  v2 = 0xff;
bool v3 = false;

int osc_socket_hook_fn(void)
{
    return 0;
}

int osc_request_hook_fn(bridge_t *br, const char *msg)
{
    // /schema        - return the schema file
    // /part0/Pvolume - return the volume
    char *buffer = NULL;

    const char *args = rtosc_argument_string(msg);
    //printf("[REQUEST] osc_request_hook_fn(%p,%s,%s)\n", br, msg,args);
    if(!strcmp(msg, "/schema") && !strcmp(args, "")) {
        size_t buf_size = rtosc_message(NULL, 0, "/schema", "s", "");
        buffer = malloc(buf_size);
        rtosc_message(buffer, buf_size, "/schema", "s", "");
        br_recv(br, buffer);
    } else if(!strcmp(msg, "/part0/Pvolume") && !strcmp(args, "")) {
        size_t buf_size = rtosc_message(NULL, 0, "/part0/Pvolume", "i", 32);
        buffer = malloc(buf_size);
        rtosc_message(buffer, 128, "/part0/Pvolume", "i", 32);
        br_recv(br, buffer);
    } else if(!strcmp(msg, "/part0/Penabled") && !strcmp(args, "")) {
        size_t buf_size = rtosc_message(NULL, 0, "/part0/Penabled", "T");
        buffer = malloc(buf_size);
        rtosc_message(buffer, buf_size, "/part0/Penabled", "T");
        br_recv(br, buffer);
    } else if(!strcmp(msg, "/vector/test")) {
        //do nothing
    } else {
        printf("[ERROR] unexpected message...\n");
        assert(false);
        return 0;
    }

    //TODO send the message

    free(buffer);

    return 0;
}



void print_response(const char *osc, void *vv)
{
    char type = rtosc_type(osc, 0);
    //printf("[callback] got a message '%s':%c data=%p...\n", osc, type, v);

    rtosc_arg_t arg = rtosc_argument(osc, 0);

    void *v = *(void**)vv;

    if(type == 'i')
        *(int*)v = arg.i;
    else if(type == 'T')
        *(bool*)v = true;
    else if(type == 'F')
        *(bool*)v = false;
    else if(type == 'f')
        for(rtosc_arg_itr_t itr = rtosc_itr_begin(osc); !rtosc_itr_end(itr);)
            printf("# vec arg %f\n", rtosc_itr_next(&itr).val.f);

    //if(type == 'i')
    //    printf("[callback] value = %d\n", arg.i);
    //else if(type == 'f')
    //    printf("[callback] value = %f\n", arg.f);
    //else if(type == 'T')
    //    printf("[callback] value = true\n");
    //else if(type == 'F')
    //    printf("[callback] value = false\n");
}

void test_pvolume(schema_t schema, bridge_t *bridge)
{
    //Add a view to /part0/Pvolume
    printf("#Grabbing Pvolume Handle On Schema...\n");
    uri_t uri = "/part0/Pvolume";
    schema_handle_t handle = sm_get(schema, uri);

    assert_true(sm_valid(handle), "A valid handle is obtained", __LINE__);

    //printf("Obtained Handle for <%s>...\n", uri);
    assert_str_eq("Pvolume", sm_get_name(handle),
            "The name of the parameter is available", __LINE__);
    assert_str_eq("Vol", sm_get_short(handle),
            "The abbreviated name is available", __LINE__);
    assert_str_eq("Part Volume", sm_get_tooltip(handle),
            "The tooltip is available", __LINE__);
    assert_str_eq("", sm_get_units(handle),
            "Optional units have some return value", __LINE__);

    void **v1_ = malloc(sizeof(void*));
    void **v2_ = malloc(sizeof(void*));
    *v1_ = &v1;
    *v2_ = &v2;

    br_add_callback(bridge, uri, print_response, v1_);
    br_add_callback(bridge, uri, print_response, v2_);
}

void test_enable(schema_t schema, bridge_t *bridge)
{
    printf("#Grabbing Penabled Handle On Schema...\n");
    uri_t uri = "/part0/Penabled";
    schema_handle_t handle = sm_get(schema, uri);

    assert_true(sm_valid(handle), "A valid handle is obtained", __LINE__);
    assert_str_eq("Penabled", sm_get_name(handle),
            "The name of the parameter is available", __LINE__);
    assert_str_eq("enable", sm_get_short(handle),
            "The abbreviated name is available", __LINE__);
    assert_str_eq("Part enable", sm_get_tooltip(handle),
            "The tooltip is available", __LINE__);
    assert_str_eq("", sm_get_units(handle),
            "Optional units have some return value", __LINE__);

    void **v3_ = malloc(sizeof(void*));
    *v3_ = &v3;

    br_add_callback(bridge, uri, print_response, v3_);
}

void test_options(schema_t schema, bridge_t *bridge)
{
    (void) bridge;
    printf("#Grabbing filter type...\n"); 
    uri_t uri = "/part3/kit8/adpars/VoicePar3/FMSmp/Pfiltertype";
    schema_handle_t handle = sm_get(schema, uri);

    assert_true(sm_valid(handle), "A valid handle is obtained", __LINE__);
    assert_int_eq(14, handle.opts->num_opts, "All Options are recorded", __LINE__);
    assert_int_eq(7, handle.opts->ids[7], "The Option Id is recorded", __LINE__);
    assert_str_eq("hp2", handle.opts->labels[7], "The Option label is recorded", __LINE__);
}

void test_part_level(schema_t schema, bridge_t *bridge)
{
    test_pvolume(schema, bridge);
    test_enable(schema, bridge);
}

void test_vector_functionality(bridge_t *br)
{
    char buffer[1024];
    rtosc_message(buffer, sizeof(buffer), "/vector/test", "ffff", 1.1, 2.2, 3.3, 4.4);
    br_recv(br, buffer);
    br_recv(br, buffer);
    void **v1_ = malloc(sizeof(void*));
    *v1_ = &v1;

    br_add_callback(br, "/vector/test", print_response, v1_);
}

int main()
{
    bool verbose = false;
    test_plan(21);

    //Apply Debug Hooks
    printf("#Setting up hooks...\n");
    osc_request_hook = osc_request_hook_fn;
    osc_socket_hook  = osc_socket_hook_fn;

    //Define that there is a bridge on localhost:1337
    bridge_t *bridge = br_create("osc.udp://localhost:1337");
    assert_non_null(bridge, "A Bridge is allocated", __LINE__);

    //Get the bridge to obtain the schema
    printf("#Creating Schema For Remote...\n");
    schema_t schema = br_get_schema(bridge, "/schema");
    assert_true(1000 <  schema.elements,
            "Schema has around the right number of elements", __LINE__);

    assert_int_eq(255, v1, "Verify pre-callback #1 data", __LINE__);
    assert_int_eq(255, v2, "Verify pre-callback #2 data", __LINE__);
    assert_false(v3, "Verify pre-callback #3 data", __LINE__);

    test_part_level(schema, bridge);
    test_options(schema, bridge);
    assert_int_eq(32, v1, "Callback #1 was applied", __LINE__);
    assert_int_eq(32, v2, "Callback #2 was applied", __LINE__);
    assert_true(v3, "Callback #3 was applied", __LINE__);

    br_default(bridge, schema, "/part0/Pvolume");

    assert_int_eq(96, v1, "Default #1 was applied", __LINE__);
    assert_int_eq(96, v2, "Default #2 was applied", __LINE__);

    printf("#bridge receive...\n");
    assert_int_eq(2, bridge->cache_len,
            "Verify number of cache fields", __LINE__);
    assert_int_eq(3, bridge->callback_len,
            "Verify number of callbacks", __LINE__);
    br_recv(bridge, 0);

    if(verbose) {
        for(int i=0; i<bridge->callback_len; ++i)
            printf("callback[%d][%s][%p]\n", i, bridge->callback[i].path,
                    bridge->callback[i].data);
        for(int i=0; i<bridge->cache_len; ++i)
            printf("cache[%d][%s][%d]\n", i, bridge->cache[i].path,
                    bridge->cache[i].pending);
    }

    assert_int_eq(0, br_pending(bridge),
            "No Cache Line is Pending", __LINE__);

    test_vector_functionality(bridge);

    //cleanup
    br_destroy(bridge);
    br_destroy_schema(schema);


    return test_summary();
}
