#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <locale.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <errno.h>
#ifdef WIN32
#include <windows.h>
#else
#define __USE_GNU
#include <dlfcn.h>
#endif
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
    void (*zest_resize)(zest_t *, int w, int h);
    int  (*zest_tick)(zest_t*);
    int  (*zest_exit)(zest_t*);
    void (*zest_set_option)(zest_t*, const char *key, const char *value);
    zest_t *zest;
    int do_exit;
};

#ifdef __APPLE__
#include <mach/clock.h>
#include <mach/mach.h>
#endif

static void monotonic_clock_gettime(struct timespec *ts) {
#ifdef __APPLE__
    clock_serv_t cclock;
    mach_timespec_t mts;
    host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &cclock);
    clock_get_time(cclock, &mts);
    mach_port_deallocate(mach_task_self(), cclock);
    ts->tv_sec = mts.tv_sec;
    ts->tv_nsec = mts.tv_nsec;
#else
    clock_gettime(CLOCK_MONOTONIC, ts);
#endif
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
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    z->zest_resize(z->zest, width, height);
}

float target_animation_fps = 30.0f;
char *osc_path = 0;

static void
onDisplay(PuglView* view)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z)
        return;
    if(!z->zest) {
        printf("[INFO:Zyn] zest_open()\n");
        z->zest = z->zest_open(osc_path ? osc_path : "osc.udp://127.0.0.1:1337");
        printf("[INFO:Zyn] zest_setup()\n");
        z->zest_setup(z->zest);

        printf("[DEBUG:Zyn] setting up animation fps\n");
        char fps[128] = {0};
        snprintf(fps, sizeof(fps)-1, "%f", target_animation_fps);
        z->zest_set_option(z->zest, "animation_fps", fps);
    }

    z->zest_draw(z->zest);
}

static void
onUtf8KeyEvent(PuglView* view, char* utf8, bool press)
{
    struct zest_handles *z = puglGetHandle(view);
    z->zest_key(z->zest, utf8, press);
}

static void
onEvent(PuglView* view, const PuglEvent* event)
{
    switch(event->type)
    {
        case PUGL_NOTHING: break;
        case PUGL_BUTTON_PRESS:
        case PUGL_BUTTON_RELEASE:
        {
            const PuglEventButton* button = &event->button;
            onMouse(view, button->button, button->type == PUGL_BUTTON_PRESS,
                    button->x, button->y);
            break;
        }
        case PUGL_CONFIGURE:
        {
            const PuglEventConfigure* configure = &event->configure;
            onReshape(view, configure->width, configure->height);
            break;
        }
        case PUGL_EXPOSE:
            onDisplay(view);
            break;
        case PUGL_CLOSE:
            onClose(view);
            break;
        case PUGL_KEY_PRESS:
        case PUGL_KEY_RELEASE:
        {
            const PuglEventKey* key = &event->key;
            if(key->utf8[0])
                onUtf8KeyEvent(view, (char*)key->utf8,
                               event->type == PUGL_KEY_PRESS);
            if(key->special)
                onSpecial(view, event->type == PUGL_KEY_PRESS, key->special);
            break;
        }
        case PUGL_ENTER_NOTIFY: break;   /* Pointer entered view */
        case PUGL_LEAVE_NOTIFY: break;   /* Pointer left view */
        case PUGL_MOTION_NOTIFY:
        {
            const PuglEventMotion* motion = &event->motion;
            onMotion(view, motion->x, motion->y);
            break;
        }
        case PUGL_SCROLL:
        {
            const PuglEventScroll* scroll = &event->scroll;
            onScroll(view, scroll->x, scroll->y, scroll->dx, scroll->dy);
            break;
        }
        case PUGL_FOCUS_IN: break;       /* Keyboard focus entered view */
        case PUGL_FOCUS_OUT: break;      /* Keyboard focus left view */
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


void *setup_pugl(void *zest)
{
    PuglView *view = puglInit(0,0);
    puglSetHandle(view, zest);
    //puglInitWindowClass(view, "PuglWindow");
    puglInitWindowSize(view, 1181, 659);
    puglInitResizable(view, true);
    puglIgnoreKeyRepeat(view, true);

    puglSetEventFunc(view, onEvent);

    puglCreateWindow(view, "ZynAddSubFX 3.0.3");
    puglShowWindow(view);
    puglProcessEvents(view);
    return view;
}

char *conv(char *c, float f)
{
    sprintf(c, "%f", f);
    char *cc = c;
    while(*cc) {
        if(*cc == ',')
            *cc = '.';
        cc++;
    }
    return c;
}

const char *help =
"zyn-fusion - the user interface component of ZynAddSubFX for 3.0+ versions"
"\n\n"
"Options:\n"
"    --help             print this help\n"
"    --uri              specify remote osc server (for zynaddsubfx dsp)\n"
"                       e.g. osc.udp://127.0.0.1:1234\n"
"\n"
"Environmental Variables:\n"
"    ZEST_TARGET_FPS    target frames per second            [default 60]\n"
"    ZEST_ANIMATE_FPS   target animation updates per second [default 30]\n";



int main(int argc, char **argv)
{
    //setlocale(LC_NUMERIC, "it_IT.UTF-8");
    setlocale(LC_NUMERIC, "C");
    //char cvt[128];
    //printf("%f\n", +1.234);
    //printf("%f\n", -1.234);
    //printf("%s\n", conv(cvt,+1.234));
    //printf("%s\n", conv(cvt,-1.234));
    if(argc > 1 && strstr(argv[1], "osc"))
        osc_path = argv[1];

    float target_fps = 60.0f;
    if(getenv("ZEST_TARGET_FPS")) {
        errno = 0;
        target_fps = strtod(getenv("ZEST_TARGET_FPS"), 0);
        if(errno != 0)
            target_fps = 60.0f;

        if(target_fps < 0.1)
            target_fps = 0.1;
        else if(target_fps > 200)
            target_fps = 200;
    }

    if(getenv("ZEST_ANIMATE_FPS")) {
        errno = 0;
        target_animation_fps = strtod(getenv("ZEST_ANIMATE_FPS"), 0);
        if(errno != 0)
            target_animation_fps = 60.0f;

        if(target_animation_fps < 0.1)
            target_animation_fps = 0.1;
        else if(target_animation_fps > 200)
            target_animation_fps = 200;
    }


#ifdef WIN32
    void *handle = LoadLibrary("./libzest.dll");
#else
    void *handle = dlopen("./libzest.so", RTLD_LAZY);
    if(!handle)
        handle = dlopen("/opt/zyn-fusion/libzest.so", RTLD_LAZY);
    if(!handle)
        handle = dlopen("libzest.so", RTLD_LAZY);
#endif
    if(!handle) {
        printf("[ERROR] Cannot Open libzest.so\n");
        return 1;
        //printf("[ERROR] '%s'\n", dlerror());
    }
    struct zest_handles z = {0};
#ifdef WIN32
#define get(x) z.zest_##x = (void*) GetProcAddress(handle, "zest_" #x)
#else
#define get(x) z.zest_##x = (void*) dlsym(handle, "zest_" #x)
#endif

    get(open);
    get(setup);
    get(close);
    get(draw);
    get(tick);
    get(motion);
    get(scroll);
    get(mouse);
    get(key);
    get(special);
    get(resize);
    get(exit);
    get(set_option);

    z.do_exit       = 0;

#define check(x) if(!z.zest_##x) {printf("z.zest_" #x " = %p\n", z.zest_##x);}
    check(open);
    check(setup);
    check(close);
    check(draw);
    check(tick);
    check(motion);
    check(scroll);
    check(mouse);
    check(key);
    check(special);
    check(resize);
    check(exit);
    check(set_option);

    printf("[INFO:Zyn] setup_pugl()\n");
    void *view = setup_pugl(&z);
    printf("[INFO:Zyn] zest_tick()\n");
    int64_t frame_id = 0;
    const float frame_sleep = 1/target_fps;
    
    struct timespec before, post_tick, post_draw, post_events;
    float total, tick, draw, events;
    while(!z.do_exit) {
        monotonic_clock_gettime(&before);
        frame_id++;
        int needs_redraw = 1;

        puglProcessEvents(view);
        monotonic_clock_gettime(&post_events);

        if(z.zest)
            needs_redraw = z.zest_tick(z.zest);
        monotonic_clock_gettime(&post_tick);

#define TIME_DIFF(a,b) (b.tv_sec-a.tv_sec + 1e-9 *(b.tv_nsec-a.tv_nsec))
        if(needs_redraw)
            puglPostRedisplay(view);
        else {
            float time = frame_sleep-TIME_DIFF(before, post_tick);
            if(time > 0)
                usleep((int)(time*1e6));
        }
        monotonic_clock_gettime(&post_draw);

        if(false) {
            events = TIME_DIFF(before,      post_events);
            tick   = TIME_DIFF(post_events, post_tick);
            draw   = TIME_DIFF(post_tick,   post_draw);
            total  = tick+draw+events;
            fflush(stdout);
            printf("[PERF:%d%%]", (int)(100.0*total*target_fps));
            tick  /= total;
            draw  /= total;
            events  /= total;
            for(int i=0; i<tick*100; ++i)
                putchar('t');
            for(int i=tick*100; i<(tick+draw)*100; ++i)
                putchar(needs_redraw ? 'd' : 's');
            for(int i=(tick+draw)*100; i<100; ++i)
                putchar('e');
            putchar('\n');
            fflush(stdout);
        }
        if(z.zest && z.zest_exit(z.zest))
            break;
    }
    printf("[INFO:Zyn] zest_close()\n");
    z.zest_close(z.zest);
    printf("[INFO:Zyn] Destroying pugl view\n");
    puglDestroy(view);
    return 0;
}
