#include <stdio.h>
#include <dlfcn.h>
#include <unistd.h>
#include "deps/pugl/pugl/pugl.h"

typedef void *zest_t;
struct zest_handles {
    zest_t *(*zest_open)(const char *);
    void (*zest_close)(zest_t*);
    void (*zest_setup)(zest_t*);
    void (*zest_draw)(zest_t*);
    void (*zest_motion)(zest_t*, int x, int y);
    void (*zest_scroll)(zest_t*, int x, int y, int dx, int dy);
    void (*zest_mouse)();
    void (*zest_key)(zest_t *, const char *key, int press);
    void (*zest_special)(zest_t *, int key, int press);
    void (*zest_resize)();
    int (*zest_tick)(zest_t*);
    zest_t *zest;
    int do_exit;
};

static void
onEvent(PuglView* view, const PuglEvent* event)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    if((event->type == PUGL_KEY_PRESS ||
            event->type == PUGL_KEY_RELEASE) &&
            event->key.utf8[0]) {
        z->zest_key(z->zest, (char*)event->key.utf8,
                event->type == PUGL_KEY_PRESS);
    }
    //if(event->key.keycode == 50) {
    //    int press = event->type == PUGL_KEY_PRESS;
    //    const char *pres_rel = press ? "press" : "release";
    //    mrb_state *mrb = v[0];
    //    mrb_value obj = mrb_obj_value(v[1]);
    //    mrb_funcall(mrb, obj, "key_mod", 2,
    //            mrb_str_new_cstr(mrb, pres_rel),
    //            mrb_str_new_cstr(mrb, "shift"));
    //}

}

static void
onSpecial(PuglView* view, bool press, PuglKey key)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    z->zest_special(z->zest, key, press);
}

static void
onMotion(PuglView* view, int x, int y)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    z->zest_motion(z->zest, x, y);
}

static void
onMouse(PuglView* view, int button, bool press, int x, int y)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    z->zest_mouse(z->zest, button, press, x, y);
}

static void
onScroll(PuglView* view, int x, int y, float dx, float dy)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    z->zest_scroll(z->zest, x, y, dx, dy);
}

static void
onClose(PuglView* view)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    z->do_exit = 1;
}

static void
onReshape(PuglView* view, int width, int height)
{
#if 0
    void **v = (void**)puglGetHandle(view);
    //printf("reshape to %dx%d\n", width, height);
    if(v) {
        mrb_value obj = mrb_obj_value(v[1]);
        mrb_funcall(v[0], obj, "resize", 2, mrb_fixnum_value(width), mrb_fixnum_value(height));
    }
#endif
}

static void
onDisplay(PuglView* view)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z)
        return;
    if(!z->zest) {
        printf("[INFO:Zyn] zest_open()\n");
        z->zest = z->zest_open("osc.udp://127.0.0.1:1337");
        printf("[INFO:Zyn] zest_setup()\n");
        z->zest_setup(z->zest);
    }

    z->zest_draw(z->zest);
}

void *setup_pugl(void *zest)
{
    void *view = puglInit(0,0);
    //puglInitWindowClass(view, "PuglWindow");
	puglInitWindowSize(view, 1181, 659);
    puglInitResizable(view, true);
    puglIgnoreKeyRepeat(view, true);

	puglSetEventFunc(view, onEvent);
	puglSetMotionFunc(view, onMotion);
	puglSetMouseFunc(view, onMouse);
	puglSetScrollFunc(view, onScroll);
	puglSetSpecialFunc(view, onSpecial);
	puglSetDisplayFunc(view, onDisplay);
	puglSetReshapeFunc(view, onReshape);
	puglSetCloseFunc(view, onClose);

	puglCreateWindow(view, "Zyn The Overdue");
	puglShowWindow(view);
    puglProcessEvents(view);
    puglSetHandle(view, zest);
    return view;
}

int main()
{
    void *handle = dlopen("./libzest.so", RTLD_LAZY);
    if(!handle) {
        printf("[ERROR] Cannot Open libzest.so\n");
        printf("[ERROR] '%s'\n", dlerror());
    }
    struct zest_handles z = {0};
    z.zest_open     = dlsym(handle, "zest_open");
    z.zest_setup    = dlsym(handle, "zest_setup");
    z.zest_close    = dlsym(handle, "zest_close");
    z.zest_draw     = dlsym(handle, "zest_draw");
    z.zest_tick     = dlsym(handle, "zest_tick");
    z.zest_motion   = dlsym(handle, "zest_motion");
    z.zest_scroll   = dlsym(handle, "zest_scroll");
    z.zest_mouse    = dlsym(handle, "zest_mouse");
    z.zest_key      = dlsym(handle, "zest_key");
    z.zest_special  = dlsym(handle, "zest_special");
    z.do_exit       = 0;

    printf("[INFO:Zyn] setup_pugl()\n");
    void *view = setup_pugl(&z);
    printf("[INFO:Zyn] zest_tick()\n");
    int64_t frame_id = 0;
    const float target_fps  = 60.0;
    const float frame_sleep = 1/target_fps;
    while(!z.do_exit) {
        frame_id++;
        putchar('.');
        fflush(stdout);
        int needs_redraw = 1;
        if(z.zest)
            needs_redraw = z.zest_tick(z.zest);
        if(needs_redraw)
            puglPostRedisplay(view);
        else
            usleep((int)(frame_sleep*1e6));
        puglProcessEvents(view);
    }
    printf("[INFO:Zyn] zest_close()\n");
    z.zest_close(z.zest);
    printf("[INFO:Zyn] Destroying pugl view\n");
    puglDestroy(view);
    return 0;
}
