#include "mruby.h"
#include <stdlib.h>

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
    printf("[INFO] (Hot?)Loading QML...\n");
    return mrb_funcall(mrb, mrb_nil_value(), "doFastLoad", 0);
}

zest_t *zest_open(char *address)
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
    
    //Run application runner setup
    //Create nanovg + frame buffers
    mrb_funcall(z->mrb, z->runner, "init_gl",     0);
    //mrb_print_error(z->mrb);
    //Create window
    mrb_funcall(z->mrb, z->runner, "init_window", 1, loader);

    return z;
}

void zest_setup(zest_t *z)
{
}

void zest_close(zest_t *z)
{
    //close mruby
    printf("[INFO] Closing MRuby Application...\n");
    mrb_close(z->mrb);
    free(z);
}

void zest_motion(zest_t *z, int x, int y)
{
    mrb_funcall(z->mrb, z->runner, "cursor", 2,
            mrb_fixnum_value(x), mrb_fixnum_value(y));
}

void zest_mouse(zest_t *z, int button, int action, int x, int y)
{
    if(button) {
        //mrb_value obj = mrb_obj_value(v[1]);
        mrb_funcall(z->mrb, z->runner, "mouse", 4,
                mrb_fixnum_value(button),
                mrb_fixnum_value(action),
                mrb_fixnum_value(x),
                mrb_fixnum_value(y));
    }
    //mrb_int x = x_;
    //mrb_int y = y_;
    //mrb_funcall(z->mrb, z->runner, "resize", 2,
    //        x, y);
}

void zest_scroll(zest_t *z, int x, int y, int dx, int dy)
{
    mrb_funcall(z->mrb, z->runner, "scroll", 4,
            mrb_fixnum_value(x),
            mrb_fixnum_value(y),
            mrb_fixnum_value(dx),
            mrb_fixnum_value(dy));
}

void zest_key(zest_t *z, int key, int action)
{
}

void zest_draw(zest_t *z)
{
    mrb_funcall(z->mrb, z->runner, "draw", 0);
}

void zest_resize(zest_t *z, int x_, int y_)
{
    mrb_int x = x_;
    mrb_int y = y_;
    mrb_funcall(z->mrb, z->runner, "resize", 2,
            x, y);
}

int zest_tick(zest_t *z)
{
    //printf("zest_tick(%p, %p)\n", z->mrb, z->runner);
    //Check code hotload
    //mrb_funcall(z->mrb, z->runner, "tick_hotload",   0);
    //Check osc events
    mrb_funcall(z->mrb, z->runner, "tick_remote",    0);
    //Check animation frames
    mrb_funcall(z->mrb, z->runner, "tick_animation", 0);
    //Apply all events for the frame
    mrb_funcall(z->mrb, z->runner, "tick_events",    0);

    //Apply redraw status
    mrb_value v = mrb_funcall(z->mrb, z->runner, "check_redraw",   0);
    return !mrb_obj_equal(z->mrb, mrb_nil_value(), v);

}
