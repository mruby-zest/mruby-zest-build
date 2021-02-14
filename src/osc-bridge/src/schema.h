#ifndef OSC_BRIDGE_SCHEMA
#define OSC_BRIDGE_SCHEMA
//OSC Schema

//Options for an enumerated parameter
typedef struct {
    int         *ids;      //Integer mapping of values (num_opts long)
    const char **labels;   //Text labels of values (num_opts long)
    unsigned     num_opts; //Number of options
} opt_t;

//Schema handle
typedef struct {
    //Note: all pointers are dynamically allocated here
    int   flag;
    opt_t *opts;
    const char *pattern;
    const char *name;
    const char *short_name;
    const char *units;
    const char *documentation;
    const char *scale;
    const char *default_;
    char  type;
    float value_min;
    float value_max;
} schema_handle_t;

//Schema instance
typedef struct {
    char            *json;     //Raw JSON
    schema_handle_t *handles;  //Array of parsed handles
    int              elements; //Array len
} schema_t;

typedef const char *uri_t;
typedef const char *str_t;

/**
 * Returns a schema handle which matches the provided uri
 *
 * Returns an invalid handle if no matching handle exists
 */
schema_handle_t sm_get(schema_t, uri_t u);

// Get field from handle or "" when no value was specified
str_t sm_get_name(schema_handle_t);
str_t sm_get_short(schema_handle_t);
str_t sm_get_tooltip(schema_handle_t);
str_t sm_get_units(schema_handle_t);
float sm_get_min_flt(schema_handle_t);
float sm_get_max_flt(schema_handle_t);

//Verify that handle contains valid data
int sm_valid(schema_handle_t);
#endif
