#include <mruby.h>
#include <mruby/array.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/string.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <complex.h>
#include <math.h>
#ifdef WIN32
#include <windows.h>
#endif
#include "../../../deps/pugl/pugl/pugl.h"
#include "../../../deps/rtosc/include/rtosc/rtosc.h"
#include "../../../src/osc-bridge/src/bridge.h"
#include "../../../deps/mruby-nanovg/src/gl_core.3.2.h"

#define glCheck() do { \
    GLenum err; \
    while((err = glGetError()) != GL_NO_ERROR)\
        printf("[ERROR] GL error %x on line %d in %s\n", err, __LINE__, __FILE__);\
} while(0)


static mrb_value
mrb_gl_viewport(mrb_state *mrb, mrb_value self)
{
    mrb_float x, y, w, h;
    mrb_get_args(mrb, "ffff", &x, &y, &w, &h);
    glViewport(x, y, w, h);
    glCheck();
    return self;
}
static mrb_value
mrb_gl_clear_color(mrb_state *mrb, mrb_value self)
{
    mrb_float r, b, g, a;
    mrb_get_args(mrb, "ffff", &r, &b, &g, &a);
    glClearColor(r, b, g, a);
    glCheck();
    return self;
}
static mrb_value
mrb_gl_clear(mrb_state *mrb, mrb_value self)
{
    mrb_int clear_mode;
    mrb_get_args(mrb, "i", &clear_mode);
    //glClear(clear_mode);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
    glCheck();
    return self;
}

static mrb_value
mrb_gl_scissor(mrb_state *mrb, mrb_value self)
{
    mrb_float x, y, w, h;
    mrb_get_args(mrb, "ffff", &x, &y, &w, &h);
    glEnable(GL_SCISSOR_TEST);
    glCheck();
    glScissor(x, y, w, h);
    glCheck();
    return self;
}

static mrb_value
mrb_gl_scissor_end(mrb_state *mrb, mrb_value self)
{
    glDisable(GL_SCISSOR_TEST);
    glCheck();
    return self;
}

static mrb_value
mrb_gl_debug(mrb_state *mrb, mrb_value self)
{
    mrb_value val;
    mrb_get_args(mrb, "o", &val);
    return self;

    const char *arg = "ERROR CODE 876-5309";
    if(val.tt == MRB_TT_STRING)
        arg = mrb_string_value_ptr(mrb, val);
    
    fprintf(stderr, "[DEBUG:Zyn-Fusion] \'%s\'\n", arg);
    return self;
}

static mrb_value
mrb_gl_intersect(mrb_state *mrb, mrb_value self)
{
    mrb_int rx, ry, rw, rh, xx, yy, ww, hh;
    mrb_get_args(mrb, "iiiiiiii", &rx, &ry, &rw, &rh, &xx, &yy, &ww, &hh);
    int left_in  = rx       >=xx && rx      <=xx+ww;
    int right_in = rx+rw    >=xx && rx+rw   <=xx+ww;
    int lr_in    = rx       <=xx && rx+rw   >=xx+ww;

    int top_in   = ry       >=yy && ry      <=yy+hh;
    int bot_in   = ry+rh    >=yy && ry+rh   <=yy+hh;
    int tb_in    = ry       <=yy && ry+rh   >=yy+hh;

    if((left_in || right_in || lr_in) && (top_in || bot_in || tb_in))
        return mrb_true_value();
    else
        return mrb_false_value();
}

static mrb_value
mrb_demo_mode(mrb_state *mrb, mrb_value self)
{
#if DEMO_MODE
    return mrb_true_value();
#else
    return mrb_false_value();
#endif
}

/*******************************************************************************
 *                          PUGL Code Here                                     *
 *                                                                             *
 ******************************************************************************/
static void
mrb_pugl_free(mrb_state *mrb, void *ptr)
{
    //printf("================ FFFFFFFFFFFFFFRRRRRRRREEEEEEEEEEEE\n");
}

const struct mrb_data_type mrb_pugl_type = {"PUGL", mrb_pugl_free};


static mrb_value
mrb_pugl_initialize(mrb_state *mrb, mrb_value self)
{
    PuglView *view = 0;

    mrb_data_init(self, view, &mrb_pugl_type);
    mrb_funcall(mrb, self, "w=", 1, mrb_fixnum_value(1181));
    mrb_funcall(mrb, self, "h=", 1, mrb_fixnum_value(659));

    return self;
}

static mrb_value
mrb_pugl_size(mrb_state *mrb, mrb_value self)
{
    mrb_value ary = mrb_ary_new(mrb);
    mrb_sym xid = mrb_intern_str(mrb, mrb_str_new_cstr(mrb, "x"));
    mrb_sym yid = mrb_intern_str(mrb, mrb_str_new_cstr(mrb, "y"));
    mrb_ary_push(mrb, ary, mrb_attr_get(mrb, self, xid));
    mrb_ary_push(mrb, ary, mrb_attr_get(mrb, self, yid));
    return ary;
}

static mrb_value
mrb_pugl_size_set(mrb_state *mrb, mrb_value self)
{
    mrb_value ary;
    mrb_get_args(mrb, "o", &ary);
    mrb_value w = mrb_ary_ref(mrb, ary, 0);
    mrb_value h = mrb_ary_ref(mrb, ary, 1);
    mrb_funcall(mrb, self, "w=", 1, w);
    mrb_funcall(mrb, self, "h=", 1, h);
    return self;
}

static mrb_value
mrb_pugl_impl(mrb_state *mrb, mrb_value self)
{
    PuglView *view = (PuglView*)mrb_data_get_ptr(mrb, self, &mrb_pugl_type);
    mrb_value zrunner;
    mrb_get_args(mrb, "o", &zrunner);
    void **v = mrb_malloc(mrb, 2*sizeof(void*));
    v[0] = mrb;
    v[1] = mrb_cptr(zrunner);
    //puglSetHandle(view, v);
    return mrb_false_value();
}

/*****************************************************************************
 *                         GL Buffer Code                                    *
 *****************************************************************************/

typedef struct {
    int w, h;
	GLuint fbo;
	GLuint rbo;
	GLuint texture;
} GLframebuffer;
    
static int
createFBO(int w, int h, GLframebuffer *fb)
{
    /* texture */
    glCheck();
    glGenTextures(1, &fb->texture);
    glCheck();
    glBindTexture(GL_TEXTURE_2D, fb->texture);
    glCheck();
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glCheck();
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glCheck();
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glCheck();
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glCheck();
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, NULL);
    glCheck();
    glBindTexture(GL_TEXTURE_2D, 0);
    glCheck();

    /* frame buffer object */
    glGenFramebuffersEXT(1, &fb->fbo);
    glCheck();
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb->fbo);
    glCheck();

    /* render buffer object */
    glGenRenderbuffersEXT(1, &fb->rbo);
    glCheck();
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, fb->rbo);
    glCheck();
    glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, 0x88f0, w, h);
    glCheck();

    /* combine all */
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
            GL_TEXTURE_2D, fb->texture, 0);
    glCheck();
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_STENCIL_ATTACHMENT_EXT,
            GL_RENDERBUFFER_EXT, fb->rbo);
    glCheck();

    //printf("framebuffer status = %d\n", glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT));
    //glCheck();
    //assert(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT) == GL_FRAMEBUFFER_COMPLETE_EXT);

    return glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT) == GL_FRAMEBUFFER_COMPLETE_EXT;
}

static void mrb_fbo_free(mrb_state *mrb, void *ptr);
const struct mrb_data_type mrb_fbo_type = {"FBO", mrb_fbo_free};
static void
mrb_fbo_free(mrb_state *mrb, void *ptr)
{

#ifdef WIN32
    //In windows plugin hosts it's impossible to know if the gl context
    // is available
    //This workaround may be needed on other platforms as well
    return;
#endif

    mrb_assert(mrb && false);
    GLframebuffer *fbo = (GLframebuffer *)ptr;
    glDeleteRenderbuffersEXT(1, &fbo->rbo);
    glCheck();
    glDeleteFramebuffersEXT(1, &fbo->fbo);
    glCheck();
    glDeleteTextures(1, &fbo->texture);
    glCheck();
    free(ptr);
}

static mrb_value
mrb_fbo_initialize(mrb_state *mrb, mrb_value self)
{
    mrb_int w, h;
    mrb_get_args(mrb, "ii", &w, &h);
    GLframebuffer *fbo = mrb_malloc(mrb, sizeof(GLframebuffer));
    fbo->w   = w;
    fbo->h   = h;
    fbo->fbo = 0;
    fbo->rbo = 0;
    fbo->texture = 0;
    int ret = createFBO(w, h, fbo);
    if(!ret)
        fprintf(stderr, "[ERROR] Failed to create frame buffer\n");
    mrb_data_init(self, fbo, &mrb_fbo_type);
    return self;
}

static mrb_value
mrb_fbo_deselect(mrb_state *mrb, mrb_value self)
{
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glCheck();
    return self;
}

extern const struct mrb_data_type mrb_nvg_context_type;
typedef void NVGcontext;
int nvglCreateImageFromHandleGL2(NVGcontext* ctx, GLuint textureId, int w, int h, int imageFlags);

static mrb_value
mrb_fbo_image(mrb_state *mrb, mrb_value self)
{
    mrb_value      obj;
    mrb_get_args(mrb, "o", &obj);
    NVGcontext    *ctx = mrb_data_get_ptr(mrb, obj, &mrb_nvg_context_type);
    GLframebuffer *fbo = (GLframebuffer*)mrb_data_get_ptr(mrb, self, &mrb_fbo_type);

    return mrb_fixnum_value(nvglCreateImageFromHandleGL2(ctx, fbo->texture, fbo->w, fbo->h, (1<<2)|(1<<3)));
}

static mrb_value
mrb_fbo_select(mrb_state *mrb, mrb_value self)
{
    GLframebuffer *fbo = (GLframebuffer*)mrb_data_get_ptr(mrb, self, &mrb_fbo_type);
    glCheck();
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo->fbo);
    glCheck();
    return self;
}

static mrb_value
mrb_fbo_destroy(mrb_state *mrb, mrb_value self)
{
    return self;
}


/*****************************************************************************
 *                      Remote Parameter Code                                *
 *****************************************************************************/
typedef struct {
    mrb_state *mrb;
    mrb_value  cb;
    mrb_value  mode;
    bool       log;
    float min;
    float max;
    float logmin;
} remote_cb_data;

typedef struct remote_data_struct remote_data;

typedef struct {
    bridge_t        *br;
    remote_data     *remote;
    const char      *scale;
    uri_t            uri;
    char             type;
    int              cbs;
    float            min;
    float            max;
    float            logmin;
    int              watch;
    remote_cb_data **cb_refs;
} remote_param_data;

typedef struct remote_data_struct {
    bridge_t *br;
    schema_t  sch;
    //Needed for deterministic memory deallocation
    remote_param_data **subs;
    int num_subs;
} remote_data;


void
mrb_remote_metadata_free(mrb_state *mrb, void *ptr)
{
    //printf("================ metadata FFFFFFFFFFFFFFRRRRRRRREEEEEEEEEEEE\n");
}
static void remote_cb(const char *msg, void *data);

static void
free_param(remote_param_data *data)
{
    for(int i=0; i<data->cbs; ++i) {
        remote_cb_data *ref = data->cb_refs[i];
        br_del_callback(data->br, data->uri, remote_cb, ref);
        free((void*)ref);
    }
    data->cbs = 0;
    free(data->cb_refs);
    data->cb_refs = 0;
    free((void*)data->uri);
    data->uri = 0;
    data->remote = 0;
}

static void
remove_from_remote(remote_param_data *data, remote_data *rem)
{
    //find the element
    int ind = -1;
    for(int i=0; i<rem->num_subs; ++i)
        if(rem->subs[i] == data)
            ind = i;
    if(ind == -1)
        return;

    //delete
    for(int i=ind; i<rem->num_subs-1; ++i)
        rem->subs[i] = rem->subs[i+1];
    rem->num_subs--;
    rem->subs = realloc(rem->subs, sizeof(void*)*rem->num_subs);
}

static void
add_to_remote(remote_param_data *data, remote_data *rem)
{
    rem->num_subs++;
    rem->subs = realloc(rem->subs, sizeof(void*)*rem->num_subs);
    rem->subs[rem->num_subs-1] = data;
}


void
mrb_remote_free(mrb_state *mrb, void *ptr)
{
    //fprintf(stderr, "================ remote FFFFFFFFFFFFFFRRRRRRRREEEEEEEEEEEE\n");
    remote_data *data = (remote_data*)ptr;
    br_destroy_schema(data->sch);
    for(int i=0; i<data->num_subs; ++i)
        free_param(data->subs[i]);
    free(data->subs);
    br_destroy(data->br);
    free(ptr);
}



void
mrb_remote_param_free(mrb_state *mrb, void *ptr)
{
    //fprintf(stderr, "================ param FFFFFFFFFFFFFFRRRRRRRREEEEEEEEEEEE\n");
    remote_param_data *data = (remote_param_data*)ptr;
    if(data->remote) {
        remove_from_remote(data, data->remote);
        free_param(data);
    }
    free(ptr);
}

const struct mrb_data_type mrb_remote_type          = {"Remote", mrb_remote_free};
const struct mrb_data_type mrb_remote_metadata_type = {"RemoteMetadata", mrb_remote_metadata_free};
const struct mrb_data_type mrb_remote_param_type    = {"RemoteParam", mrb_remote_param_free};

static mrb_value
mrb_remote_initalize(mrb_state *mrb, mrb_value self)
{
    mrb_value val;
    mrb_get_args(mrb, "o", &val);

    extern char *zest_search_path;
    char *search = zest_search_path;
    const char *arg = "osc.udp://localhost:1234";
    if(val.tt == MRB_TT_STRING)
        arg = mrb_string_value_ptr(mrb, val);
    remote_data *data = mrb_malloc(mrb, sizeof(remote_data));
    data->br  = br_create(arg);
    if(search)
        data->br->search_path = search;
    data->sch = br_get_schema(data->br, "");
    data->num_subs = 0;
    data->subs     = 0;

    mrb_data_init(self, data, &mrb_remote_type);

    mrb_funcall(mrb, self, "init_automate", 0);
    return self;
}

static mrb_value
mrb_remote_tick(mrb_state *mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    br_tick(data->br);
    return self;
}

static mrb_value
mrb_remote_seti(mrb_state *mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    mrb_assert(data && data->br);

    mrb_value path;
    mrb_int value = 0;
    mrb_get_args(mrb, "oi", &path, &value);

    int next = value;
    //printf("[INFO] seti<%s> = %d\n", mrb_string_value_ptr(mrb, path), next);
    br_set_value_int(data->br, mrb_string_value_ptr(mrb, path), next);
    return self;
}

static mrb_value
mrb_remote_setf(mrb_state *mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    mrb_assert(data && data->br);

    mrb_value path;
    mrb_float value = 0;
    mrb_get_args(mrb, "of", &path, &value);

    float next = value;
    //printf("[INFO] seti<%s> = %f\n", mrb_string_value_ptr(mrb, path), next);
    br_set_value_float(data->br, mrb_string_value_ptr(mrb, path), next);
    return self;
}

static mrb_value
mrb_remote_settf(mrb_state *mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    mrb_assert(data && data->br);

    mrb_value path;
    mrb_value value;
    mrb_get_args(mrb, "oo", &path, &value);

    bool val = false;
    if(mrb_obj_equal(mrb, mrb_true_value(), value))
        val = true;
    br_set_value_bool(data->br, mrb_string_value_ptr(mrb, path), val);
    return self;
}

static mrb_value
mrb_remote_sets(mrb_state *mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    mrb_assert(data && data->br);

    mrb_value path;
    mrb_value value;
    mrb_get_args(mrb, "oo", &path, &value);

    br_set_value_string(data->br,
            mrb_string_value_ptr(mrb, path),
            mrb_string_value_ptr(mrb, value));
    return self;
}

static mrb_value
mrb_remote_getaddr(mrb_state* mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    mrb_assert(data);
    mrb_assert(data->br);
    mrb_assert(data->br->address);
    return mrb_str_new_cstr(mrb, data->br->address);
}

static mrb_value
mrb_remote_getport(mrb_state* mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    mrb_assert(data);
    mrb_assert(data->br);
    mrb_assert(data->br->port);
    return mrb_fixnum_value(data->br->port);
}

static mrb_value
mrb_remote_action(mrb_state *mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    mrb_value *argv;
    mrb_int    argc;
    mrb_get_args(mrb, "*", &argv, &argc);
    if(argc < 1)
        return self;

    char *path = strdup(mrb_string_value_ptr(mrb, argv[0]));

    if(argc == 2 && argv[1].tt == MRB_TT_STRING) {
        char *arg = strdup(mrb_string_value_ptr(mrb, argv[1]));
        rtosc_arg_t args[1];
        args[0].s = arg;
        br_action(data->br, path, "s", args);
        free(arg);
    } else if(argc == 2 && argv[1].tt == MRB_TT_FIXNUM) {
        rtosc_arg_t args[1];
        args[0].i = argv[1].value.i;
        br_action(data->br, path, "i", args);
    } else if(argc == 3) {
        //TODO make this less error prone
        if(argv[1].tt == MRB_TT_FIXNUM && argv[2].tt == MRB_TT_STRING) {
            char *arg = strdup(mrb_string_value_ptr(mrb, argv[2]));
            rtosc_arg_t args[2];
            args[0].i = argv[1].value.i;
            args[1].s = arg;
            br_action(data->br, path, "is", args);
            free(arg);
        } else if(argv[1].tt == MRB_TT_STRING && argv[2].tt == MRB_TT_FIXNUM) {
            char *arg = strdup(mrb_string_value_ptr(mrb, argv[1]));
            rtosc_arg_t args[2];
            args[0].s = arg;
            args[1].i = argv[2].value.i;
            br_action(data->br, path, "si", args);
            free(arg);
        } else if(argv[1].tt == MRB_TT_FIXNUM && argv[2].tt == MRB_TT_FIXNUM) {
            rtosc_arg_t args[2];
            args[0].i = argv[1].value.i;
            args[1].i = argv[2].value.i;
            br_action(data->br, path, "ii", args);
        }
    } else if(argc == 4) {
        if(argv[1].tt == MRB_TT_FIXNUM && argv[2].tt == MRB_TT_FIXNUM && argv[3].tt == MRB_TT_FIXNUM) {
            rtosc_arg_t args[3];
            args[0].i = argv[1].value.i;
            args[1].i = argv[2].value.i;
            args[2].i = argv[3].value.i;
            br_action(data->br, path, "iii", args);
        }
    } else {
        br_action(data->br, path, "", NULL);
    }
    free(path);

    return self;
}

static mrb_value
mrb_remote_damage(mrb_state *mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    mrb_value val;
    mrb_get_args(mrb, "o", &val);

    if(val.tt == MRB_TT_STRING)
        br_damage(data->br, mrb_string_value_ptr(mrb, val));
    else
        fprintf(stderr, "[ERROR] Wrong type given to mrb_remote_damage()\n");

    return self;
}

static mrb_value
mrb_remote_default(mrb_state *mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    mrb_value val;
    mrb_get_args(mrb, "o", &val);

    if(val.tt == MRB_TT_STRING)
        br_default(data->br, data->sch, mrb_string_value_ptr(mrb, val));
    else
        fprintf(stderr, "[ERROR] Wrong type given to mrb_remote_default()\n");

    return self;
}

static mrb_value
mrb_remote_last_up_time(mrb_state *mrb, mrb_value self)
{
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, self, &mrb_remote_type);
    int up = br_last_update(data->br);
    return mrb_fixnum_value(up);
}


static mrb_value
mrb_remote_metadata_initalize(mrb_state *mrb, mrb_value self)
{
    mrb_value remote;
    mrb_value path;
    mrb_get_args(mrb, "oS", &remote, &path);

    //Obtain the schema handle
    remote_data *data = (remote_data*)mrb_data_get_ptr(mrb, remote, &mrb_remote_type);
    bridge_t *br = data->br;
    schema_t sch = data->sch;
    schema_handle_t handle = sm_get(sch, mrb_string_value_ptr(mrb, path));
    mrb_value opts = mrb_nil_value();
    if(handle.opts) {
        opts = mrb_ary_new(mrb);
        for(int i=0; i<handle.opts->num_opts; ++i)
        {
            mrb_value opt = mrb_ary_new(mrb);
            mrb_ary_push(mrb, opt, mrb_fixnum_value(handle.opts->ids[i]));
            mrb_ary_push(mrb, opt, mrb_str_new_cstr(mrb, handle.opts->labels[i]));
            mrb_ary_push(mrb, opts, opt);
        }
    }

#define setfield(x, cstr) \
    mrb_funcall(mrb, self, x, 1, \
                      mrb_str_new_cstr(mrb, cstr))
#define setfield2(x, value) \
    mrb_funcall(mrb, self, x, 1, value)
#define setfield3(x, value) \
    mrb_funcall(mrb, self, x, 1, mrb_float_value(mrb, value))
    setfield("name=",       sm_get_name(handle));
    setfield("short_name=", sm_get_short(handle));
    setfield("tooltip=",    sm_get_tooltip(handle));
    setfield("units=",      handle.units);
    setfield("scale=",      handle.scale);
    setfield2("options=",   opts);
    setfield3("min=",       sm_get_min_flt(handle));
    setfield3("max=",       sm_get_max_flt(handle));
    setfield3("logmin=",    sm_get_logmin_flt(handle));
#undef setfield
#undef setfield2
#undef setfield3
    return self;
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
remote_cb_127(const char *msg, remote_cb_data *cb)
{
    //assume the 0..127 integer case for the input
    //assume the 0..1   float   case for the output

    mrb_assert(!strcmp("i",rtosc_argument_string(msg)));
    int arg = rtosc_argument(msg, 0).i;

    mrb_assert(0 <= arg && arg <= 127);

    mrb_float cb_val = (arg-cb->min)/(cb->max-cb->min);

    mrb_funcall(cb->mrb, cb->cb, "call", 1, mrb_float_value(cb->mrb,cb_val));
}

static void
remote_cb_pure_int(const char *msg, remote_cb_data *cb)
{
    mrb_assert(!strcmp("i",rtosc_argument_string(msg)) || !strcmp("c",rtosc_argument_string(msg)));

    int cb_val = rtosc_argument(msg, 0).i;

    mrb_funcall(cb->mrb, cb->cb, "call", 1, mrb_fixnum_value(cb_val));
}

static void
remote_cb_int(const char *msg, remote_cb_data *cb)
{
    mrb_assert(!strcmp("i",rtosc_argument_string(msg)) || !strcmp("c",rtosc_argument_string(msg)));

    mrb_float cb_val = rtosc_argument(msg, 0).i;

    mrb_funcall(cb->mrb, cb->cb, "call", 1, mrb_float_value(cb->mrb,cb_val));
}

static void
remote_cb_tf(const char *msg, remote_cb_data *cb)
{
    if(!strcmp("T", rtosc_argument_string(msg)))
        mrb_funcall(cb->mrb, cb->cb, "call", 1, mrb_true_value());
    else
        mrb_funcall(cb->mrb, cb->cb, "call", 1, mrb_false_value());
}

static void
remote_cb_str(const char *msg, remote_cb_data *cb)
{
    mrb_funcall(cb->mrb, cb->cb, "call", 1,
            mrb_str_new_cstr(cb->mrb, rtosc_argument(msg, 0).s));
}

static void
remote_cb_fvec(const char *msg, remote_cb_data *cb)
{
    mrb_value ary = mrb_ary_new(cb->mrb);
    for(rtosc_arg_itr_t itr = rtosc_itr_begin(msg); !rtosc_itr_end(itr);) {
        rtosc_arg_val_t val = rtosc_itr_next(&itr);
        if(val.type == 'f')
            mrb_ary_push(cb->mrb, ary, mrb_float_value(cb->mrb, val.val.f));
        else if(val.type == 'i')
            mrb_ary_push(cb->mrb, ary, mrb_fixnum_value(val.val.i));
        else if(val.type == 's')
            mrb_ary_push(cb->mrb, ary, mrb_str_new_cstr(cb->mrb, val.val.s));
        else if(val.type == 'T')
            mrb_ary_push(cb->mrb, ary, mrb_true_value());
        else if(val.type == 'F')
            mrb_ary_push(cb->mrb, ary, mrb_false_value());
        else if(val.type == 'b') {
            int    n   = val.val.b.len/4;
            float *dat = (float*)val.val.b.data;
            for(int i=0; i<n; ++i)
                mrb_ary_push(cb->mrb, ary, mrb_float_value(cb->mrb, dat[i]));
        }

    }

    mrb_funcall(cb->mrb, cb->cb, "call", 1, ary);
}

// callback after receiving a value from OSC message
static void
remote_cb(const char *msg, void *data)
{
    if(!msg || *msg != '/') {
        printf("[ERROR] INVALID MESSAGE <%s>\n", msg);
    }
    assert(msg && *msg == '/');
    const char *args = rtosc_argument_string(msg);
    if(args && *args)
        assert(valid_type(*args));
    remote_cb_data *cb = (remote_cb_data*) data;
    int nil = mrb_obj_equal(cb->mrb, mrb_nil_value(), cb->mode);
    mrb_sym norm_sym = mrb_intern_lit(cb->mrb, "normal_int");
    int norm_int = mrb_obj_equal(cb->mrb,
                                 mrb_symbol_value(norm_sym),
                                 cb->mode);
    const char *arg_str = rtosc_argument_string(msg);
    if(!strcmp("i", arg_str) && nil)
        remote_cb_127(msg, cb);
    else if(!strcmp("c", arg_str))
        remote_cb_127(msg, cb);
    else if(!strcmp("i", arg_str) && norm_int)
        remote_cb_pure_int(msg, cb);
    else if(!strcmp("i", arg_str))
        remote_cb_int(msg, cb);
    else if(!strcmp("f", arg_str)) {
        float val = rtosc_argument(msg, 0).f;
        if(cb->log) {
            // clip values around [min,logmin]
            if (val > cb->min && val < cb->logmin) {
                val = (val < .5f * (cb->min + cb->logmin)) ? cb->min : cb->logmin;
            }

            if (val == cb->min) {
                val = 0.f;
            } else {
                // map [min,max] -> [0,1]
                if (cb->logmin > 0){
                    const float b = log(cb->logmin);
                    const float a = log(cb->max)-b;
                    val = (logf(val)-b)/a; // inverse scaling function of exp-function in mrb_remote_param_set_value
                }else { // min <= 0
                    const float a = logf(1.0f+4096.0f);
                    val = logf(1.0f+val*4096.0f/cb->max)/a; // inverse function of exp-function in mrb_remote_param_set_value
                }

                // linear post-mapping:
                // [0,1] -> [0.07,1]
                if(cb->logmin != cb->min)
                    val = 0.93 * val + 0.07;
            }
        } else
            val = (val-cb->min)/(cb->max-cb->min);
        mrb_funcall(cb->mrb, cb->cb, "call", 1, mrb_float_value(cb->mrb, val));
    } else if(!strcmp("T", arg_str))
        remote_cb_tf(msg, cb);
    else if(!strcmp("F", arg_str))
        remote_cb_tf(msg, cb);
    else if(!strcmp("s", arg_str))
        remote_cb_str(msg, cb);
    else
        remote_cb_fvec(msg, cb);
}


static mrb_value
mrb_remote_param_initalize(mrb_state *mrb, mrb_value self)
{
    mrb_value remote;
    mrb_value uri;
    mrb_get_args(mrb, "oS", &remote, &uri);
    remote_param_data *data = mrb_malloc(mrb, sizeof(remote_param_data));
    remote_data *rdata = (remote_data*)mrb_data_get_ptr(mrb, remote, &mrb_remote_type);
    data->br      = rdata->br;
    data->remote  = rdata;
    data->uri     = strdup(mrb_string_value_ptr(mrb, uri));
    data->type    = 'i';
    data->cb_refs = NULL;
    data->cbs     = 0;
    data->min     = 0;
    data->max     = 0;
    data->logmin  = 0;
    data->watch   = 0;
    data->scale   = 0;
    //if(strstr(data->uri, "Pfreq"))
    //    data->type = 'f';
    if(!data->br) {
        fprintf(stderr, "[ERROR] Remote Bridge Is Missing...\n");
        exit(1);
    }

    mrb_funcall(mrb, self, "remote=", 1, remote);
    mrb_data_init(self, data, &mrb_remote_param_type);
    add_to_remote(data, rdata);
    return self;
}

static mrb_value
mrb_remote_param_set_watch(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param = (remote_param_data*)
        mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    param->watch = true;
    return self;
}

static mrb_value
mrb_remote_param_set_callback(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param = (remote_param_data*)
        mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);

    remote_cb_data *data = malloc(sizeof(remote_cb_data));
    data->mrb    = mrb;
    data->mode   = mrb_funcall(mrb, self, "mode", 0);
    data->log    = (param->scale && strstr(param->scale, "log"));
    data->min    = param->min;
    data->max    = param->max;
    data->logmin = param->logmin;
    if(data->min == data->max && data->max == 0)
        data->max = 127.0;
    mrb_get_args(mrb, "o", &data->cb);

    mrb_funcall(mrb, self, "add_cb", 1, data->cb);

    mrb_assert(param->br);
    mrb_assert(param->uri);
    if(!param->watch)
        br_add_callback(param->br, param->uri, remote_cb, data);
    else
        br_add_action_callback(param->br, param->uri, remote_cb, data);
    param->cbs += 1;
    param->cb_refs = realloc(param->cb_refs, param->cbs*sizeof(void*));
    param->cb_refs[param->cbs-1] = data;

    //param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    return self;
}

static mrb_value
mrb_remote_param_set_min(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    mrb_float value = 0;
    mrb_get_args(mrb, "f", &value);
    mrb_assert(param);

    param->min = value;
    return self;
}

static mrb_value
mrb_remote_param_set_max(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    mrb_float value = 0;
    mrb_get_args(mrb, "f", &value);
    mrb_assert(param);

    param->max = value;
    return self;
}

static mrb_value
mrb_remote_param_set_logmin(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    mrb_float value = 0;
    mrb_get_args(mrb, "f", &value);
    mrb_assert(param);

    param->logmin = value;
    return self;
}

static mrb_value
mrb_remote_param_has_logmin(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);
    return mrb_bool_value(param->logmin != param->min);
}

static mrb_value
mrb_remote_param_set_scale(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    mrb_value val;
    mrb_get_args(mrb, "o", &val);

    const char *arg = "";
    if(val.tt == MRB_TT_STRING)
        arg = mrb_string_value_ptr(mrb, val);

    mrb_assert(param);

    if(strstr(arg, "log"))
        param->scale = "log";
    else
        param->scale = "linear";
    return self;
}

// called when UI is setting a value
static mrb_value
mrb_remote_param_set_value(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    mrb_value mode;
    mrb_float value = 0;
    mrb_get_args(mrb, "fo", &value, &mode);
    mrb_assert(param);
    mrb_assert(param->br);
    mrb_assert(param->uri);

    if(param->type == 'i') {
        int next = value;
        bool nil_mode = mrb_obj_equal(mrb, mrb_nil_value(), mode);
        bool p127     = param->min == 0 && (param->max == 127 || param->max == 0);
        if(nil_mode && p127)
            next = (127.0*value);
        else if(nil_mode)
            next = (param->max-param->min)*value + param->min;
        br_set_value_int(param->br, param->uri, next);
    } else if(param->type == 'f') {
        float out = 0;
        if(param->scale && strstr(param->scale, "log")) {
            // map [0,1] => [min,max]

            // if logmin, clip values around [0,0.07]
            if(param->logmin!=param->min && value > 0.f && value < 0.07f)
                value = (value < .035f) ? 0 : 0.07;

            if(param->logmin!=param->min && value == 0) {
                out = param->min;
            } else {
                float x;
                if(param->logmin == param->min) {
                    x = value;
                } else {
                    // linear pre-mapping: [0.07,1] -> [0,1]
                    float a, b; // f(x) = ax + b
                    a = 1.f/0.93f;
                    b = 1-a;
                    x = a*value + b;
                }

                // now, we are in [0,1] (again)
                // map [0,1] => [min,max]
                if (param->logmin > 0) {
                    const float b = log(param->logmin);
                    const float a = log(param->max)-b;
                    out = expf(a*x+b);
                } else { // min <= 0 ( e.g. envelope time param )
                    const float a = logf(1.0+4096.0f);
                    out = (expf(a*x)-1.0f)*param->max/4096.0f;
                }
            }

        } else
            out = (param->max-param->min)*value + param->min;

        br_set_value_float(param->br, param->uri, out);
    }
    
    return self;
}

static mrb_value
mrb_remote_param_set_value_tf(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    mrb_value mode;
    mrb_value value;
    mrb_get_args(mrb, "oo", &value, &mode);
    mrb_assert(param);
    mrb_assert(param->br);
    mrb_assert(param->uri);

    bool val = false;
    if(mrb_obj_equal(mrb, mrb_true_value(), value))
        val = true;
    br_set_value_bool(param->br, param->uri, val);
    return self;
}

static mrb_value
mrb_remote_param_set_value_ar(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    mrb_value mode;
    mrb_value value;
    mrb_get_args(mrb, "oo", &value, &mode);
    mrb_assert(param);
    mrb_assert(param->br);
    mrb_assert(param->uri);

    int len = RARRAY_LEN(value);
    rtosc_arg_t args[len];
    char        types[len+1];
    memset(types, 0, len+1);
    int j=0;
    for(int i=0; i<len; ++i) {
        mrb_value v = mrb_ary_ref(mrb, value, i);
        if(v.tt == MRB_TT_FLOAT) {
            args[j].f = v.value.f;
            types[j]  = 'f';
            j++;
        } else {
            printf("[WARNING] Invalid TT(%d) in mrb_remote_param_set_value_ar\n", v.tt);
        }
    }

    br_set_array(param->br, param->uri, types, args);
    return self;
}

static char *
mrb_copy_str(mrb_state *mrb, mrb_value value)
{
    size_t      l   = mrb_string_value_len(mrb, value);
    const char *s   = mrb_string_value_ptr(mrb, value);
    char       *out = malloc(l+1);

    for(int i=0; i<l; ++i)
        out[i] = s[i];

    out[l] = 0;
    return out;
}

static mrb_value
mrb_remote_param_set_value_str(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    mrb_value mode;
    mrb_value value;
    mrb_get_args(mrb, "oo", &value, &mode);
    mrb_assert(param);
    mrb_assert(param->br);
    mrb_assert(param->uri);

    const char *str = mrb_copy_str(mrb, value);
    br_set_value_string(param->br, param->uri, str);
    free(str);
    return self;
}

static mrb_value
mrb_remote_param_set_type(mrb_state *mrb, mrb_value self)
{
    mrb_value type;
    mrb_get_args(mrb, "o", &type);
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);

    param->type = 'f';
    return self;
}

static mrb_value
mrb_remote_param_display_value(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    bridge_t *br = param->br;
    //try to see if the value is already in the cache
    for(int i=0; i<br->cache_len; ++i) {
        if(!strcmp(br->cache[i].path, param->uri) &&
                br->cache[i].valid) {
            if(br->cache[i].type == 'i')
                return mrb_fixnum_value(br->cache[i].val.i);
            if(br->cache[i].type == 'f')
                return mrb_float_value(mrb, br->cache[i].val.f);
        }
    }

    return mrb_nil_value();
}

static mrb_value
mrb_remote_param_refresh(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    br_refresh(param->br, param->uri);
    return self;
}

static mrb_value
mrb_remote_param_force_refresh(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    br_force_refresh(param->br, param->uri);
    return self;
}

static mrb_value
mrb_remote_param_watch(mrb_state *mrb, mrb_value self)
{
    remote_param_data *param;
    param = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    mrb_assert(param);

    br_watch(param->br, param->uri);
    return self;
}

static mrb_value
mrb_remote_param_clean(mrb_state *mrb, mrb_value self)
{
    remote_param_data *data;
    data = (remote_param_data*) mrb_data_get_ptr(mrb, self, &mrb_remote_param_type);
    for(int i=0; i<data->cbs; ++i) {
        remote_cb_data *ref = data->cb_refs[i];
        br_del_callback(data->br, data->uri, remote_cb, ref);
        free(ref);
    }
    free(data->cb_refs);
    data->cb_refs = 0;
    data->cbs     = 0;

    return self;
}

//Optimized DSP stuff
mrb_value
mrb_opt_magnitude(mrb_state *mrb, mrb_value self)
{
    mrb_value num, dem, freq, output;
    mrb_int stages;
    int args = mrb_get_args(mrb, "AAAi", &num, &dem, &freq, &stages);
    assert(args == 4);

    float b[3] = {0}, a[3] = {0};
    int   order = RARRAY_LEN(num);
    assert(order == 3 || order == 2);

    for(int i=0; i<order; ++i) {
        b[i] = mrb_ary_ref(mrb, num, i).value.f;
        a[i] = mrb_ary_ref(mrb, dem, i).value.f;
    }

    int n = RARRAY_LEN(freq);

    output = mrb_ary_new(mrb);

    for(int i=0; i<n; ++i) {
        const float fq = mrb_ary_ref(mrb, freq, i).value.f;
        float complex nm = 0;
        float complex dm = 1.0;
        for(int j=0; j<order; ++j) {
#ifndef M_PI
# define M_PI		3.14159265358979323846f
#endif
            const float angle  = M_PI * fq * j;
            float complex base = cosf(angle) + I*sinf(angle);
            nm += b[j]*base;
            dm -= a[j]*base;
        }
        const float rs = powf(cabs(nm/dm), stages);
        mrb_ary_push(mrb, output, mrb_float_value(mrb, rs));
    }

    return output;
}

void draw_seq_start(mrb_state *mrb);
// Puting it all together
void
mrb_mruby_widget_lib_gem_init(mrb_state* mrb) {
    struct RClass *module = mrb_define_module(mrb, "GL");
    mrb_define_class_method(mrb, module, "gl_viewport",    mrb_gl_viewport,    MRB_ARGS_REQ(4));
    mrb_define_class_method(mrb, module, "gl_clear_color", mrb_gl_clear_color, MRB_ARGS_REQ(4));
    mrb_define_class_method(mrb, module, "gl_clear",       mrb_gl_clear,       MRB_ARGS_REQ(1));
    mrb_define_class_method(mrb, module, "gl_scissor",     mrb_gl_scissor,     MRB_ARGS_REQ(4));
    mrb_define_class_method(mrb, module, "gl_scissor_end", mrb_gl_scissor_end, MRB_ARGS_REQ(0));
    mrb_define_class_method(mrb, module, "debug", mrb_gl_debug, MRB_ARGS_REQ(1));
    mrb_define_class_method(mrb, module, "intersect", mrb_gl_intersect,
            MRB_ARGS_REQ(8));
    //yeah, this shouldn't be in GL, but it was quick to hack in
    mrb_define_class_method(mrb, module, "demo_mode", mrb_demo_mode, MRB_ARGS_NONE());


    struct RClass *pugl = mrb_define_class_under(mrb, module, "PUGL", mrb->object_class);
    MRB_SET_INSTANCE_TT(pugl, MRB_TT_DATA);

    mrb_define_method(mrb, pugl, "initialize",   mrb_pugl_initialize,   MRB_ARGS_REQ(1));
    mrb_define_method(mrb, pugl, "size",         mrb_pugl_size,         MRB_ARGS_NONE());
    mrb_define_method(mrb, pugl, "size=",        mrb_pugl_size_set,     MRB_ARGS_REQ(1));
    mrb_define_method(mrb, pugl, "impl=",        mrb_pugl_impl,         MRB_ARGS_REQ(1));

    struct RClass *fbo = mrb_define_class_under(mrb, module, "FBO",
            mrb->object_class);
    MRB_SET_INSTANCE_TT(fbo, MRB_TT_DATA);
    mrb_define_method(mrb, fbo, "initialize",   mrb_fbo_initialize,   MRB_ARGS_REQ(2));
    mrb_define_method(mrb, fbo, "select",       mrb_fbo_select,       MRB_ARGS_NONE());
    mrb_define_method(mrb, fbo, "deselect",     mrb_fbo_deselect,     MRB_ARGS_NONE());
    mrb_define_method(mrb, fbo, "image",        mrb_fbo_image,        MRB_ARGS_REQ(1));
    mrb_define_method(mrb, fbo, "destroy",      mrb_fbo_destroy,      MRB_ARGS_NONE());

    //Define the remote API
    struct RClass *osc = mrb_define_module(mrb, "OSC");
    struct RClass *remote = mrb_define_class_under(mrb, osc, "Remote", mrb->object_class);
    MRB_SET_INSTANCE_TT(remote, MRB_TT_DATA);
    mrb_define_method(mrb, remote, "initialize", mrb_remote_initalize, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, remote, "tick",       mrb_remote_tick,      MRB_ARGS_NONE());
    mrb_define_method(mrb, remote, "seti",       mrb_remote_seti,      MRB_ARGS_REQ(2));
    mrb_define_method(mrb, remote, "setf",       mrb_remote_setf,      MRB_ARGS_REQ(2));
    mrb_define_method(mrb, remote, "settf",      mrb_remote_settf,     MRB_ARGS_REQ(2));
    mrb_define_method(mrb, remote, "sets",       mrb_remote_sets,      MRB_ARGS_REQ(2));
    mrb_define_method(mrb, remote, "action",     mrb_remote_action,    MRB_ARGS_ANY());
    mrb_define_method(mrb, remote, "damage",     mrb_remote_damage,    MRB_ARGS_REQ(1));
    mrb_define_method(mrb, remote, "default",     mrb_remote_default,  MRB_ARGS_REQ(1));
    mrb_define_method(mrb, remote, "last_up_time", mrb_remote_last_up_time, MRB_ARGS_NONE());
    mrb_define_method(mrb, remote, "getaddr",    mrb_remote_getaddr,   MRB_ARGS_NONE());
    mrb_define_method(mrb, remote, "getport",    mrb_remote_getport,   MRB_ARGS_NONE());

    struct RClass *metadata = mrb_define_class_under(mrb, osc, "RemoteMetadata", mrb->object_class);
    MRB_SET_INSTANCE_TT(metadata, MRB_TT_DATA);
    mrb_define_method(mrb, metadata, "initialize", mrb_remote_metadata_initalize, MRB_ARGS_REQ(2));

    struct RClass *param = mrb_define_class_under(mrb, osc, "RemoteParam", mrb->object_class);
    MRB_SET_INSTANCE_TT(param, MRB_TT_DATA);
    mrb_define_method(mrb, param, "initialize", mrb_remote_param_initalize, MRB_ARGS_REQ(2));
    mrb_define_method(mrb, param, "set_watch",    mrb_remote_param_set_watch,    MRB_ARGS_NONE());
    mrb_define_method(mrb, param, "set_callback", mrb_remote_param_set_callback, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, param, "set_min",      mrb_remote_param_set_min, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, param, "set_max",      mrb_remote_param_set_max, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, param, "set_logmin",   mrb_remote_param_set_logmin, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, param, "has_logmin",   mrb_remote_param_has_logmin, MRB_ARGS_NONE());
    mrb_define_method(mrb, param, "set_scale",    mrb_remote_param_set_scale, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, param, "set_value",    mrb_remote_param_set_value, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, param, "set_value_tf", mrb_remote_param_set_value_tf, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, param, "set_value_ar", mrb_remote_param_set_value_ar, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, param, "set_value_str",mrb_remote_param_set_value_str, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, param, "type=",        mrb_remote_param_set_type, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, param, "display_value",mrb_remote_param_display_value, MRB_ARGS_NONE());
    mrb_define_method(mrb, param, "force_refresh",mrb_remote_param_force_refresh, MRB_ARGS_NONE());
    mrb_define_method(mrb, param, "refresh",      mrb_remote_param_refresh, MRB_ARGS_NONE());
    mrb_define_method(mrb, param, "watch",        mrb_remote_param_watch, MRB_ARGS_NONE());
    mrb_define_method(mrb, param, "clean",        mrb_remote_param_clean, MRB_ARGS_NONE());

    struct RClass *opt = mrb_define_module(mrb, "Draw");
    mrb_define_class_method(mrb, opt, "opt_magnitude",    mrb_opt_magnitude,    MRB_ARGS_REQ(4));
    draw_seq_start(mrb);
}

void
mrb_mruby_widget_lib_gem_final(mrb_state* mrb) {
    /* finalizer */
}

//Workaround for mruby's read only data sector detection
char __ehdr_start[] = {0};
char __init_array_start[] = {0};
