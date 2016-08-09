#include <mruby.h>
#include <mruby/proc.h>
#include <stdlib.h>

struct {
    const char *remote_address;
    const char *widget_selection;
    //Tweaks paths slightly
    int package_mode;
    //Reloads code when a change is detected
    int hotload;
} cmd_arg;

void
parse_arguments(int argc, char **argv)
{
    cmd_arg.remote_address   = "osc.udp://127.0.0.1:1337";
    cmd_arg.widget_selection = "MainWindow";
    cmd_arg.hotload          = 0;
    for(int i=0; i<argc; ++i) {
        if(!strcmp("--hotload", argv[i]))
            cmd_arg.hotload = 1;
        if(strstr(argv[i], "osc.udp://") == argv[i])
            cmd_arg.remote_address = argv[i];
    }

    (void) argc;
    (void) argv;
}

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

void
check_glpsol_sanity(void)
{
    printf("[INFO] Checking GLPK Solver...\n");
    FILE *f = fopen("./glpsol", "r");
    if(f) {
        fclose(f);
        f = NULL;
        printf("[INFO] Dist GLPK Found...\n");
        printf("[INFO] Testing GLPK Sanity...\n");
        int ret = system("./glpsol --version");
        printf("[INFO] Got a code %d from glpsol...\n", ret);
        if(ret != 0)
            exit(1);
    } else {
        printf("[INFO] Dist GLPK NOT Found...\n");
    }
}

int
main(int argc, char **argv)
{
    //Parse arguments
    parse_arguments(argc, argv);

    //Verify The System Can Run The Application
    check_glpsol_sanity();

    //Create Interpreter
    printf("[INFO] Creating MRuby Interpreter...\n");
    mrb_state *mrb = mrb_open();

    //Create Callback Object
    struct RClass *hotload = mrb_define_class(mrb, "HotLoad", mrb->object_class);
    mrb_define_method(mrb, hotload, "initialize", dummy_initialize, MRB_ARGS_NONE());
    mrb_define_method(mrb, hotload, "call", load_qml_obj, MRB_ARGS_NONE());
    mrb_value      loader  = mrb_obj_new(mrb, hotload, 0, NULL);

    //Initialize Application Runner
    struct RClass *runner  = mrb_class_get(mrb, "ZRunner");
    mrb_value      runarg  = mrb_str_new_cstr(mrb, cmd_arg.remote_address);
    mrb_value      run     = mrb_obj_new(mrb, runner, 1, &runarg);

    //Set Argument Values
    mrb_funcall(mrb, run, "hotload=", 1, cmd_arg.hotload ? mrb_true_value() : mrb_false_value());

    //Launch the application
    printf("[INFO] Launching MRuby Application...\n");
    mrb_funcall(mrb, run, "doRun", 1, loader);

    //Finalize
    printf("[INFO] Closing MRuby Application...\n");
    mrb_close(mrb);
    return 0;
}
