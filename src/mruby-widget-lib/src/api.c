#include "mruby.h"
#include <stdlib.h>
#include <string.h>
#include "../../../deps/pugl/pugl/common.h"
#ifndef WIN32
#define __USE_GNU
#include <dlfcn.h>

const char *path;

__attribute__((constructor))
void on_zest_load(void) {
    Dl_info dl_info;
    dladdr((void*)on_zest_load, &dl_info);
    if(!path)
        path = strdup(dl_info.dli_fname);
    printf("[INFO] Zest Library Located at <%s>\n", path);
}
#define EXPORT
#else

#endif
#define EXPORT __declspec(dllexport)

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
    return mrb_funcall(mrb, mrb_nil_value(), "doFastLoad", 0);
}

EXPORT zest_t *
zest_open(char *address)
{
    //Find QML Root
    const char *roots[] = {
        "/home/mark/code/mruby-zest-build/package/qml/MainWindow.qml"
        "/usr/local/share/zyn-fusion/qml/MainWindow.qml",
        "./qml/MainWindow.qml"};

    zest_t *z = calloc(1, sizeof(zest_t));

    //Detect if the current mode is the dev mode
    const char *dev_check = "src/mruby-zest/example/MainWindow.qml";

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
    mrb_funcall(z->mrb, z->runner, "hotload=", 1, mrb_false_value());
    check_error(z->mrb);

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
    mrb_funcall(z->mrb, z->runner, "cursor", 2,
            mrb_fixnum_value(x), mrb_fixnum_value(y));
    check_error(z->mrb);
}

EXPORT void
zest_mouse(zest_t *z, int button, int action, int x, int y)
{
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
	//fprintf(stderr, "Special key %d %s ", key, press ? "down" : "up");
    const char *pres_rel = press ? "press" : "release";
    const char *type     = NULL;
    if(key == PUGL_KEY_CTRL)
        type = "ctrl";
    else if(key == PUGL_KEY_SHIFT)
        type = "shift";

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
    mrb_funcall(z->mrb, z->runner, "draw", 0);
    check_error(z->mrb);
}

EXPORT void 
zest_resize(zest_t *z, int x_, int y_)
{
    mrb_int x = x_;
    mrb_int y = y_;
    mrb_funcall(z->mrb, z->runner, "resize", 2,
            x, y);
    check_error(z->mrb);
}

EXPORT int 
zest_tick(zest_t *z)
{
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
