#include <mruby.h>
#include <mruby/variable.h>
#include <mruby/array.h>
#include <mruby/object.h>
#include <math.h>
//def self.normalize(seq)
//    min = 1
//    max = -1
//    seq.each do |x|
//        min = x if x < min
//        max = x if x > max
//    end
//    mag = [max,-min].max
//    mag = 1.0 if mag == 0.0
//    (0...seq.length).each do |i|
//        seq[i] /= mag
//    end
//    seq
//end
static void
normalize(float *f, int n)
{
    float min = 1;
    float max = -1;
    for(int i=0; i<n; ++i) {
        if(f[i] < min)
            min = f[i];
        if(f[i] > max)
            max = f[i];
    }
    float mag = max > -min ? max : -min;
    if(mag == 0)
        mag = 1.0;
    for(int i=0; i<n; ++i)
        f[i] /= mag;
}

float
get(mrb_state *mrb, mrb_value v, const char *field)
{
    mrb_value asdf = mrb_funcall(mrb, v, field, 0);
    if(asdf.tt == MRB_TT_FIXNUM)
        return asdf.value.i;
    else
        return asdf.value.f;
}

typedef struct zest_bounding_box 
{
    float x;
    float y;
    float w;
    float h;

    float center_y;

    float right;
    float bottom;
} zest_bounding_box;

static void
zest_bounding_box_init(mrb_state *mrb, mrb_value *bb, zest_bounding_box *bound) {
    mrb_value _bb = *bb;

    bound->x = get(mrb, _bb, "x");
    bound->y = get(mrb, _bb, "y");
    bound->w = get(mrb, _bb, "w");
    bound->h = get(mrb, _bb, "h");

    bound->center_y = bound->y + bound->h / 2.0f;

    bound->right = bound->x + bound->w;
    bound->bottom = bound->y + bound->h;
}

static float 
build_oscil_plot_path(mrb_state *mrb, mrb_value *nvg, const float phase, const zest_bounding_box *bound, const float *data, const int data_length)
{
    mrb_value vg = *nvg;

    const int off = phase * (data_length-1);
    int ii = off % data_length;
    const float initial_y = -bound->h/2 * data[ii] + bound->center_y;

    mrb_funcall(mrb, vg, "move_to", 2,
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, initial_y));

    for(int i=1; i<data_length; ++i) {
        ii = (off+i)%data_length;
        
        float ypos = -bound->h/2*data[ii] + bound->center_y;

        if(ypos > bound->bottom) ypos = bound->bottom;
        if(ypos < bound->y) ypos = bound->y;

        mrb_funcall(mrb, vg, "line_to", 2,
                mrb_float_value(mrb, bound->w*ii/data_length + bound->x),
                mrb_float_value(mrb, ypos));
    }

    return initial_y;
}

static void
draw_oscil_plot_stroke(mrb_state *mrb, mrb_value *nvg, const float phase, const zest_bounding_box *bound, const float *data, const int data_length)
{
    mrb_value vg = *nvg;

    struct RClass *theme = mrb_module_get(mrb, "Theme");
    mrb_value linecolor = mrb_mod_cv_get(mrb, theme, mrb_intern_cstr(mrb, "VisualLine"));
    
    mrb_funcall(mrb, vg, "begin_path", 0);

    build_oscil_plot_path(mrb, nvg, phase, bound, data, data_length);

    mrb_funcall(mrb, vg, "stroke_color", 1, linecolor);
    mrb_funcall(mrb, vg, "stroke_width", 1, mrb_float_value(mrb, 2.0));
    mrb_funcall(mrb, vg, "stroke", 0);
    
    mrb_funcall(mrb, vg, "close_path", 0);
}

static void
draw_oscil_plot_unidirectional_highlight(mrb_state *mrb, mrb_value *nvg, const float phase, const zest_bounding_box *bound, const float *data, const int data_length)
{
    mrb_value vg = *nvg;

    struct RClass *theme = mrb_module_get(mrb, "Theme");

    mrb_value highlight_grad_1 = mrb_mod_cv_get(mrb, theme, mrb_intern_cstr(mrb, "FilterHighlight1"));
    mrb_value highlight_grad_2 = mrb_mod_cv_get(mrb, theme, mrb_intern_cstr(mrb, "FilterHighlight2"));

    mrb_funcall(mrb, vg, "begin_path", 0);

    const float initial_y = build_oscil_plot_path(mrb, nvg, phase, bound, data, data_length);

    mrb_funcall(mrb, vg, "line_to", 2,
        mrb_float_value(mrb, bound->right),
        mrb_float_value(mrb, bound->bottom));

    mrb_funcall(mrb, vg, "line_to", 2,
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, bound->bottom));

    mrb_funcall(mrb, vg, "line_to", 2,
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, initial_y));

    mrb_value gradient_paint = mrb_funcall(mrb, vg, "linear_gradient", 6,
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, bound->bottom),
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, bound->y),
            highlight_grad_1,
            highlight_grad_2);

    mrb_funcall(mrb, vg, "fill_paint", 1, gradient_paint);

    mrb_funcall(mrb, vg, "fill", 0);

    mrb_funcall(mrb, vg, "close_path", 0);
}

void
draw_oscil_plot_bidirectional_highlight(mrb_state *mrb, mrb_value *nvg, const float phase, const zest_bounding_box *bound, const float *data, const int data_length)
{
    mrb_value vg = *nvg;

    struct RClass *theme       = mrb_module_get(mrb, "Theme");

    mrb_value highlight_grad_1 = mrb_mod_cv_get(mrb, theme, mrb_intern_cstr(mrb,
                                                "HighlightGrad1"));
    mrb_value highlight_grad_2 = mrb_mod_cv_get(mrb, theme, mrb_intern_cstr(mrb,
                                                "HighlightGrad2"));

    // Over-highlight

    mrb_funcall(mrb, vg, "begin_path", 0);

    const float initial_y = build_oscil_plot_path(mrb, nvg, phase, bound, data, data_length);

    mrb_funcall(mrb, vg, "line_to", 2,
        mrb_float_value(mrb, bound->x + bound->w),
        mrb_float_value(mrb, bound->center_y));

    mrb_funcall(mrb, vg, "line_to", 2,
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, bound->center_y));

    mrb_funcall(mrb, vg, "line_to", 2,
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, initial_y));

    mrb_value gradient_paint = mrb_funcall(mrb, vg, "linear_gradient", 6,
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, bound->center_y),
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, bound->y),
            highlight_grad_1,
            highlight_grad_2);

    mrb_funcall(mrb, vg, "fill_paint", 1, gradient_paint);

    mrb_funcall(mrb, vg, "scissor", 4, 
        mrb_float_value(mrb, bound->x), 
        mrb_float_value(mrb, bound->y), 
        mrb_float_value(mrb, bound->w), 
        mrb_float_value(mrb, bound->h/2.f));

    mrb_funcall(mrb, vg, "fill", 0);

    mrb_funcall(mrb, vg, "reset_scissor", 0);

    mrb_funcall(mrb, vg, "close_path", 0);


    // Under-highlight

    mrb_funcall(mrb, vg, "begin_path", 0);

    build_oscil_plot_path(mrb, nvg, phase, bound, data, data_length);

    mrb_funcall(mrb, vg, "line_to", 2,
        mrb_float_value(mrb, bound->x + bound->w),
        mrb_float_value(mrb, bound->center_y));

    mrb_funcall(mrb, vg, "line_to", 2,
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, bound->center_y));

    mrb_funcall(mrb, vg, "line_to", 2,
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, initial_y));

    gradient_paint = mrb_funcall(mrb, vg, "linear_gradient", 6,
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, bound->center_y),
            mrb_float_value(mrb, bound->x),
            mrb_float_value(mrb, bound->bottom),
            highlight_grad_1,
            highlight_grad_2);

    mrb_funcall(mrb, vg, "fill_paint", 1, gradient_paint);

    mrb_funcall(mrb, vg, "scissor", 4, 
        mrb_float_value(mrb, bound->x), 
        mrb_float_value(mrb, bound->center_y), 
        mrb_float_value(mrb, bound->w), 
        mrb_float_value(mrb, bound->h/2.f));

    mrb_funcall(mrb, vg, "fill", 0);

    mrb_funcall(mrb, vg, "reset_scissor", 0);

    mrb_funcall(mrb, vg, "close_path", 0);
}

mrb_value
draw_oscil_plot(mrb_state *mrb, mrb_value self)
{
    mrb_value vg;
    mrb_value ypts;
    mrb_value bb;
    mrb_value do_norm;
    mrb_float phase;
    mrb_int plot_highlight;

    mrb_get_args(mrb, "oooofi", &vg, &ypts, &bb, &do_norm, &phase, &plot_highlight);

    int n = RARRAY_LEN(ypts);
    float *f = (float*)mrb_malloc(mrb, n*sizeof(float));
    for(int i=0; i<n; ++i)
        f[i] = mrb_ary_ref(mrb, ypts, i).value.f;

    if(mrb_obj_equal(mrb, mrb_true_value(), do_norm))
        normalize(f, n);
    
    zest_bounding_box bound;
    zest_bounding_box_init(mrb, &bb, &bound);

    if (plot_highlight == 1) {
        draw_oscil_plot_unidirectional_highlight(mrb, &vg, phase, &bound, f, n);
    } else if (plot_highlight == 2) {
        draw_oscil_plot_bidirectional_highlight(mrb, &vg, phase, &bound, f, n);
    }

    draw_oscil_plot_stroke(mrb, &vg, phase, &bound, f, n);

    mrb_free(mrb, f);

    return self;
}

//def self.norm_harmonics(seq)
//    (0...seq.length).each do |i|
//        seq[i] = -seq[i] if seq[i] < 0
//    end
//    max = -1
//    seq.each do |x|
//        max = x if x > max
//    end
//    (0...seq.length).each do |i|
//        seq[i] = (seq[i]/max)**0.1
//    end
//    seq
//end
static mrb_value
norm_harmonics(mrb_state *mrb, mrb_value self)
{
    mrb_value ary;
    mrb_get_args(mrb, "o", &ary);
    int n = RARRAY_LEN(ary);
    float *f = (float*)mrb_malloc(mrb, n*sizeof(float));
    for(int i=0; i<n; ++i)
        f[i] = mrb_ary_ref(mrb, ary, i).value.f;

    float max = -1.0;
    for(int i=0; i<n; ++i) {
        if(f[i] < 0)
            f[i] *= -1;
        if(f[i] > max)
            max = f[i];
    }

    for(int i=0; i<n; ++i)
        mrb_ary_set(mrb, ary, i,
                mrb_float_value(mrb, powf(f[i]/max, 0.1)));
    return ary;
}

//def self.bar(vg, data, bb, bar_color, xx=nil)
//    n    = data.length
//    xpts = Draw::DSP::linspace(0,1,n)
//    bx   = bb.x
//    bw   = bb.w
//    by   = bb.y
//    bh   = bb.h 
//
//    y  = by+bh
//
//    vg.stroke_color bar_color
//    vg.stroke_width 1.0
//    (0...n).each do |i|
//        x  = bx + xpts[i]*bw      if !xx
//        x  = bx + xx[i]  *bw/64.0 if  xx
//        vg.path do
//            vg.move_to(x, y)
//            vg.line_to(x, y-bh*data[i])
//            vg.stroke
//        end
//    end
//end
static mrb_value
bar(mrb_state *mrb, mrb_value self)
{
    mrb_value vg;
    mrb_value ypts;
    mrb_value bb;
    mrb_value color;
    mrb_value xx;

    mrb_get_args(mrb, "ooooo", &vg, &ypts, &bb, &color, &xx);

    int n = RARRAY_LEN(ypts);
    float *f = (float*)mrb_malloc(mrb, n*sizeof(float));
    for(int i=0; i<n; ++i)
        f[i] = mrb_ary_ref(mrb, ypts, i).value.f;

    const float bound_x = get(mrb, bb, "x");
    const float bound_y = get(mrb, bb, "y");
    const float bound_w = get(mrb, bb, "w");
    const float bound_h = get(mrb, bb, "h");

    const float y  = round(bound_y+bound_h);
    mrb_funcall(mrb, vg, "stroke_color", 1, color);
    mrb_funcall(mrb, vg, "stroke_width", 1, mrb_float_value(mrb, 1.0));

    mrb_funcall(mrb, vg, "translate", 2,
        mrb_float_value(mrb, 0.5f),
        mrb_float_value(mrb, 0.5f));

    for(int i=0; i<n; ++i)
    {
        float x;
        if(mrb_obj_equal(mrb, mrb_nil_value(), xx)) {
            x = bound_x + i*1.0/(n-1)*bound_w;
        } else {
            x = bound_x + mrb_ary_ref(mrb, xx, i).value.f*bound_w/64.0;
        }

        x = round(x);

        const int target_y = round(y-bound_h*f[i]);

        mrb_funcall(mrb, vg, "begin_path", 0);
        mrb_funcall(mrb, vg, "move_to", 2,
                mrb_float_value(mrb, x),
                mrb_float_value(mrb, y));
        mrb_funcall(mrb, vg, "line_to", 2,
                mrb_float_value(mrb, x),
                mrb_float_value(mrb, target_y));
        mrb_funcall(mrb, vg, "stroke", 0);
        mrb_funcall(mrb, vg, "close_path", 0);
    }

    mrb_funcall(mrb, vg, "translate", 2,
            mrb_float_value(mrb, -0.5f),
            mrb_float_value(mrb, -0.5f));

    mrb_free(mrb, f);
    return self;
}

void
mrb_mruby_zest_gem_init(mrb_state *mrb) {
    struct RClass *module = mrb_define_module(mrb, "Draw");
    mrb_define_class_method(mrb, module, "opt_plot", draw_oscil_plot, MRB_ARGS_REQ(6));
    mrb_define_class_method(mrb, module, "opt_norm_harmonics", norm_harmonics, MRB_ARGS_REQ(1));
    mrb_define_class_method(mrb, module, "opt_bar", bar, MRB_ARGS_REQ(5));
}
void
mrb_mruby_zest_gem_final(mrb_state* mrb) {
}
