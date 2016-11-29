#include "mruby.h"
#include <stdlib.h>
#include <string.h>
#include "../../../deps/pugl/pugl/common.h"
#include <locale.h>
#ifndef WIN32
#define __USE_GNU
#include <dlfcn.h>

const char *zest_search_path;
static void
check_error(mrb_state *mrb);

char *get_search_path(void) {
    Dl_info dl_info;
    dladdr((void*)check_error, &dl_info);
    return strdup(dl_info.dli_fname);
}
#define EXPORT
#else
#define EXPORT __declspec(dllexport)
#endif

static void
check_error(mrb_state *mrb)
{
    if(mrb->exc) {
        mrb_print_error(mrb);
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
    if(zest_search_path)
        return mrb_funcall(mrb, mrb_nil_value(), "doFastLoad", 1, mrb_str_new_cstr(mrb, zest_search_path));
    else
        return mrb_funcall(mrb, mrb_nil_value(), "doFastLoad", 0);
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

    //Create mruby interpreter
    printf("[INFO:Zyn] Creating MRuby Interpreter...\n");
    z->mrb = mrb_open();

    //Create Callback Object
    struct RClass *hotload = mrb_define_class(z->mrb, "HotLoad", z->mrb->object_class);
    mrb_define_method(z->mrb, hotload, "initialize", dummy_initialize, MRB_ARGS_NONE());
    mrb_define_method(z->mrb, hotload, "call", load_qml_obj, MRB_ARGS_NONE());
    mrb_value      loader  = mrb_obj_new(z->mrb, hotload, 0, NULL);

    //Create application runner
    struct RClass *runcls  = mrb_class_get(z->mrb, "ZRunner");
    mrb_value      runarg  = mrb_str_new_cstr(z->mrb, address);
    z->runner              = mrb_obj_new(z->mrb, runcls, 1, &runarg);

    //Configure application runner
    mrb_funcall(z->mrb, z->runner, "hotload=", 1, dev_mode ? mrb_true_value() : mrb_false_value());
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

EXPORT void
zest_setup(zest_t *z)
{
}

EXPORT void
zest_close(zest_t *z)
{
    //close mruby
    printf("[INFO] Closing MRuby Application...\n");
    mrb_close(z->mrb);
    free(z);
}

EXPORT void
zest_motion(zest_t *z, int x, int y)
{
    setlocale(LC_NUMERIC, "C");
    mrb_funcall(z->mrb, z->runner, "cursor", 2,
            mrb_fixnum_value(x), mrb_fixnum_value(y));
    check_error(z->mrb);
}

EXPORT void
zest_mouse(zest_t *z, int button, int action, int x, int y)
{
    setlocale(LC_NUMERIC, "C");
    if(button) {
        //mrb_value obj = mrb_obj_value(v[1]);
        mrb_funcall(z->mrb, z->runner, "mouse", 4,
                mrb_fixnum_value(button),
                mrb_fixnum_value(action),
                mrb_fixnum_value(x),
                mrb_fixnum_value(y));
        check_error(z->mrb);
    }
    //mrb_int x = x_;
    //mrb_int y = y_;
    //mrb_funcall(z->mrb, z->runner, "resize", 2,
    //        x, y);
}

EXPORT void
zest_scroll(zest_t *z, int x, int y, int dx, int dy)
{
    setlocale(LC_NUMERIC, "C");
    mrb_funcall(z->mrb, z->runner, "scroll", 4,
            mrb_fixnum_value(x),
            mrb_fixnum_value(y),
            mrb_fixnum_value(dx),
            mrb_fixnum_value(dy));
    check_error(z->mrb);
}

EXPORT void 
zest_key(zest_t *z, const char *key, int press)
{
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
	//fprintf(stderr, "Special key %d %s ", key, press ? "down" : "up");
    const char *pres_rel = press ? "press" : "release";
    const char *type     = NULL;
#define k(x,y) case PUGL_KEY_##x: type = #y;break
    switch(key) {
        k(F1,       f1);
        k(LEFT,     left);
        k(RIGHT,    right);
        k(UP,       up);
        k(DOWN,     down);
        k(CTRL,     ctrl);
        k(SHIFT,    shift);
    }
#undef k

	//PUGL_KEY_PAGE_UP,
	//PUGL_KEY_PAGE_DOWN,
	//PUGL_KEY_HOME,
	//PUGL_KEY_END,
	//PUGL_KEY_INSERT,
	//PUGL_KEY_SHIFT,
	//PUGL_KEY_CTRL,
	//PUGL_KEY_ALT,
	//PUGL_KEY_SUPER

    if(type) {
        mrb_funcall(z->mrb, z->runner, "key_mod", 2,
                mrb_str_new_cstr(z->mrb, pres_rel),
                mrb_str_new_cstr(z->mrb, type));
    } else {
        printf("[INFO] Unknown special key(%d)...\n", key);
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

    //Apply redraw status
    mrb_value v = mrb_funcall(z->mrb, z->runner, "check_redraw",   0);
    check_error(z->mrb);
    return !mrb_obj_equal(z->mrb, mrb_nil_value(), v);

}
