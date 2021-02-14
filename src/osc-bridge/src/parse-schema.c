#include "schema.h"
#define MM_JSON_IMPLEMENTATION
#include "mm_json.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

//Disable debug prints
#define printf(...) do {} while(0)
#define putchar(x) (void)(x)

//Shadow string duplication due to windows build issues
#ifdef  strndup
#undef  strndup
#endif
#define strndup(dat, len) strndup_custom(dat,len)

static char *strndup_custom(const char *data, int len)
{
    char *dest = calloc(len+1,1);
    for(int i=0; i<len; ++i)
        dest[i] = data[i];
    return dest;
}


void print_string(const char *str, unsigned len)
{
    for(unsigned i=0; i<len; ++i)
        putchar(str[i]);
}

opt_t *parse_options(const char *str, int len)
{
    printf("parse options...\n");
    opt_t *o = calloc(1, sizeof(opt_t));
    struct mm_json_iter array = mm_json_begin(str, len);
    struct mm_json_token tok;
    array = mm_json_read(&tok, &array);
    while(array.src) {
        //printf("option?\n");

        int   id   = 0xcafebeef;
        char *text = 0;

        struct mm_json_iter array2 = mm_json_begin(tok.str, tok.len);
        struct mm_json_pair pair;
        array2 = mm_json_parse(&pair, &array2);
        while (!array2.err) {
            assert(pair.name.type == MM_JSON_STRING);

            if(pair.value.type == MM_JSON_STRING) {
                struct mm_json_token v = pair.value;
                if(mm_json_cmp(&pair.name, "value") == 0)
                    text = strndup(v.str, v.len);
            } else if(pair.value.type == MM_JSON_NUMBER) {
                struct mm_json_token v = pair.value;
                if(mm_json_cmp(&pair.name, "id") == 0)
                    id = atoi(v.str);
            } else
                printf(" = ????\n");

            array2 = mm_json_parse(&pair, &array2);
        }

        assert(id != (int) 0xcafebeef);

        //Add to the list of options
        o->num_opts++;
        o->ids = realloc(o->ids, sizeof(o->ids[0])*o->num_opts);
        o->labels = realloc(o->labels, sizeof(o->labels[0])*o->num_opts);
        o->ids[o->num_opts-1]    = id;
        o->labels[o->num_opts-1] = text;
        //printf(" %d -> <%s>\n", id, text);


        array = mm_json_read(&tok, &array);
    }
    return o;
}

void parse_range(schema_handle_t *handle, const char *str, int len)
{
    struct mm_json_iter array = mm_json_begin(str, len);
    struct mm_json_token tok;
    array = mm_json_read(&tok, &array);
    if(!array.src) {
        fprintf(stdout, "[WARNING] Unexpected range termination in parse_range()\n");
        return;
    }

    if(tok.type == MM_JSON_NUMBER)
        handle->value_min = atof(tok.str);
    else
        fprintf(stdout, "[WARNING] Unexpected Range Type %d For Min\n", tok.type);

    array = mm_json_read(&tok, &array);
    if(!array.src) {
        fprintf(stdout, "[WARNING] Unexpected range termination in parse_range() P2\n");
        return;
    }

    if(tok.type == MM_JSON_NUMBER)
        handle->value_max = atof(tok.str);
    else
        fprintf(stdout, "[WARNING] Unexpected Range Type %d For Max\n", tok.type);
}

void parse_schema(const char *json, schema_t *sch)
{
    sch->elements = 0;
    sch->handles  = 0;

    /* Lexer example */
    mm_json_size len = strlen(json);

    /* create iterator  */
    struct mm_json_iter iter;
    iter = mm_json_begin(json, len);

    //Read in parameters
    struct mm_json_pair pair;
    iter = mm_json_parse(&pair, &iter);
    assert(!mm_json_cmp(&pair.name, "parameters"));
    assert(pair.value.type == MM_JSON_ARRAY);

    //Read in parameter objects
    struct mm_json_iter array = mm_json_begin(pair.value.str, pair.value.len);
    struct mm_json_token tok;
    array = mm_json_read(&tok, &array);
    while (array.src) {
        /* read single token */
        printf("new schema handle...\n");
        sch->elements += 1;
        sch->handles   = realloc(sch->handles, sch->elements*sizeof(schema_handle_t));

        schema_handle_t *handle = sch->handles+(sch->elements-1);
        memset(handle, 0, sizeof(schema_handle_t));

        struct mm_json_iter array2 = mm_json_begin(tok.str, tok.len);
        struct mm_json_pair pair2;
        array2 = mm_json_parse(&pair2, &array2);
        while (!array2.err) {
            assert(pair2.name.type == MM_JSON_STRING);
            printf("  ");
            print_string(pair2.name.str, pair2.name.len);
            unsigned pad = pair2.name.len < 10 ? 10-pair2.name.len : 0;
            for(unsigned i=0; i<pad; ++i)
                putchar(' ');

            if(pair2.value.type == MM_JSON_STRING) {
                printf(" = \"");
                print_string(pair2.value.str, pair2.value.len);
                printf("\"\n");

                struct mm_json_token v = pair2.value;
                if(mm_json_cmp(&pair2.name, "path") == 0)
                    handle->pattern = strndup(v.str, v.len);
                else if(mm_json_cmp(&pair2.name, "name") == 0)
                    handle->name = strndup(v.str, v.len);
                else if(mm_json_cmp(&pair2.name, "shortname") == 0)
                    handle->short_name = strndup(v.str, v.len);
                else if(mm_json_cmp(&pair2.name, "units") == 0)
                    handle->units = strndup(v.str, v.len);
                else if(mm_json_cmp(&pair2.name, "scale") == 0)
                    handle->scale = strndup(v.str, v.len);
                else if(mm_json_cmp(&pair2.name, "tooltip") == 0)
                    handle->documentation = strndup(v.str, v.len);
                else if(mm_json_cmp(&pair2.name, "default") == 0)
                    handle->default_ = strndup(v.str, v.len);
                else if(mm_json_cmp(&pair2.name, "type") == 0) {
                    if(v.str[0] == 'i')
                        handle->type = 'i';
                    else if(v.str[0] == 'f')
                        handle->type = 'f';
                    else if(v.str[0] == 'T')
                        handle->type = 'T';
                    else
                        handle->type = 0;
                }
            } else if(pair2.value.type == MM_JSON_ARRAY &&
                    mm_json_cmp(&pair2.name, "options") == 0) {
                handle->opts = parse_options(pair2.value.str, pair2.value.len);
            } else if(pair2.value.type == MM_JSON_ARRAY &&
                    mm_json_cmp(&pair2.name, "range") == 0) {
                parse_range(handle, pair2.value.str, pair2.value.len);
            } else
                printf(" = ????\n");
            array2 = mm_json_parse(&pair2, &array2);
        }

        //MM_JSON_OBJECT
        array = mm_json_read(&tok, &array);
    }

    {
        printf("ACTIONS...\n\n");
        iter = mm_json_parse(&pair, &iter);
        assert(!mm_json_cmp(&pair.name, "actions"));
        assert(pair.value.type == MM_JSON_ARRAY);

        //Read in parameter objects
        struct mm_json_iter array = mm_json_begin(pair.value.str, pair.value.len);
        struct mm_json_token tok;
        iter = mm_json_read(&tok, &array);
        while (array.src) {
            /* read single token */
            printf("field.type = %d\n", tok.type);
            struct mm_json_iter array2 = mm_json_begin(tok.str, tok.len);
            struct mm_json_pair pair2;
            array2 = mm_json_parse(&pair2, &array2);
            while (!array2.err) {
                assert(pair2.name.type == MM_JSON_STRING);
                printf("  field.name[");
                print_string(pair2.name.str, pair2.name.len);
                if(pair2.value.type == MM_JSON_STRING) {
                    printf("] = \"");
                    print_string(pair2.value.str, pair2.value.len);
                    printf("\"\n");
                } else
                    printf("] = ????\n");
                array2 = mm_json_parse(&pair2, &array2);
            }

            //MM_JSON_OBJECT
            array = mm_json_read(&tok, &array);
        }
    }

    return;

    /* read subobject (array/objects) */
    iter = mm_json_parse(&pair, &iter);
    printf("pair.name = %s\n", pair.name.str);
    printf("pair.value.type = %d\n", pair.value.type);
    assert(pair.value.type == MM_JSON_ARRAY);

}
