#include <assert.h>
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
    void (*zest_motion)(zest_t*, int x, int y, int mod);
    void (*zest_scroll)(zest_t*, int x, int y, int dx, int dy, int mod);
    void (*zest_mouse)(zest_t *z, int button, int action, int x, int y, int mod);
    void (*zest_key)(zest_t *, const char *key, int press);
    void (*zest_special)(zest_t *, int key, int press);
    void (*zest_resize)(zest_t *, int w, int h);
    int  (*zest_tick)(zest_t*);
    int  (*zest_exit)(zest_t*);
    void (*zest_set_option)(zest_t*, const char *key, const char *value);
    void (*zest_dnd_drop)(zest_t*, const char*);
    const char* (*zest_dnd_pick)(zest_t*);
    const char* (*zest_get_remote_url)(zest_t*);

    void (*zest_script)(zest_t *, const char *str);

    zest_t *zest;
    int do_exit;

    // drag and drop variables if zest is the target
    int dnd_target_best_slot;          //!< ID of the offered types
    int dnd_target_best_mimetype;      //!< mimetype in the best slot
    PuglDndSourceStatus dnd_source_status;
    PuglDndTargetStatus dnd_target_status;

    char dnd_source_widget_path[1024]; //!< OSC path of dragged widget, or ""
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
onMotion(PuglView* view, int x, int y, int mod)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    z->zest_motion(z->zest, x, y, mod);
}

static void
onMouse(PuglView* view, int button, bool press, int x, int y, int mod)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    if(z->dnd_source_status == PuglNotDndSource &&
       z->dnd_target_status == PuglNotDndTarget) {
        z->zest_mouse(z->zest, button, press, x, y, mod);
    }
}

static void
onScroll(PuglView* view, int x, int y, float dx, float dy, int mod)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    z->zest_scroll(z->zest, x, y, dx, dy, mod);
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
char *script_data = 0;

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

        if(script_data)
            z->zest_script(z->zest, script_data);
    }

    z->zest_draw(z->zest);
}

static void
onUtf8KeyEvent(PuglView* view, char* utf8, bool press)
{
    struct zest_handles *z = puglGetHandle(view);
    if(z->zest)
	    z->zest_key(z->zest, utf8, press);
}

// convert pugl-new-style event structs to pugl-old-style event callbacks
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
                    button->x, button->y, button->state);
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
            onMotion(view, motion->x, motion->y, motion->state);
            break;
        }
        case PUGL_SCROLL:
        {
            const PuglEventScroll* scroll = &event->scroll;
            onScroll(view, scroll->x, scroll->y, scroll->dx, scroll->dy, scroll->state);
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

/*
 * Drag and Drop functionality
 */

// what we can send:
enum {
    application_x_osc_stringpair,
    /* insert more here and keep in sync with send_mime_names! */
    send_mime_count
};

char *send_mime_names[send_mime_count] = {
    "application/x-osc-stringpair"
    /* insert more here and keep in sync with above enum! */
};

// what we can receive:
enum {
    // mozilla [1] recommends to prefer the most specific mimetype
    // => the larger the number, the better
    // [1] https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API/Recommended_drag_types
    text_plain,
    text_uri_list,
    // text_x_moz_url, /* unsupported, as it seems to use wide characters */
    /* insert more here and keep in sync with recv_mime_names! */
    recv_mime_count
};

char *recv_mime_names[recv_mime_count] = {
    "text/plain",
    "text/uri-list",
    // "text/x-moz-url"
    /* insert more here and keep in sync with above enum! */
};

static void
onDndSourceStatus(PuglView* view, PuglDndSourceStatus status) {
//  printf("source status: %d\n", (int)status);
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;
    z->dnd_source_status = status;
}

static void
onDndTargetStatus(PuglView* view, PuglDndTargetStatus status) {
//  printf("target status: %d\n", (int)status);
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;
    z->dnd_target_status = status;
}

static PuglDndAction
onDndSourceAction(PuglView* view, int rootx, int rooty)
{
    (void)view; (void)rootx; (void)rooty;
    // currently, if pugl is the dnd source, we only support
    // linking knobs with DAW automation
    return PuglDndActionLink;
}

static int
onDndSourceDrag(PuglView* view, int x, int y)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return 0;
    const char* widget_path = z->zest_dnd_pick(z->zest);
    if(widget_path && *widget_path) {
        *z->dnd_source_widget_path = 0;
        strncat(z->dnd_source_widget_path, widget_path,
                sizeof(z->dnd_source_widget_path)-1);
        return 1;
    }
    else
        return 0; /* forbid drag */
}

static void
onDndSourceFinished(PuglView* view, int accepted)
{
    (void)view; (void)accepted;
}

static PuglKey
onDndSourceKey(PuglView* view)
{
    (void)view;
    return PUGL_KEY_F1;
}

static const char*
onDndSourceOfferType(PuglView* view, int rootx, int rooty, int slot)
{
    (void)view; (void)rootx; (void)rooty;
    // provide application/x-osc-stringpair in slot 0
    // if we will offer other mimetypes to drag, add them here
    // note that using more than 3 slots (e.g. using slot 3) requires
    // implementation in pugl_x11.c
    return slot ? NULL : send_mime_names[application_x_osc_stringpair];
}

static int
onDndSourceProvideData(PuglView* view, int slot, int size, char* buffer)
{
    assert(!slot);
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return 0;

    size_t sz = 1024;
    char offered_property[sz];
    *offered_property = 0;
    // e.g. osc.udp://127.0.0.1:17070/path/to/port
    int res = snprintf(offered_property, sz-1, "automatable_model:%s%s",
             z->zest_get_remote_url(z->zest), z->dnd_source_widget_path);
    assert(res < sz);

    int len = 1 + strlen(offered_property);
    assert(len <= size);
    strcpy(buffer, offered_property);
    return len;
}

// also used as a cleanup-function:
static void
onDndTargetLeave(PuglView* view)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;
    z->dnd_target_best_slot = -1;
    z->dnd_target_best_mimetype = -1;
}

static int
onDndTargetAcceptDrop(PuglView* view)
{
    const struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return 0;
    if(z->dnd_target_best_slot == -1)
        return 0;
    else
    {
        onDndTargetLeave(view); // reset for next time
        return 1;
    }
}

static int
onDndTargetChooseTypesToLookup(PuglView* view)
{
    const struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return 0;

    // this function is being called both when the pointer position changes and
    // during the drop; we only need to request data in the second case
    if(z->dnd_target_status == PuglDndTargetDropped)
    {
        int slot = z->dnd_target_best_slot;
        if(slot == -1)
            return 0;
        else
            return 1 << slot;
    }
    else
        return 0;
}

static void
onDndTargetDrop(PuglView* view)
{
    (void)view;
}

static int
onDndTargetInformPosition(PuglView* view, int x, int y, PuglDndAction a)
{
    // files can be dropped everywhere:
    (void)x; (void)y;
    // file dropping means:
    if(a == PuglDndActionCopy)
        return 1;
    else {
        onDndTargetLeave(view); // reset
        return 0;
    }
}

static void
onDndTargetOfferType(PuglView* view, int slot, const char* mimetype)
{
    struct zest_handles *z = puglGetHandle(view);
    if(!z || !z->zest)
        return;

    // mozilla recommends to pick the most specific type,
    // i.e. the highest enum
    for(int i = 1 + z->dnd_target_best_mimetype; i < recv_mime_count; ++i)
    if(!strcmp(recv_mime_names[i], mimetype))
    {
        z->dnd_target_best_slot = slot;
        z->dnd_target_best_mimetype = i;
    }
}

// get next line which is not empty and not starting with #
static const char*
next_in_urilist(const char* start)
{
    while(start && *start && *start == '#')
    {
        start = strchr(start, '\n');
        if(start) ++start;
    }
    return (start && *start && *start != '\n' && *start != '\r') ? start : NULL;
}

// translate uri in-place into filename
void uri_to_filename(char* filename)
{
    const char* read = filename + (!strncmp(filename, "file://", 7) ? 7 : 0);
    char* write = filename;
    while(*read)
    {
        switch(*read)
        {
            case '%':
            {
                int i=0, skipped=0;
                sscanf(++read, "%x%n", &i, &skipped);
                read += skipped;
                if(i>255) i = 0; // be safe
                *write++ = (char)i;
                break;
            }
            case '\n':
            case '\r': *write++ = 0; ++read; break;
            default: *write++ = *read; ++read; break;
        }
    }
}

static void
onDndTargetReceiveData(PuglView* view, int slot, int size, const char* property)
{
    (void)slot;

    int uris_counted = 0;
    const char* uri1 = next_in_urilist(property);
    const char* uri1_end;

    if(uri1)
    {
        uris_counted = 1;
        uri1_end = uri1;
        for(; *uri1_end && *uri1_end != '\n'; ++uri1_end) ;

        if(*uri1_end)
        {
            const char* uri2 = next_in_urilist(uri1_end + 1);
            if(uri2)
                uris_counted = 2;
        }
    }

    if(1 == uris_counted)
    {
        char filename[size];
        {
            // copy to no-const buffer
            int i;
            for(i = 0; uri1[i] && uri1[i] != '\n'; ++i) filename[i] = uri1[i];
            filename[i] = 0;
        }
        uri_to_filename(filename);

        if(0 == access(filename, R_OK))
        {
            struct zest_handles *z = puglGetHandle(view);
            if(!z || !z->zest)
                return;
            z->zest_dnd_drop(z->zest, filename);
        }
        else
            fprintf(stderr, "Unable to read file \"%s\"\n", filename);
    }
    else
        fprintf(stderr, "Unable to load %d files at once\n", uris_counted);
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
    puglSetDndSourceStatusFunc(view, onDndSourceStatus);
    puglSetDndSourceActionFunc(view, onDndSourceAction);
    puglSetDndSourceDragFunc(view, onDndSourceDrag);
    puglSetDndSourceFinishedFunc(view, onDndSourceFinished);
    puglSetDndSourceKeyFunc(view, onDndSourceKey);
    puglSetDndSourceOfferTypeFunc(view, onDndSourceOfferType);
    puglSetDndSourceProvideDataFunc(view, onDndSourceProvideData);
    puglSetDndTargetStatusFunc(view, onDndTargetStatus);
    puglSetDndTargetAcceptDropFunc(view, onDndTargetAcceptDrop);
    puglSetDndTargetChooseTypesToLookupFunc(view,
                                            onDndTargetChooseTypesToLookup);
    puglSetDndTargetDropFunc(view, onDndTargetDrop);
    puglSetDndTargetInformPositionFunc(view, onDndTargetInformPosition);
    puglSetDndTargetLeaveFunc(view, onDndTargetLeave);
    puglSetDndTargetOfferTypeFunc(view, onDndTargetOfferType);
    puglSetDndTargetReceiveDataFunc(view, onDndTargetReceiveData);

    puglCreateWindow(view, "ZynAddSubFX 3.0.6");
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
"    --uri    URI       specify remote osc server (for zynaddsubfx dsp)\n"
"                       e.g. osc.udp://127.0.0.1:1234\n"
"    --script SCRIPT    specify script to register events for screenshot\n"
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
    {
        int next_script = 0;
        for(int i=1; i<argc; ++i) {
            if(!strcmp(argv[i], "--help")) {
                fputs(help, stderr);
                return 0;
            } else if(strstr(argv[i], "osc"))
                osc_path = argv[i];
            else if(next_script) {
                FILE *f = fopen(argv[i], "r");
                if(!f)
                    continue;
                fseek(f, 0, SEEK_END);
                size_t fsize = ftell(f);
                fseek(f, 0, SEEK_SET);

                script_data = calloc(1,fsize+1);
                fread(script_data, fsize, 1, f);
                fclose(f);
            } else if(!strcmp("--script", argv[i]))
                next_script = 1;
        }
    }

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
    if(handle)
        printf("[INFO] Succeeded in loading development libzest.so\n");
    else
        printf("[INFO] Loading system libzest.so\n");
    if(!handle)
        handle = dlopen("libzest.so", RTLD_LAZY);
    if(!handle)
        handle = dlopen("/opt/zyn-fusion/libzest.so", RTLD_LAZY);
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
    get(dnd_drop);
    get(dnd_pick);
    get(script);
    get(get_remote_url);

    z.do_exit       = 0;
    z.dnd_target_best_slot = -1;
    z.dnd_target_best_mimetype = -1;
    *z.dnd_source_widget_path = 0;

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
    check(dnd_drop);
    check(dnd_pick);
    check(script);
    check(get_remote_url);

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

#ifndef _WIN32
        puglEnterContext(view);
#endif
        if(z.zest)
            needs_redraw = z.zest_tick(z.zest);
#ifndef _WIN32
        puglLeaveContext(view, 0);
#endif

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
