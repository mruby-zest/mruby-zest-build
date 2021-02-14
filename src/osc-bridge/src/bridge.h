#include <uv.h>
#include "schema.h"
#include "cache.h"
//A means of staying synchonized with respect to a collection of parameters
//presented over OSC in a REST like fashion

typedef struct {
    const char *path;
    double last_set;
} debounce_t;

typedef void (*bridge_cb_t)(const char *, void*);
typedef struct {
    const char *path;
    bridge_cb_t cb;
    void *data;
} bridge_callback_t;

//Bridge
typedef struct {
    uv_loop_t *loop;
    uv_udp_t socket;
    void *pending_requests;

    char *search_path;
    char *address;
    int port;
    int frame_messages;

    param_cache_t     *cache;
    debounce_t        *bounce;
    bridge_callback_t *callback;
    char             **rlimit;
    int cache_len;
    int debounce_len;
    int callback_len;
    int rlimit_len;
    uint64_t last_update;
} bridge_t;

//Maximum messages per br_tick() frame
#define BR_RATE_LIMIT 128

//Create a remote OSC bridge
bridge_t *br_create(uri_t);
//Destroy and deallocate an OSC bridge
void      br_destroy(bridge_t *br);

//Obtain a copy of the scheama used to communicate over OSC
schema_t br_get_schema(bridge_t*, uri_t);
//Deallocate a schema instance
void br_destroy_schema(schema_t);

/**
 * Randomize a value according to schema min/max
 *
 * XXX - This method is not yet implemented
 */
void br_randomize(bridge_t *, uri_t);

void br_default(bridge_t *, schema_t, uri_t);

//Value setters
void br_set_array(bridge_t *, uri_t, char*, rtosc_arg_t*);
void br_set_value_bool(bridge_t *, uri_t, int);
void br_set_value_int(bridge_t *, uri_t, int);
void br_set_value_float(bridge_t *, uri_t, float);
void br_set_value_string(bridge_t *, uri_t, const char *);

/** Return 1 if uri has a callback bound to it*/
int  br_has_callback(bridge_t *, uri_t);

/**
 * Add a callback to the provided uri
 *
 * If the provided uri has data in the cache it, the callback is invoked
 * immediately. Otherwise the data is requested and the callback is
 * called when data is available. The callback is invoked when the bound
 * data changes.
 */
void br_add_callback(bridge_t *, uri_t, bridge_cb_t, void*);

/**
 * Add callback to the provided uri without requesting data
 */
void br_add_action_callback(bridge_t *, uri_t, bridge_cb_t, void*);

/**
 * Remove callback from uri
 */
void br_del_callback(bridge_t *, uri_t, bridge_cb_t, void*);

/**
 * Invalidate cached data which matches the partial path provided
 */
void br_damage(bridge_t *, uri_t);

/**
 * Rate limited refresh of given uri
 */
void br_refresh(bridge_t *, uri_t);

/**
 * Rate limited refresh of given uri
 *
 * Note: this is different than br_refresh in the case that:
 *
 * 1. br_refresh(a)
 * 2. send osc message which alters 'a', but does not broadcast the change
 * 3. br_refresh(a)
 *
 * Will not send a request with step 3 while force_refresh will 'eventually'
 * send an update for 'a' after a timeout
 */
void br_force_refresh(bridge_t *, uri_t);

/**
 * Start a state watch on remote host via '/watch/add' port
 */
void br_watch(bridge_t *, uri_t);

/**
 * Send a raw OSC message to the remote host
 *
 * These messages should conform to the actions specified in the osc schema
 */
void br_action(bridge_t *, uri_t, const char *argt, const rtosc_arg_t *args);

/**
 * Handle incoming OSC messages from remote host
 */
void br_recv(bridge_t *, const char *);

//Returns the number of cache fields in the 'pending' state
int  br_pending(bridge_t *);

/**
 * Communicate with remote host
 *
 * This function should be called frequently (10-120Hz) in the main loop
 * of the program.
 *
 * This routine:
 * - Sends requests for data
 * - Receives data based upon requests
 * - Runs callbacks based upon new data
 * - Retries requesting data based upon timeouts
 * - Rate limits data requests
 */
void br_tick(bridge_t *);

/*
 * Report last update from remote in seconds
 *
 * Note - For a system which isn't experiencing lag, this should typically be
 *        zero
 */
int  br_last_update(bridge_t *);//returns delta time in seconds

//Print statistics about bridge/schema
void print_stats(bridge_t *br, schema_t sch);


//Testing Hooks
extern int  (*osc_socket_hook)(void);
extern int  (*osc_request_hook)(bridge_t *, const char *);
