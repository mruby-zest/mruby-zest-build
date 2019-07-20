#include <mruby.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/variable.h>
#include <mruby/array.h>
#include <assert.h>

typedef struct
{
    mrb_float x, y, w, h;
} mrb_draw_rect;

typedef struct
{
    mrb_draw_rect bounds;
    int layer;
    mrb_value item;
    mrb_value self;
} mrb_draw_seq_node;

typedef struct
{
    int               len;
    mrb_draw_seq_node *seq;
} mrb_draw_seq;

static void
mrb_common_free(mrb_state *mrb, void *ptr)
{
}

const struct mrb_data_type mrb_draw_rect_type = {"DrawRect", mrb_common_free};
const struct mrb_data_type mrb_draw_seq_node_type = {"DrawSeqNode", mrb_common_free};
const struct mrb_data_type mrb_draw_seq_type = {"DrawSeq", mrb_common_free};


#define set_local(mrb, obj, var, value) \
    mrb_iv_set(mrb, obj, mrb_intern_lit(mrb, var), value);

static mrb_value
mrb_draw_rect_initialize(mrb_state *mrb, mrb_value self)
{
    mrb_draw_rect *r = 
        (mrb_draw_rect *)mrb_malloc(mrb, sizeof(mrb_draw_rect));
    mrb_get_args(mrb, "ffff", &r->x, &r->y, &r->w, &r->h);
    mrb_data_init(self, r, &mrb_draw_rect_type);

    set_local(mrb, self, "@x", mrb_float_value(mrb,r->x));
    set_local(mrb, self, "@y", mrb_float_value(mrb,r->y));
    set_local(mrb, self, "@w", mrb_float_value(mrb,r->w));
    set_local(mrb, self, "@h", mrb_float_value(mrb,r->h));

    return self;
}

static mrb_value
mrb_draw_seq_node_initialize(mrb_state *mrb, mrb_value self)
{
    mrb_draw_seq_node *view =
        (mrb_draw_seq_node*)mrb_malloc(mrb, sizeof(mrb_draw_seq_node));
    mrb_float x=0, y=0, w=0, h=0, layer=0;
    mrb_value item, tmp;
    mrb_get_args(mrb, "ffo", &x, &y, &item);
    tmp = mrb_funcall(mrb, item, "w", 0);
    if(tmp.tt == MRB_TT_FLOAT)
        w = tmp.value.f;
    else if(tmp.tt == MRB_TT_FIXNUM)
        w = tmp.value.i;

    tmp = mrb_funcall(mrb, item, "h", 0);
    if(tmp.tt == MRB_TT_FLOAT)
        h = tmp.value.f;
    else if(tmp.tt == MRB_TT_FIXNUM)
        h = tmp.value.i;
    
    tmp = mrb_funcall(mrb, item, "layer", 0);
    if(tmp.tt == MRB_TT_FIXNUM)
        layer = tmp.value.i;

    view->bounds.x = x;
    view->bounds.y = y;
    view->bounds.w = w;
    view->bounds.h = h;
    view->item   = item;
    view->layer  = layer;
    view->self   = self;

    set_local(mrb, self, "@x", mrb_float_value(mrb,x));
    set_local(mrb, self, "@y", mrb_float_value(mrb,y));
    set_local(mrb, self, "@w", mrb_float_value(mrb,w));
    set_local(mrb, self, "@h", mrb_float_value(mrb,h));
    set_local(mrb, self, "@item", item);
    set_local(mrb, self, "@layer", mrb_fixnum_value(layer));
    mrb_data_init(self, view, &mrb_draw_seq_node_type);
    return self;
}

static mrb_value
mrb_draw_seq_initialize(mrb_state *mrb, mrb_value self)
{
    mrb_draw_seq *view = (mrb_draw_seq *)
        mrb_malloc(mrb, sizeof(mrb_draw_seq));
    view->len = 0;
    view->seq = 0;
    mrb_data_init(self, view, &mrb_draw_seq_type);
    mrb_funcall(mrb, self, "initialize_rb", 0);
    return self;
}

int
intersect(mrb_draw_rect a, mrb_draw_rect b)
{
    int left_in  = a.x       >=b.x && a.x       <=b.x+b.w;
    int right_in = a.x+a.w   >=b.x && a.x+a.w   <=b.x+b.w;
    int lr_in    = a.x       <=b.x && a.x+a.w   >=b.x+b.w;

    int top_in   = a.y       >=b.y && a.y       <=b.y+b.h;
    int bot_in   = a.y+a.h   >=b.y && a.y+a.h   <=b.y+b.h;
    int tb_in    = a.y       <=b.y && a.y+a.h   >=b.y+b.h;

    return (left_in || right_in || lr_in) && (top_in || bot_in || tb_in);
}

int
hit(mrb_draw_rect a, float x, float y)
{
    int hx = a.x <= x && x <= a.x+a.w;
    int hy = a.y <= y && y <= a.y+a.h;
    return hx && hy;
}

#define GET_DATA(x) x *view = (x*)mrb_data_get_ptr(mrb, self, &x##_type)
#define GET_DATA2(x,y) x *data = (x*)mrb_data_get_ptr(mrb, y, &x##_type)
mrb_value
mrb_draw_seq_event_widget(mrb_state *mrb, mrb_value self)
{
    GET_DATA(mrb_draw_seq);
    mrb_float x, y;
    mrb_sym method=0;
    mrb_value tmp;
    int check_method = 0;
    mrb_get_args(mrb, "ffo", &x, &y, &tmp);
    
    if(!mrb_obj_equal(mrb, mrb_nil_value(), tmp)) {
        check_method = 1;
        method = tmp.value.sym;
    }


    mrb_value sel = mrb_nil_value();
    int selected_layer = 0;

    for(int i=0; i<view->len; ++i) {
        mrb_draw_seq_node e = view->seq[i];
        if(e.layer == 1)
            continue;
        if(selected_layer == 2 && e.layer != 2)
            continue;
        if(check_method && !mrb_obj_respond_to(mrb, mrb_class(mrb, e.item), method))
            continue;
        if(hit(e.bounds, x, y)) {
            selected_layer = e.layer;
            sel            = e.item;
        }
    }
    return sel;
}

static mrb_value
mrb_draw_seq_node_hit(mrb_state *mrb, mrb_value self)
{
    mrb_float x, y;
    GET_DATA(mrb_draw_seq_node);
    mrb_get_args(mrb, "ff", &x, &y);

    if(hit(view->bounds, x, y))
        return mrb_true_value();
    else
        return mrb_false_value();
}

static mrb_value
mrb_draw_seq_node_intersect(mrb_state *mrb, mrb_value self)
{
    GET_DATA(mrb_draw_seq_node);
    mrb_value obj;
    mrb_get_args(mrb, "o", &obj);
    GET_DATA2(mrb_draw_rect, obj);
    if(intersect(view->bounds, *data))
        return mrb_true_value();
    else
        return mrb_false_value();
}

mrb_value
mrb_draw_seq_clear_seq(mrb_state *mrb, mrb_value self)
{
    GET_DATA(mrb_draw_seq);
    view->len = 0;
    return self;
}

mrb_value
mrb_draw_seq_add_seq(mrb_state *mrb, mrb_value self)
{
    GET_DATA(mrb_draw_seq);
    mrb_value elm;
    mrb_get_args(mrb, "o", &elm);
    view->len += 1;
    view->seq  =
       (mrb_draw_seq_node*) mrb_realloc(mrb, view->seq, view->len*sizeof(mrb_draw_seq_node));
    GET_DATA2(mrb_draw_seq_node, elm);
    view->seq[view->len-1] = *data;

    return self;
}

mrb_value
mrb_draw_seq_get_node(mrb_state *mrb, mrb_value self)
{
    GET_DATA(mrb_draw_seq);
    mrb_value obj;
    mrb_get_args(mrb, "o", &obj);
    for(int i=0; i<view->len; ++i)
        if(mrb_obj_equal(mrb, obj, view->seq[i].item))
            return mrb_ary_ref(mrb,
                    mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@seq")), i);
    return mrb_nil_value();
}

mrb_value
mrb_draw_seq_render_seqs(mrb_state *mrb, mrb_value self)
{
    GET_DATA(mrb_draw_seq);
    mrb_value dmg     = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "@damage"));
    mrb_value base    = mrb_ary_new(mrb);
    mrb_value animate = mrb_ary_new(mrb);
    mrb_value overlay = mrb_ary_new(mrb);
    int n = RARRAY_LEN(dmg);
    for(int i=0; i<view->len; ++i) {
        mrb_draw_seq_node node = view->seq[i];
        int needs_redraw = 0;
        for(int j=0; j<n; ++j) {
            mrb_value d = mrb_ary_ref(mrb, dmg, j);
            mrb_value a = mrb_ary_ref(mrb, d, 0);
            mrb_value b = mrb_ary_ref(mrb, d, 1);
            assert(b.tt == MRB_TT_FIXNUM);
            GET_DATA2(mrb_draw_rect, a);
            int dmg_layer = b.value.i;
            if(node.layer == dmg_layer && intersect(node.bounds, *data)) {
                needs_redraw = 1;
            }
        }

        if(needs_redraw) {
            if(node.layer == 0)
                mrb_ary_push(mrb, base, node.self);
            else if(node.layer == 1)
                mrb_ary_push(mrb, animate, node.self);
            else if(node.layer == 2)
                mrb_ary_push(mrb, overlay, node.self);
        }
    }
    mrb_value result = mrb_ary_new(mrb);
    mrb_ary_push(mrb, result, base);
    mrb_ary_push(mrb, result, animate);
    mrb_ary_push(mrb, result, overlay);
    return result;
}

mrb_value 
mrb_draw_rect_hit(mrb_state *mrb, mrb_value self)
{
    assert(0);
    return self;
}

mrb_value
mrb_draw_rect_intersect(mrb_state *mrb, mrb_value self)
{
    assert(0);
    return self;
}

void draw_seq_start(mrb_state *mrb)
{
    struct RClass *draw_rect = mrb_define_class(mrb, "DrawRect", mrb->object_class);
    struct RClass *draw_seq_node = mrb_define_class(mrb, "DrawSeqNode", mrb->object_class);
    struct RClass *draw_seq = mrb_define_class(mrb, "DrawSequence", mrb->object_class);
    MRB_SET_INSTANCE_TT(draw_rect, MRB_TT_DATA);
    MRB_SET_INSTANCE_TT(draw_seq_node, MRB_TT_DATA);
    MRB_SET_INSTANCE_TT(draw_seq, MRB_TT_DATA);

    mrb_define_method(mrb, draw_rect,    "initialize",
            mrb_draw_rect_initialize, MRB_ARGS_REQ(4));
    mrb_define_method(mrb, draw_seq_node, "initialize",
            mrb_draw_seq_node_initialize, MRB_ARGS_REQ(3));
    mrb_define_method(mrb, draw_seq,     "initialize",
            mrb_draw_seq_initialize, MRB_ARGS_NONE());
    mrb_define_method(mrb, draw_seq_node, "hit?",
            mrb_draw_seq_node_hit, MRB_ARGS_REQ(2));
    mrb_define_method(mrb, draw_seq_node, "intersect?",
            mrb_draw_seq_node_intersect, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, draw_rect,    "hit?",
            mrb_draw_rect_hit, MRB_ARGS_REQ(2));
    mrb_define_method(mrb, draw_rect,    "intersect?",
            mrb_draw_rect_intersect, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, draw_seq,     "event_widget",
            mrb_draw_seq_event_widget, MRB_ARGS_ANY());
    mrb_define_method(mrb, draw_seq,     "get_node",
            mrb_draw_seq_get_node,   MRB_ARGS_REQ(1));
    mrb_define_method(mrb, draw_seq,     "add_seq_c",
            mrb_draw_seq_add_seq,    MRB_ARGS_REQ(1));
    mrb_define_method(mrb, draw_seq,     "clear_seq_c",
            mrb_draw_seq_clear_seq,  MRB_ARGS_NONE());
    mrb_define_method(mrb, draw_seq,     "render_seqs",
            mrb_draw_seq_render_seqs,  MRB_ARGS_NONE());
}
