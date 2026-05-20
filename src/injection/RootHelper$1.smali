.class Lnet/kdt/pojavlaunch/RootHelper$1;
.super Ljava/lang/Object;
.source "RootHelper.java"

# Background thread: checks root, then schedules delayed Toast on UI thread
.implements Ljava/lang/Runnable;

# instance fields
.field final synthetic val$context:Landroid/content/Context;


# direct methods
.method public constructor <init>(Landroid/content/Context;)V
    .locals 0

    iput-object p1, p0, Lnet/kdt/pojavlaunch/RootHelper$1;->val$context:Landroid/content/Context;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 7

    # v0 = context
    # v1 = rootResult (Z/int)
    # v2 = message (String)
    # v3 = Handler
    # v4 = Runnable
    # v5,v6 = delay 2500ms (wide)

    iget-object v0, p0, Lnet/kdt/pojavlaunch/RootHelper$1;->val$context:Landroid/content/Context;

    # Call checkRootAndSetOOM() on background thread
    invoke-static {}, Lnet/kdt/pojavlaunch/RootHelper;->checkRootAndSetOOM()Z
    move-result v1

    # Determine toast message
    if-eqz v1, :no_root
    const-string v2, "Root Active: OOM_ADJ Injected"
    goto :schedule_toast
    :no_root
    const-string v2, "Standard Non-Root Mode"
    :schedule_toast

    # Log.d("POJAV_CLONE", message)
    const-string v3, "POJAV_CLONE"
    invoke-static {v3, v2}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    # Create Handler(Looper.getMainLooper())
    new-instance v3, Landroid/os/Handler;
    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;
    move-result-object v4
    invoke-direct {v3, v4}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    # Create RootHelper$2(context, message) - the delayed toast + log runnable
    new-instance v4, Lnet/kdt/pojavlaunch/RootHelper$2;
    invoke-direct {v4, v0, v2}, Lnet/kdt/pojavlaunch/RootHelper$2;-><init>(Landroid/content/Context;Ljava/lang/String;)V

    # Handler.postDelayed(runnable, 2500ms)
    # 2500 decimal = 0x9C4 hex, fits in signed 16-bit
    const-wide/16 v5, 0x9C4
    invoke-virtual {v3, v4, v5, v6}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

    const-string v3, "POJAV_CLONE"
    const-string v4, "Toast scheduled with 2500ms delay"
    invoke-static {v3, v4}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    return-void
.end method
