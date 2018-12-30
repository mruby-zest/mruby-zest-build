#ifndef ZEST_API_H_DEFINED
#define ZEST_API_H_DEFINED

#ifdef __cplusplus
extern "C" {
#endif

typedef struct mrb_state mrb_state;
typedef struct mrb_value mrb_value;
typedef struct zest_t zest_t;

zest_t *zest_open(char *address);
void zest_close(zest_t *);
void zest_setup(zest_t *);
void zest_draw(zest_t *);
void zest_motion(zest_t *, int x, int y, int mod);
void zest_scroll(zest_t *, int x, int y, int dx, int dy, int mod);
void zest_mouse(zest_t *z, int button, int action, int x, int y, int mod);
void zest_key(zest_t *z, const char *key, int press);
void zest_resize(zest_t *z, int w, int h);
void zest_special(zest_t *z, int key, int press);
int zest_tick(zest_t *);

#ifdef __cplusplus
}
#endif

#endif