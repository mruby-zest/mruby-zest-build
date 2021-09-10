#include <rtosc/rtosc.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include <stdlib.h>
#include "bridge.h"

//Forward declarations for private functions
static void osc_request(bridge_t *br, const char *path);
static void run_callbacks(bridge_t *br, param_cache_t *line);

/*****************************************************************************
 *                                                                           *
 *                      OSC Bridge Data Cache                                *
 *                                                                           *
 *****************************************************************************/

static int cache_has(param_cache_t *c, size_t len, uri_t uri)
{
    for(size_t i=0; i<len; ++i)
        if(!strcmp(c[i].path, uri))
            return 1;
    return 0;
}

static void cache_update(bridge_t *br, param_cache_t *ch)
{
    double now  = 1e-3*uv_now(br->loop);
    uri_t uri   = ch->path;
    ch->valid   = 0;
    ch->type    = 0;
    ch->usable  = 1;
    ch->pending = 1;
    ch->force_refresh = 0;
    ch->request_time = now;
    ch->requests++;
    memset(&ch->val, 0, sizeof(ch->val));

    if(osc_request_hook) {
        char buffer[128];
        const int len = rtosc_message(buffer, 128, uri, "");
        if(len <= 0)
            fprintf(stderr, "[ERROR] Osc Bridge Could Not Request Update For \"%s\"\n", uri);
    	osc_request_hook(br, buffer);
    } else
        osc_request(br, uri);
}

static void cache_push(bridge_t *br, uri_t uri)
{
    if(!uri)
        return;
    assert(uri);
    br->cache_len += 1;
    br->cache = realloc(br->cache, br->cache_len*sizeof(param_cache_t));
    param_cache_t *ch = br->cache + (br->cache_len - 1);
    memset(ch, 0, sizeof(param_cache_t));
    ch->path    = strdup(uri);
    cache_update(br, ch);
}

static param_cache_t *cache_get(bridge_t *br, uri_t uri)
{
    for(int i=0; i<br->cache_len; ++i)
        if(!strcmp(br->cache[i].path, uri))
	    return br->cache + i;
    cache_push(br, uri);
    return cache_get(br, uri);
}

static rtosc_arg_t
clone_value(char type, rtosc_arg_t val)
{
    if(type == 'b') {
        char *data = (char*)val.b.data;
        val.b.data = malloc(val.b.len);
        memcpy(val.b.data, data, val.b.len);
    } else if(type == 's') {
        val.s = strdup(val.s);
    }
    return val;
}

static rtosc_arg_t *
clone_vec_value(char *type, rtosc_arg_t *val)
{
    int n = strlen(type);
    rtosc_arg_t *nargs = calloc(sizeof(rtosc_arg_t), n);
    for(int i=0; i<n; ++i) {
        nargs[i] = clone_value(type[i], val[i]);
    }
    return nargs;
}

static void
declone_value(char type, rtosc_arg_t val)
{
    if(type == 'b')
        free(val.b.data);
    else if(type == 's')
        free(strdup(val.s));
}

static void
declone_vec_value(const char *type, rtosc_arg_t *val)
{
    int n = strlen(type);
    for(int i=0; i<n; ++i)
        declone_value(type[i], val[i]);
    free(val);
    free((void*)type);
}

//returns true when the cache has changed values
static int cache_set(bridge_t *br, uri_t uri, char type, rtosc_arg_t val, int skip_debounce)
{
    param_cache_t *line = cache_get(br, uri);
    assert(line);
    line->pending = false;
    if(!line->valid || line->type != type || memcmp(&line->val, &val, sizeof(val)))
    {
        if(line->type == 'v')
            declone_vec_value(line->vec_type, line->vec_value);
        else
            declone_value(line->type, line->val);
        line->valid = true;
        line->type  = type;
        line->val   = clone_value(type, val);
        line->requests = 0;

        //check if cache line is currently debounced...
        int debounced = false;
        for(int i=0; i<br->debounce_len; ++i)
            if(!strcmp(br->bounce[i].path, line->path))
                debounced = true;

        if(!debounced || skip_debounce)
            run_callbacks(br, line);

        return true;
    }
    return false;
}

static int cache_set_vector(bridge_t *br, uri_t uri, char *types, rtosc_arg_t *args)
{
    param_cache_t *line = cache_get(br, uri);
    assert(line);
    line->pending = false;

    int line_size = line->type == 'v' ? strlen(line->vec_type) : 0;

    //If the line is invalid OR
    //the cache isn't a vector field OR
    //the vector fields differ in type OR
    //the vector fields differ in value
    if(!line->valid || line->type != 'v' || strcmp(line->vec_type, types) ||
            memcmp(line->vec_value, args, sizeof(args[0])*strlen(line->vec_type)))
    {
        if(line->type == 'v')
            declone_vec_value(line->vec_type, line->vec_value);
        else
            declone_value(line->type, line->val);

        line->valid     = true;
        line->type      = 'v';
        line->vec_type  = strdup(types);
        line->vec_value = clone_vec_value(types, args);
        line->requests = 0;

        //check if cache line is currently debounced...
        int debounced = false;
        for(int i=0; i<br->debounce_len; ++i) {
            if(!strcmp(br->bounce[i].path, line->path))
                debounced = true;
        }

        if(!debounced)
            run_callbacks(br, line);

        return true;
    }
    return false;
}

/*****************************************************************************
 *                                                                           *
 *                            Network Code                                   *
 *                                                                           *
 *****************************************************************************/

//Testing Hooks
int  (*osc_socket_hook)(void) = NULL;
int  (*osc_request_hook)(bridge_t *, const char *) = NULL;

static void alloc_buffer(uv_handle_t *handle, size_t suggested_size,
        uv_buf_t *buf) {
    (void) handle;
    *buf = uv_buf_init((char*) malloc(suggested_size), suggested_size);
}

#if 0
static void hexdump(const char *data, const char *mask, size_t len)
{
    const char *bold_gray = "\x1b[30;1m";
    const char *reset      = "\x1b[0m";
    int offset = 0;
    while(1)
    {
        //print line
        printf("#%07x: ", offset);

        int char_covered = 0;

        //print hex groups (8)
        for(int i=0; i<8; ++i) {

            //print doublet
            for(int j=0; j<2; ++j) {
                int loffset = offset + 2*i + j;
                if(loffset >= (int)len)
                    goto escape;

                //print hex
                {
                    //start highlight
                    if(mask && mask[loffset]){printf("%s", bold_gray);}

                    //print chars
                    printf("%02x", 0xff&data[loffset]);

                    //end highlight
                    if(mask && mask[loffset]){printf("%s", reset);}
                    char_covered += 2;
                }
            }
            printf(" ");
            char_covered += 1;
        }
escape:

        //print filler if needed
        for(int i=char_covered; i<41; ++i)
            printf(" ");

        //print ascii (16)
        for(int i=0; i<16; ++i) {
            if(isprint(data[offset+i]))
                printf("%c", data[offset+i]);
            else
                printf(".");
        }
        printf("\n");
        offset += 16;
        if(offset >= (int)len)
            return;
    }
}
#endif

void on_read(uv_udp_t *req, ssize_t nread, const uv_buf_t *buf,
             const struct sockaddr *addr, unsigned flags) {
    (void) flags;
    if(nread > 0) {

        const struct sockaddr_in *addr_in = (const struct sockaddr_in *)addr;
        if(addr) {
            char sender[17] = { 0 };
            uv_ip4_name(addr_in, sender, 16);
            //printf("Recv from %s\n", sender);
            //printf("port = %d\n", addr_in->sin_port);
        }
        //printf("buffer[%d] = %s\n", nread, buf->base);
        //hexdump(buf->base, 0, nread);
        bridge_t *br = (bridge_t*)req->data;
        br_recv(br, buf->base);
    }
    free(buf->base);
    //free(req);
}

typedef struct {
    uv_udp_send_t send_req;
    char *data;
} req_t;

static void send_cb(uv_udp_send_t* req, int status)
{
    (void) status;
    req_t *request = (req_t*)req;
    free(request->data);
    free(request);
}

//I know that 300 messages within a single frame results in lost packets, so
//lets identify a reasonable limit of 100 messages per frame

static void do_send(bridge_t *br, char *buffer, unsigned len)
{
    if(br->frame_messages >= BR_RATE_LIMIT) {
        br->rlimit_len++;
        br->rlimit = (char**)realloc(br->rlimit, sizeof(char**)*br->rlimit_len);
        br->rlimit[br->rlimit_len-1] = buffer;
        return;
    }
    br->frame_messages++;
    req_t *request = (req_t*)malloc(sizeof(req_t));
    request->data  = buffer;
    uv_buf_t buf   = uv_buf_init((char*)buffer, len);

    struct sockaddr_in send_addr;
    uv_ip4_addr(br->address, br->port, &send_addr);
    uv_udp_send(&request->send_req, &br->socket, &buf, 1, (const struct sockaddr *)&send_addr, send_cb);
    uv_run(br->loop, UV_RUN_NOWAIT);
}

void osc_request(bridge_t *br, const char *path)
{
    char *buffer = (char*)malloc(4096);
    size_t len   = rtosc_message(buffer, 4096, path, "");
    do_send(br, buffer, len);
    //printf("osc request done<%s>?\n", path);
}

void osc_send(bridge_t *br, const char *message)
{
    size_t   len   = rtosc_message_length(message, -1);
    char     *copy = (char*)malloc(len);
    memcpy(copy, message, len);
    do_send(br, copy, len);
    //printf("osc sent...<%s>?\n", message);
}

/*****************************************************************************
 *                                                                           *
 *                         Bridge Methods                                    *
 *                                                                           *
 *****************************************************************************/

bridge_t *br_create(uri_t uri)
{
    bridge_t *br = (bridge_t*)calloc(1,sizeof(bridge_t));

    br->loop = (uv_loop_t*)calloc(1, sizeof(uv_loop_t));
    uv_loop_init(br->loop);

    uv_udp_init(br->loop, &br->socket);
    int no_collide = rand()%1000;
    for(int offset=0; offset < 1000; ++offset) {
        struct sockaddr_in recv_addr;
        recv_addr.sin_family = AF_INET;
        recv_addr.sin_port = htons(1338+(offset+no_collide)%1000);
        recv_addr.sin_addr.s_addr = INADDR_ANY;
        if(!uv_udp_bind(&br->socket, (const struct sockaddr *)&recv_addr, 0))
            break;
    }
    br->socket.data = br;

    uv_udp_recv_start(&br->socket, alloc_buffer, on_read);

    //parse the url to read
    if(strstr(uri, "osc.udp://") != uri) {
        fprintf(stderr, "[ERROR] Unknown protocol in '%s'\n", uri);
        fprintf(stderr, "[ERROR] Try something like osc.udp://localhost:1234\n");
        exit(1);
    }
    uri = uri+10;
    char *tmp = br->address = strdup(uri);
    while(*tmp && *tmp != ':') ++tmp;
    if(*tmp == ':')
        *tmp++ = 0;

    br->port = atoi(tmp);

    return br;
}

static void
declone_value(char type, rtosc_arg_t val);
static void
declone_vec_value(const char *type, rtosc_arg_t *val);

void br_destroy(bridge_t *br)
{
    int close;
    close = uv_udp_recv_stop(&br->socket);
    if(close)
        fprintf(stderr, "[Warning] UV UDP cannot be stopped [%d] (UV_EBUSY=%d)\n", close, UV_EBUSY);
    else
        fprintf(stderr, "[INFO] UV UDP Stopped\n");
    uv_close((uv_handle_t*)&br->socket, NULL);

    //Flush Events
    int i=100;
    while(uv_run(br->loop, UV_RUN_NOWAIT) > 1)
        if(i-- < 0)
            break;

    close = uv_loop_close(br->loop);
    if(close)
        fprintf(stderr, "[Warning] UV Loop Cannot be closed [%d] (UV_EBUSY=%d)\n", close, UV_EBUSY);
    else
        fprintf(stderr, "[INFO] UV Loop Stopped\n");
    free(br->loop);

    for(int i=0; i<br->cache_len; ++i) {
        free((void*)br->cache[i].path);
        if(br->cache[i].type == 'v') {
            declone_vec_value(br->cache[i].vec_type, br->cache[i].vec_value);
            //free((void*)br->cache[i].vec_type);
            //free((void*)br->cache[i].vec_value);
        } else
            declone_value(br->cache[i].type, br->cache[i].val);
    }
    free(br->cache);
    free(br->bounce);
    for(int i=0; i<br->callback_len; ++i) {
        free((void*)br->callback[i].data);
        free((void*)br->callback[i].path);
    }
    free(br->callback);
    free(br->address);
    free(br);
}

void parse_schema(const char *json, schema_t *sch);
schema_t br_get_schema(bridge_t *br, uri_t uri)
{
    (void) uri;
    schema_t sch;

    //printf("[debug] loading json file\n");
    FILE *f = fopen("schema/test.json", "r");
    if(!f && br->search_path) {
        char tmp[256];
        snprintf(tmp, sizeof(tmp), "%s%s", br->search_path, "schema/test.json");
        f = fopen(tmp, "r");
    }
    if(!f)
        f = fopen("src/osc-bridge/schema/test.json", "r");
    if(!f) {
        printf("[ERROR:Zyn] schema/test.json file is missing.\n");
        printf("[ERROR:Zyn] Please check your installation for problems\n");
        exit(1);
    }
    assert(f && "opening json file");
    fseek(f, 0, SEEK_END);
    size_t len = ftell(f);
    rewind(f);
    char *json = (char*)calloc(1, len+1);
    fread(json, 1, len, f);
    fclose(f);

    printf("[debug] parsing json file\n");
    parse_schema(json, &sch);
    printf("[debug] json parsed succesfully\n");
    sch.json = json;


	return sch;
}

/*****************************************************************************
 *                                                                           *
 *                   Bridge Allocation/Destruction                           *
 *                                                                           *
 *****************************************************************************/

static void debounce_push(bridge_t *br, param_cache_t *line, double obs)
{
    br->debounce_len += 1;
    br->bounce        = (debounce_t*)realloc(br->bounce, br->debounce_len*sizeof(debounce_t));
    debounce_t *bo = br->bounce + (br->debounce_len - 1);
    bo->path = line->path;
    bo->last_set = obs;
}

static void debounce_update(bridge_t *br, param_cache_t *line)
{
    uv_update_time(br->loop);
    uint64_t now = uv_now(br->loop);
    double obs   = 1e-3*now;
    for(int i=0; i<br->debounce_len; ++i) {
        if(!strcmp(line->path, br->bounce[i].path)) {
            br->bounce[i].last_set = obs;
            return;
        }
    }
    debounce_push(br, line, obs);
}

static void debounce_pop(bridge_t *br, int idx)
{
    assert(idx < br->debounce_len);
    for(int i=idx; i<br->debounce_len-1; ++i)
        br->bounce[i] = br->bounce[i+1];
    br->debounce_len -= 1;
}


static void callback_push(bridge_t *br, uri_t uri, bridge_cb_t cb, void *data)
{
    br->callback_len += 1;
    br->callback = (bridge_callback_t*)realloc(br->callback, br->callback_len*sizeof(bridge_callback_t));
    bridge_callback_t *ch = br->callback + (br->callback_len - 1);
    ch->path    = strdup(uri);
    ch->cb      = cb;
    ch->data    = data;
}

static void callback_pop(bridge_t *br, uri_t uri, bridge_cb_t cb, void *data)
{
    int len = br->callback_len;

    int idx = 0;
    while(idx < len) {
        bridge_callback_t item = br->callback[idx];
        if(!strcmp(item.path, uri) && item.cb == cb && item.data == data) {
            //We should remove this element

            //Deallocate resources
            free((void*)item.path);

            //Move all other items
            for(int i=idx; i<len-1; ++i)
                br->callback[i] = br->callback[i+1];

            //Shrink list
            len--;
        } else {
            //move on to the next element of the list
            idx++;
        }
    }

    br->callback_len = len;
}


static int valid_type(char ch)
{
    switch(ch)
    {
        case 'i'://official types
        case 's':
        case 'b':
        case 'f':

        case 'h'://unofficial
        case 't':
        case 'd':
        case 'S':
        case 'r':
        case 'm':
        case 'c':
        case 'T':
        case 'F':
        case 'N':
        case 'I':
            return 1;
        default:
            return 0;
    }
}

static void
run_callbacks(bridge_t *br, param_cache_t *line)
{
    char buffer[1024*16];
    int len = 0;
    if(line->type != 'v') {
        char args[2] = {line->type, 0};
        assert(valid_type(line->type));
        len = rtosc_amessage(buffer, sizeof(buffer), line->path, args, &line->val);
    } else {
        len = rtosc_amessage(buffer, sizeof(buffer), line->path, line->vec_type,
                line->vec_value);
    }

    if(len == 0) {
        //TODO USE DYNAMIC ALLOCATION...
        printf("[ERROR] Message Too long for cache line <%s>\n", line->path);
        if(line->type != 'v') {
            char args[2] = {line->type, 0};
            assert(valid_type(line->type));
            len = rtosc_amessage(0, 0, line->path, args, &line->val);
        } else {
            len = rtosc_amessage(0, 0, line->path, line->vec_type,
                    line->vec_value);
        }
        printf("[ERROR] Needs %d bytes of space...\n", len);
    }


    //run callbacks
    if(len)
        for(int i=0; i<br->callback_len; ++i)
            if(!strcmp(br->callback[i].path, line->path))
                br->callback[i].cb(buffer, br->callback[i].data);
}

void br_randomize(bridge_t *br, uri_t uri)
{
    (void) br;
    (void) uri;
    //TODO
}

void br_default(bridge_t *br, schema_t s, uri_t uri)
{
    schema_handle_t handle = sm_get(s, uri);
    if(!sm_valid(handle))
        return;
    if(handle.type == 'i' && handle.default_)
        br_set_value_int(br, uri, atoi(handle.default_));
    else if(handle.type == 'f' && handle.default_)
        br_set_value_float(br, uri, atof(handle.default_));
}

void br_set_array(bridge_t *br, uri_t uri, char *type, rtosc_arg_t*args)
{
    if(cache_set_vector(br, uri, type, args)) {
        char buffer[1024*8];
        int len = rtosc_amessage(buffer, sizeof(buffer), uri, type, args);
        (void) len;
        //hexdump(buffer, 0, len);
        osc_send(br, buffer);
        debounce_update(br, cache_get(br, uri));
    }
}

void br_set_value_bool(bridge_t *br, uri_t uri, int value)
{
    rtosc_arg_t arg = {.i = value};
    char type = value ? 'T' : 'F';
    if(cache_set(br, uri, type, arg, 1)) {
        char buffer[1024];
        char typestr[2] = {type, '\0'};
        rtosc_message(buffer, 1024, uri, typestr, value);
        osc_send(br, buffer);
        debounce_update(br, cache_get(br, uri));
    }
}

void br_set_value_int(bridge_t *br, uri_t uri, int value)
{
    rtosc_arg_t arg = {.i = value};
    if(cache_set(br, uri, 'i', arg, 1)) {
        char buffer[1024];
        rtosc_message(buffer, 1024, uri, "i", value);
        osc_send(br, buffer);
        debounce_update(br, cache_get(br, uri));
    }
}

void br_set_value_float(bridge_t *br, uri_t uri, float value)
{
    rtosc_arg_t arg = {.f = value};
    if(cache_set(br, uri, 'f', arg, 1)) {
        char buffer[1024];
        rtosc_message(buffer, 1024, uri, "f", value);
        osc_send(br, buffer);
        debounce_update(br, cache_get(br, uri));
    }
}

void br_set_value_string(bridge_t *br, uri_t uri, const char *str)
{
    rtosc_arg_t arg = {.s = str};
    if(cache_set(br, uri, 's', arg, 1)) {
        char buffer[1024];
        rtosc_message(buffer, 1024, uri, "s", str);
        osc_send(br, buffer);
        //debounce_update(br, cache_get(br, uri));
    }
}

int br_has_callback(bridge_t *br, uri_t uri)
{
    for(int i=0; i < br->callback_len; ++i)
        if(!strcmp(br->callback[i].path, uri))
            return true;
    return false;
}

void br_add_callback(bridge_t *br, uri_t uri, bridge_cb_t callback, void *data)
{
    assert(br);
    callback_push(br, uri, callback, data);
    if(!cache_has(br->cache, br->cache_len, uri)) {
        cache_push(br, uri);
    } else {
        //instantly respond when possible
        param_cache_t *ch = cache_get(br, uri);
        if(!ch->valid || !ch->usable) {
            cache_update(br, ch);
            return;
        }
        char buffer[1024*16];
        int len = 0;

        if(ch->type != 'v') {
            char typestr[2] = {ch->type,0};
            len = rtosc_amessage(buffer, sizeof(buffer), ch->path,
                    typestr, &ch->val);
        } else {
            len = rtosc_amessage(buffer, sizeof(buffer), ch->path, ch->vec_type,
                    ch->vec_value);
        }
        if(len == 0) {
            //TODO USE DYNAMIC ALLOCATION...
            printf("[ERROR] Message Too long for cache line <%s> @ %d\n", ch->path, __LINE__);
            if(ch->type != 'v') {
                char args[2] = {ch->type, 0};
                assert(valid_type(ch->type));
                len = rtosc_amessage(0, 0, ch->path, args, &ch->val);
            } else {
                len = rtosc_amessage(0, 0, ch->path, ch->vec_type,
                        ch->vec_value);
            }
            printf("[ERROR] Needs %d bytes of space...\n", len);
        }

        callback(buffer, data);
    }
}

void br_add_action_callback(bridge_t *br, uri_t uri, bridge_cb_t callback, void *data)
{
    assert(br);
    callback_push(br, uri, callback, data);
}

void br_del_callback(bridge_t *br, uri_t uri, bridge_cb_t callback, void *data)
{
    callback_pop(br, uri, callback, data);
}

void br_damage(bridge_t *br, uri_t dmg)
{
    //printf("Damage of parameters...\n");
    //printf("path is %s\n", dmg);
    for(int i=0; i<br->cache_len; ++i) {
        if(strstr(br->cache[i].path, dmg)) {
            int current = br_has_callback(br, br->cache[i].path);
            if(current) {
                osc_request(br, br->cache[i].path);
                br->cache[i].pending = true;
            } else
                br->cache[i].usable = false;
            br->cache[i].requests = 0;
        }
    }
}

void br_refresh(bridge_t *br, uri_t uri)
{
    param_cache_t *cline = cache_get(br, uri);

    uv_update_time(br->loop);
    double now = 1e-3*uv_now(br->loop);

    if(cline->request_time < now) {
        cline->request_time = now;
        osc_request(br, uri);
    } else {
        //printf("skipping refresh for %s at dt = %f\n", uri, cline->request_time-now);
    }
}

void br_force_refresh(bridge_t *br, uri_t uri)
{
    param_cache_t *cline = cache_get(br, uri);

    uv_update_time(br->loop);
    double now = 1e-3*uv_now(br->loop);

    if(cline->request_time < now) {
        cline->request_time = now;
        osc_request(br, uri);
        cline->force_refresh = 0;
    } else {
        cline->request_time = now;
        cline->force_refresh = 1;
        //printf("skipping refresh for %s at dt = %f\n", uri, cline->request_time-now);
    }
}

void br_watch(bridge_t *br, const char *uri)
{
    char *buffer = (char*)malloc(4096);
    size_t len   = rtosc_message(buffer, 4096, "/watch/add", "s", uri);
    do_send(br, buffer, len);

}

void br_action(bridge_t *br, const char *uri, const char *argt,
        const rtosc_arg_t *args)
{
    char *buffer = (char*)malloc(4096);
    size_t len   = rtosc_amessage(buffer, 4096, uri, argt, args);
    do_send(br, buffer, len);
}

void br_recv(bridge_t *br, const char *msg)
{
    //char buffer[128];
    //rtosc_message(buffer, 128, "/part0/Pvolume", "i", 74);
    if(!msg)
        return;

    //if(rtosc_narguments(msg) < 3) {
    //    //printf("BR RECEIVE %s:%s\n", msg, rtosc_argument_string(msg));
    //    //printf("MESSAGE IS %d bytes\n", rtosc_message_length(msg, -1));
    //}
    br->last_update = 1e-3*uv_now(br->loop);

    if(!strcmp("/damage", msg) && !strcmp("s", rtosc_argument_string(msg))) {
        const char *dmg = rtosc_argument(msg, 0).s;
        br_damage(br, dmg);
        return;
    }

    const int nargs = rtosc_narguments(msg);
    if(nargs == 1)
        cache_set(br, msg, rtosc_type(msg, 0), rtosc_argument(msg, 0), 0);
    else {
        //Try to handle the vector message cases
        //printf("BRIDGE RECEIVE A VECTOR MESSAGE\n");
        //TODO verify that we've got some sort of uniformity?
        rtosc_arg_itr_t  itr   = rtosc_itr_begin(msg);
        rtosc_arg_t     *args  = (rtosc_arg_t*)calloc(nargs, sizeof(rtosc_arg_t));
        char            *types = strdup(rtosc_argument_string(msg));

        int offset = 0;
        while(!rtosc_itr_end(itr))
            args[offset++] = rtosc_itr_next(&itr).val;

        cache_set_vector(br, msg, types, args);
        free(args);
        free(types);
    }
    //for(int i=0; i<br->callback_len; ++i) {
    //    printf("cb name = %s\n", br->callback[i].path);
    //    bridge_callback_t cb = br->callback[i];
    //    if(!strcmp(cb.path, msg))
    //        cb.cb(msg, cb.data);
    //}
}

int br_pending(bridge_t *br)
{
    int pending = 0;
    for(int i=0; i<br->cache_len; ++i)
        pending += !!(br->cache[i].pending);
    return pending;
}

void br_tick(bridge_t *br)
{
    //Run all network events
    for(int i=0; i<200; ++i)
        uv_run(br->loop, UV_RUN_NOWAIT);

    if(br->frame_messages >= BR_RATE_LIMIT) {
        //printf("[INFO] Hit rate limit\n");
    }

    br->frame_messages = 0;
    if(br->rlimit) {
        //printf("[INFO] Reading through rate limited fields\n");
        int messages_sent = 0;
        for(int i=0; i<br->rlimit_len && i<BR_RATE_LIMIT; ++i) {
            char *msg = br->rlimit[i];
            //printf("[DEBUG] message = \"%s\"\n", msg);
            if(br->frame_messages >= BR_RATE_LIMIT)
                break;
            do_send(br, msg, rtosc_message_length(msg, -1));
            messages_sent++;
        }
        if(messages_sent == br->rlimit_len) {
            //printf("[INFO] Clearing rate limit queue\n");
            br->rlimit_len = 0;
            free(br->rlimit);
            br->rlimit = 0;
        } else {
            char **base = br->rlimit;
            int N = messages_sent;
            int M = br->rlimit_len;
            //printf("[INFO] Shrinking rate limit queue %d=>%d\n", M, M-N);
            memmove(base, base+N, sizeof(void*)*(M-N));
            br->rlimit_len = M-N;
        }
        //wait 10ms
        //usleep(10000);
    }
    uv_update_time(br->loop);
    double now  = 1e-3*uv_now(br->loop);

    if(!br->rlimit) {
        for(int i=0; i<br->cache_len; ++i) {
            char *path   = br->cache[i].path;
            int   pend   = br->cache[i].pending;
            int   valid  = br->cache[i].valid;
            int   usable = br->cache[i].usable;
            int   fref   = br->cache[i].force_refresh;
            double uptim = br->cache[i].request_time;
            int   rq     = br->cache[i].requests;
            (void) path;
            if(usable && (pend || !valid)) {
                //printf("cache status = <%s, %d, %d, %f, %d>\n", path, pend, valid, uptim, rq);
                if(uptim < now - 300e-3) {
                    if(rq < 10)
                        cache_update(br, &br->cache[i]);
                    //else if(br->cache[i].requests++ == 10)
                    //    printf("[ERROR] Invalid parameter cannot be accessed at <%s>\n", path);
                }
            } else if(usable && fref)
                if(uptim < now - 50e-3)
                    cache_update(br, &br->cache[i]);

        }
    }

    //Attempt to disable debouncing
    if(br->debounce_len == 0)
        return;
    double delta  = 200e-3;
    double thresh = now - delta;
    for(int i=br->debounce_len-1; i >= 0; --i) {
        if(br->bounce[i].last_set < thresh) {
            param_cache_t *cline = cache_get(br, br->bounce[i].path);
            if(cline->valid)
                run_callbacks(br, cline);
            debounce_pop(br, i);
        }
    }


}

int br_last_update(bridge_t *br)
{
    return 1e-3*uv_now(br->loop)-br->last_update;
}

//Statistics
void print_stats(bridge_t *br, schema_t sch)
{
    printf("Bridge Statistics:\n");
    printf("    Total cache lines:          %d\n", br->cache_len);
    printf("    Total callbacks:            %d\n", br->callback_len);
    printf("Schema Statistics:\n");
    printf("    Known Parameters Patterns:  %d\n", sch.elements);
}
