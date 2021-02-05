#include "mruby.h"
#include "mruby/string.h"
#include <stdlib.h>
#include <string.h>
#include "../../../deps/pugl/pugl/pugl.h"
#include <locale.h>
#ifndef WIN32
#define __USE_GNU
#include <dlfcn.h>

const char *zest_search_path = 0;
static void
check_error(mrb_state *mrb);

char *get_search_path(void) {
    Dl_info dl_info;
    dladdr((void*)check_error, &dl_info);
    return strdup(dl_info.dli_fname);
}
#define EXPORT __attribute__ ((visibility ("default")))
#else
#include <windows.h>
const char *zest_search_path=0;
static void
check_error(mrb_state *mrb);

char *get_search_path(void) {
    char buffer[1024];
    GetModuleFileName(GetModuleHandle("libzest.dll"), buffer, sizeof(buffer));
    //printf("get_search_path() => <%s>\n", buffer);
    return strdup(buffer);
}

#define EXPORT __declspec(dllexport)
#endif

#ifndef WIN32
#define MessageBox(a,b,c,d)
#endif

extern char superhack[];

static void
check_error(mrb_state *mrb)
{
    if(mrb->exc) {
        mrb_print_error(mrb);
        //MessageBox(0, "[FATAL ERROR] Mruby Is Unable To Continue\n", "asdf", 0);
        MessageBox(0, superhack, "[FATAL ERROR] mruby-zest (likely zyn-fusion) cannot continue", 0);
        fprintf(stderr, "[FATAL ERROR] Mruby Is Unable To Continue\n");
        exit(1);
    }
}

typedef struct {
    mrb_state *mrb;
    mrb_value  runner;
} zest_t;

mrb_value
dummy_initialize(mrb_state *mrb, mrb_value self)
{
    return self;
}

mrb_value
load_qml_obj(mrb_state *mrb, mrb_value self)
{
    //printf("[INFO] (Hot?)Loading QML...\n");
#ifdef UI_HOTLOAD
    bool workaround=false;
#else
    bool workaround=true;
#endif
    if(zest_search_path)
      return mrb_funcall(mrb, mrb_nil_value(), "doFastLoad",
                         2, mrb_str_new_cstr(mrb, zest_search_path),
                         mrb_bool_value(workaround));
    else
      return mrb_funcall(mrb, mrb_nil_value(), "doFastLoad",
                         2, mrb_nil_value(), mrb_bool_value(workaround));
}

EXPORT zest_t *
zest_open(char *address)
{
    setlocale(LC_NUMERIC, "C");
    //Find QML Root
    const char *roots[] = {
        "./src/mruby-zest/example/MainWindow.qml",
        "./qml/MainWindow.qml"};

    zest_t *z = calloc(1, sizeof(zest_t));

    //Detect if the current mode is the dev mode
    const char *dev_check = "src/mruby-zest/example/MainWindow.qml";
    int dev_mode = 0;
    {
        FILE *f = fopen(dev_check, "r");
        if(f) {
            dev_mode = 1;
            printf("[INFO:Zyn] running in dev mode\n");
            fclose(f);
        }
    }

    //Verify that the search path is usable
    char *path = get_search_path();
    if(!dev_mode) {
        if(strstr(path, "libzest"))
            strstr(path, "libzest")[0] = 0;
        char path2[256];
        snprintf(path2, sizeof(path2), "%s%s", path, "./qml/MainWindow.qml");
        FILE *f = fopen(path2, "r");
        if(f) {
            printf("[INFO:Zyn] Found Assets at %s\n", path);
            zest_search_path = path;
            fclose(f);
        } else {
            printf("[ERROR:Zyn] QML Not Found At \"%s\"...\n", path2);
            printf("[ERROR:Zyn] Zyn Fusion Assets Missing, Please Check Install...\n");
            exit(1);
        }
    }

#if DEMO_MODE
    printf("[INFO:Zyn] Starting Zyn-Fusion Demo...\n");
#else
    printf("[INFO:Zyn] Starting Zyn-Fusion\n");
    printf("[INFO:Zyn] Thanks for supporting the development of this project\n");
#endif

    //Create mruby interpreter
    printf("[INFO:Zyn] Creating MRuby Interpreter...\n");
    z->mrb = mrb_open();
    check_error(z->mrb);

#ifdef WIN32
    mrb_funcall(z->mrb, mrb_nil_value(), "disable_kernel_io", 0);
    check_error(z->mrb);
#endif

    //Create Callback Object
    struct RClass *hotload = mrb_define_class(z->mrb, "HotLoad", z->mrb->object_class);
    mrb_define_method(z->mrb, hotload, "initialize", dummy_initialize, MRB_ARGS_NONE());
    mrb_define_method(z->mrb, hotload, "call", load_qml_obj, MRB_ARGS_NONE());
    mrb_value      loader  = mrb_obj_new(z->mrb, hotload, 0, NULL);
    check_error(z->mrb);

    //Create application runner
    struct RClass *runcls  = mrb_class_get(z->mrb, "ZRunner");
    mrb_value      runarg  = mrb_str_new_cstr(z->mrb, address);
    z->runner              = mrb_obj_new(z->mrb, runcls, 1, &runarg);
    check_error(z->mrb);

    //Configure application runner
#ifdef UI_HOTLOAD
    mrb_funcall(z->mrb, z->runner, "hotload=", 1, mrb_true_value());
#else
    mrb_funcall(z->mrb, z->runner, "hotload=", 1, mrb_false_value());
#endif
    check_error(z->mrb);

    if(!dev_mode) {
        mrb_funcall(z->mrb, z->runner, "search_path=", 1, mrb_str_new_cstr(z->mrb, zest_search_path));
        check_error(z->mrb);
    }

    //Run application runner setup
    //Create nanovg + frame buffers
    mrb_funcall(z->mrb, z->runner, "init_gl",     0);
    check_error(z->mrb);
    //mrb_print_error(z->mrb);
    //Create window
    mrb_funcall(z->mrb, z->runner, "init_window", 1, loader);
    check_error(z->mrb);

    return z;
}

const char *
get_special_type(int key)
{
    const char *type = "";

#define k(x,y) case PUGL_KEY_##x: type = #y;break
    switch(key) {
        k(F1,       f1);
        k(LEFT,     left);
        k(RIGHT,    right);
        k(UP,       up);
        k(DOWN,     down);
        k(CTRL,     ctrl);
        k(SHIFT,    shift);
        k(PAGE_UP,  page_up);
        k(PAGE_DOWN, page_down);
        k(HOME,     home);
        k(END,      end);
        k(INSERT,   insert);
        k(ALT,      alt);
        k(SUPER,    super);
    }
#undef k

    return type;
}

EXPORT void
zest_setup(zest_t *z)
{
setlocale(LC_NUMERIC, "C");
}

EXPORT void
zest_close(zest_t *z)
{
    //close mruby
    //MessageBox(0, "[INFO] Closing the UI\n", "asdf", 0);
    printf("[INFO] Closing MRuby Application...\n");
    mrb_close(z->mrb);
    //MessageBox(0, "[INFO] Mruby closed\n", "asdf", 0);
    free(z);
    //MessageBox(0, "[INFO] Mruby freed\n", "asdf", 0);
}

EXPORT void
zest_motion(zest_t *z, int x, int y, int mod)
{
    setlocale(LC_NUMERIC, "C");

    mrb_funcall(z->mrb, z->runner, "cursor", 3,
            mrb_fixnum_value(x), mrb_fixnum_value(y), mrb_fixnum_value(mod));

    check_error(z->mrb);
}

EXPORT void
zest_mouse(zest_t *z, int button, int action, int x, int y, int mod)
{
    setlocale(LC_NUMERIC, "C");
    if(button) {

        //mrb_value obj = mrb_obj_value(v[1]);
        mrb_funcall(z->mrb, z->runner, "mouse", 5,
                mrb_fixnum_value(button),
                mrb_fixnum_value(action),
                mrb_fixnum_value(x),
                mrb_fixnum_value(y),
		        mrb_fixnum_value(mod));
        check_error(z->mrb);
    }
    //mrb_int x = x_;
    //mrb_int y = y_;
    //mrb_funcall(z->mrb, z->runner, "resize", 2,
    //        x, y);
}

EXPORT void
zest_scroll(zest_t *z, int x, int y, int dx, int dy, int mod)
{
    setlocale(LC_NUMERIC, "C");
    mrb_funcall(z->mrb, z->runner, "scroll", 5,
            mrb_fixnum_value(x),
            mrb_fixnum_value(y),
            mrb_fixnum_value(dx),
            mrb_fixnum_value(dy),
            mrb_fixnum_value(mod));
    check_error(z->mrb);
}

#ifdef WIN32
static int vst_dup_hack = 0;
#endif

EXPORT void 
zest_key(zest_t *z, const char *key, int press)
{
    int len = 0;
    if(key)
        len = strlen(key);
    //fprintf(stderr, "   zest_key = <%s>(%d) press=%d\n", key, len, press);
    setlocale(LC_NUMERIC, "C");
#ifdef WIN32
    //Normal event
    if(press && len == 1) {
        if(vst_dup_hack == key[0])
            return;
        vst_dup_hack = key[0];
    }
#endif



    const char *pres_rel = press ? "press" : "release";
    mrb_state *mrb = z->mrb;
    mrb_funcall(z->mrb, z->runner, "key", 2,
            mrb_str_new_cstr(mrb, key),
            mrb_str_new_cstr(mrb, pres_rel));
}

EXPORT void 
zest_special(zest_t *z, int key, int press)
{
    setlocale(LC_NUMERIC, "C");
	//fprintf(stderr, "   zest_special() key %d %s ", key, press ? "down" : "up");
    const char *pres_rel = press ? "press" : "release";
    const char *type     = get_special_type(key);

    if(type) {
        mrb_funcall(z->mrb, z->runner, "key_mod", 2,
                mrb_str_new_cstr(z->mrb, pres_rel),
                mrb_str_new_cstr(z->mrb, type));
    } else {
        printf("[INFO] Unknown special key(%x)...\n", key);
    }
}

EXPORT void 
zest_draw(zest_t *z)
{
    setlocale(LC_NUMERIC, "C");
    mrb_funcall(z->mrb, z->runner, "draw", 0);
    check_error(z->mrb);
}

EXPORT void
zest_resize(zest_t *z, int x, int y)
{
    setlocale(LC_NUMERIC, "C");
    mrb_funcall(z->mrb, z->runner, "resize", 2,
            mrb_fixnum_value(x), mrb_fixnum_value(y));
    check_error(z->mrb);
}

EXPORT int
zest_tick(zest_t *z)
{
    setlocale(LC_NUMERIC, "C");
    //printf("zest_tick(%p, %p)\n", z->mrb, z->runner);
#ifdef WIN32
    vst_dup_hack = 0;
#endif
    //Check code hotload
    struct RClass *hotload = mrb_define_class(z->mrb,
            "HotLoad", z->mrb->object_class);
    mrb_value      loader  = mrb_obj_new(z->mrb, hotload, 0, NULL);
    mrb_funcall(z->mrb, z->runner, "tick_hotload",   1, loader);
    check_error(z->mrb);
    //Check osc events
    mrb_funcall(z->mrb, z->runner, "tick_remote",    0);
    check_error(z->mrb);
    //Check animation frames
    mrb_funcall(z->mrb, z->runner, "tick_animation", 0);
    check_error(z->mrb);
    //Apply all events for the frame
    mrb_funcall(z->mrb, z->runner, "tick_events",    0);
    check_error(z->mrb);
    //Run the scheduler
    mrb_funcall(z->mrb, z->runner, "tick_sched",     0);
    check_error(z->mrb);

    //Apply redraw status
    mrb_value v = mrb_funcall(z->mrb, z->runner, "check_redraw",   0);
    check_error(z->mrb);
    return !mrb_obj_equal(z->mrb, mrb_nil_value(), v);

}

EXPORT void
zest_set_option(zest_t *z, const char *key, const char *value)
{
    if(!strcmp(key, "animation_fps"))
        mrb_funcall(z->mrb, z->runner, "animation_fps=", 1,
                mrb_float_value(z->mrb, atof(value)));
}

EXPORT int
zest_exit(zest_t *z)
{
    mrb_value out;
    out = mrb_funcall(z->mrb, z->runner, "exit?", 0),
    check_error(z->mrb);
    if(mrb_obj_equal(z->mrb, out, mrb_nil_value()))
        return 0;
    return 1;
}

EXPORT void
zest_dnd_drop(zest_t *z, const char *data)
{
    mrb_state *mrb = z->mrb;
    mrb_funcall(z->mrb, z->runner, "dnd_drop", 1,
                mrb_str_new_cstr(mrb, data));
    check_error(z->mrb);
}

EXPORT const char*
zest_dnd_pick(zest_t *z)
{
    mrb_state *mrb = z->mrb;
    mrb_value out = mrb_funcall(z->mrb, z->runner, "dnd_pick", 0);
    check_error(z->mrb);
    return mrb_string_value_ptr(mrb, out);
}

EXPORT void
zest_script(zest_t *z, const char *script)
{
    mrb_value out;
    out = mrb_funcall(z->mrb, z->runner, "run_script", 1,
                mrb_str_new_cstr(z->mrb, script));
    check_error(z->mrb);
}

EXPORT const char*
zest_get_remote_url(zest_t *z)
{
    mrb_state *mrb = z->mrb;
    mrb_value out = mrb_funcall(z->mrb, z->runner, "get_remote_url", 0);
    check_error(z->mrb);
    return mrb_string_value_ptr(mrb, out);
}

/**
 * zest_forget_all_state()
 * 
 * Explicity require Zest UI to update itself.
 * Invoke this method in DPF's DISTHRO::UI::stateChanged()
 *   so that Zest UI can respond to preset changes in VST host.
 */
EXPORT void
zest_forget_all_state(zest_t *z)
{
    mrb_state *mrb = z->mrb;
    mrb_funcall(z->mrb, z->runner, "forget_all_state", 0);
    check_error(z->mrb);
}
