#include "schema.h"
#include <assert.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h> //for error printing

static int match_path(const char *uri, const char *pattern)
{
    if(!pattern)
        return 0;

    //uri_i = pattern_j when uri_i !\in range
    //range = atoi(pattern_j) when \in  range

    while(*uri && *pattern)
    {
        if(*pattern != '[') {
            if(*uri != *pattern)
                return 0;
            uri++;
            pattern++;
        } else {
            pattern++;
            assert(isdigit(*pattern));
            int low = atoi(pattern);
            while(*pattern && isdigit(*pattern))
                pattern++;
            assert(*pattern == ',');
            pattern++;
            int high = atoi(pattern);
            while(*pattern && isdigit(*pattern))
                pattern++;
            assert(*pattern == ']');
            pattern++;

            int real = atoi(uri);
            while(*uri && isdigit(*uri))
                uri++;

            if(real < low || real > high)
                return 0;
        }

    }

    //partial match, but not a complete one
    if(!*pattern && *uri)
        return 0;

    return 1;
}

void br_destroy_schema(schema_t sch)
{
    free(sch.json);
    for(int i=0; i<sch.elements; ++i) {
        if(sch.handles[i].opts) {
            free(sch.handles[i].opts->ids);
            for(size_t j=0; j<sch.handles[i].opts->num_opts; ++j)
                free((void*)sch.handles[i].opts->labels[j]);
            free(sch.handles[i].opts->labels);
        }
        free((void*)sch.handles[i].documentation);
        free((void*)sch.handles[i].name);
        free((void*)sch.handles[i].short_name);
        free((void*)sch.handles[i].pattern);
        free((void*)sch.handles[i].default_);
        free(sch.handles[i].opts);
    }
    free(sch.handles);
}

//Schema
schema_handle_t sm_get(schema_t sch, uri_t u)
{
    schema_handle_t invalid;
    memset(&invalid, 0, sizeof(invalid));
    invalid.flag = 0xdeadbeef;
    //printf("Getting a handle(%s)...\n", u);
    for(int i=0; i<sch.elements; ++i)
        if(match_path(u, sch.handles[i].pattern))
            return sch.handles[i];
    if(!(strstr(u, "VoicePar") && strstr(u, "Enabled")))
        printf("[WARNING:osc-bridge] Invalid Handle \"%s\"...\n", u);
    return invalid;
}
str_t sm_get_name(schema_handle_t h)
{
    return h.name ? h.name : "";
}

str_t sm_get_short(schema_handle_t h)
{
    return h.short_name ? h.short_name : "";
}

str_t sm_get_tooltip(schema_handle_t h)
{
    return h.documentation ? h.documentation : "";
}

str_t sm_get_units(schema_handle_t h)
{
    (void) h;
    return "";
}

float sm_get_min_flt(schema_handle_t h)
{
    return h.value_min;
}

float sm_get_max_flt(schema_handle_t h)
{
    return h.value_max;
}

int sm_valid(schema_handle_t h)
{
    return h.flag != (int) 0xdeadbeef;
}

