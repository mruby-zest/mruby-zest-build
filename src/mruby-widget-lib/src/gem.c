#include <mruby.h>
#include <mruby/array.h>
#include <mruby/string.h>
#include <GL/gl.h>

static mrb_value
mrb_gl_viewport(mrb_state *mrb, mrb_value self)
{
    mrb_float x, y, w, h;
    mrb_get_args(mrb, "ffff", &x, &y, &w, &h);
    glViewport(x, y, w, h);
    return self;
}
static mrb_value
mrb_gl_clear_color(mrb_state *mrb, mrb_value self)
{
    mrb_float r, b, g, a;
    mrb_get_args(mrb, "ffff", &r, &b, &g, &a);
    glClearColor(r, b, g, a);
    return self;
}
static mrb_value
mrb_gl_clear(mrb_state *mrb, mrb_value self)
{
    mrb_int clear_mode;
    mrb_get_args(mrb, "i", &clear_mode);
    glClear(clear_mode);
    return self;
}

void
mrb_mruby_widget_lib_gem_init(mrb_state* mrb) {
    struct RClass *class = mrb_define_module(mrb, "GL");
    mrb_define_class_method(mrb, class, "gl_viewport",    mrb_gl_viewport,    MRB_ARGS_REQ(4));
    mrb_define_class_method(mrb, class, "gl_clear_color", mrb_gl_clear_color, MRB_ARGS_REQ(4));
    mrb_define_class_method(mrb, class, "gl_clear",       mrb_gl_clear,       MRB_ARGS_REQ(1));
}

void
mrb_mruby_widget_lib_gem_final(mrb_state* mrb) {
    /* finalizer */
}
