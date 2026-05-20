.class Lnet/kdt/pojavlaunch/RootHelper$2;
.super Ljava/lang/Object;
.source "RootHelper.java"

# UI thread runnable: shows Toast + Log.d after 2.5s delay
.implements Ljava/lang/Runnable;

# instance fields
.field final synthetic val$context:Landroid/content/Context;
.field final synthetic val$message:Ljava/lang/String;


# direct methods
.method public constructor <init>(Landroid/content/Context;Ljava/lang/String;)V
    .locals 0

    iput-object p1, p0, Lnet/kdt/pojavlaunch/RootHelper$2;->val$context:Landroid/content/Context;
    iput-object p2, p0, Lnet/kdt/pojavlaunch/RootHelper$2;->val$message:Ljava/lang/String;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 4

    :try_start
    # This runs on the main UI thread after 2.5s delay via Handler.postDelayed

    # Log.d("POJAV_CLONE", "Showing delayed Toast: " + message)
    const-string v0, "POJAV_CLONE"
    const-string v1, "showToast: now executing on UI thread"
    invoke-static {v0, v1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    # Toast.makeText(context, message, Toast.LENGTH_LONG).show()
    iget-object v0, p0, Lnet/kdt/pojavlaunch/RootHelper$2;->val$context:Landroid/content/Context;
    iget-object v1, p0, Lnet/kdt/pojavlaunch/RootHelper$2;->val$message:Ljava/lang/String;

    # Toast.LENGTH_LONG = 1
    const/4 v2, 0x1
    invoke-static {v0, v1, v2}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;
    move-result-object v0
    invoke-virtual {v0}, Landroid/widget/Toast;->show()V

    # Log.d("POJAV_CLONE", "Toast.makeText().show() called successfully")
    const-string v0, "POJAV_CLONE"
    const-string v1, "Toast.makeText().show() completed"
    invoke-static {v0, v1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :catch_ex

    :catch_ex
    move-exception v0
    # Log.e("POJAV_CLONE", "Toast display failed", exception)
    const-string v1, "POJAV_CLONE"
    const-string v2, "Toast display FAILED"
    invoke-static {v1, v2, v0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method
