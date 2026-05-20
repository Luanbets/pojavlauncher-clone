.class public Lnet/kdt/pojavlaunch/RootHelper;
.super Ljava/lang/Object;
.source "RootHelper.java"


# direct methods
.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

# performRootInit(Context)
# Entry point - launches background thread for root check
# Called from MainActivity.onCreate AFTER super.onCreate
.method public static performRootInit(Landroid/content/Context;)V
    .locals 2

    # Log.d("POJAV_CLONE", "performRootInit called")
    const-string v0, "POJAV_CLONE"
    const-string v1, "performRootInit: launching root check thread"
    invoke-static {v0, v1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    # new Thread(new RootHelper$1(context)).start()
    new-instance v0, Ljava/lang/Thread;
    new-instance v1, Lnet/kdt/pojavlaunch/RootHelper$1;
    invoke-direct {v1, p0}, Lnet/kdt/pojavlaunch/RootHelper$1;-><init>(Landroid/content/Context;)V
    invoke-direct {v0, v1}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;)V
    invoke-virtual {v0}, Ljava/lang/Thread;->start()V

    return-void
.end method

# checkRootAndSetOOM() -> boolean
# Must run on background thread. Checks root, sets oom_score_adj=-17.
.method public static checkRootAndSetOOM()Z
    .locals 8

    const/4 v0, 0x0

    :try_start_root
    # Log.d("POJAV_CLONE", "Root check: executing su -c id")
    const-string v1, "POJAV_CLONE"
    const-string v2, "Root check: executing su -c id"
    invoke-static {v1, v2}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    invoke-static {}, Ljava/lang/Runtime;->getRuntime()Ljava/lang/Runtime;
    move-result-object v1
    const-string v2, "su -c id"
    invoke-virtual {v1, v2}, Ljava/lang/Runtime;->exec(Ljava/lang/String;)Ljava/lang/Process;
    move-result-object v1

    # Read stdout
    invoke-virtual {v1}, Ljava/lang/Process;->getInputStream()Ljava/io/InputStream;
    move-result-object v2
    new-instance v3, Ljava/io/BufferedReader;
    new-instance v4, Ljava/io/InputStreamReader;
    invoke-direct {v4, v2}, Ljava/io/InputStreamReader;-><init>(Ljava/io/InputStream;)V
    invoke-direct {v3, v4}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V
    invoke-virtual {v3}, Ljava/io/BufferedReader;->readLine()Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v3}, Ljava/io/BufferedReader;->close()V

    # Wait with 5-second timeout
    const-wide/16 v3, 0x1388
    invoke-virtual {v1, v3, v4}, Ljava/lang/Process;->waitFor(JI)Z

    # Check if uid=0
    if-eqz v2, :no_root
    const-string v3, "uid=0"
    invoke-virtual {v2, v3}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v2
    if-eqz v2, :no_root

    # Root confirmed
    const/4 v0, 0x1
    const-string v1, "POJAV_CLONE"
    const-string v2, "Root detected! Setting OOM_ADJ=-17"
    invoke-static {v1, v2}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    # Set OOM_ADJ to -17: su -c 'echo -17 > /proc/<pid>/oom_score_adj'
    :try_start_oom
    invoke-static {}, Landroid/os/Process;->myPid()I
    move-result v1

    new-instance v2, Ljava/lang/StringBuilder;
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V
    const-string v3, "su -c \'echo -17 > /proc/"
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    move-result-object v2
    invoke-static {v1}, Ljava/lang/String;->valueOf(I)Ljava/lang/String;
    move-result-object v3
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    move-result-object v2
    const-string v3, "/oom_score_adj\'"
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    move-result-object v2
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v2

    const-string v3, "POJAV_CLONE"
    invoke-static {v3, v2}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    invoke-static {}, Ljava/lang/Runtime;->getRuntime()Ljava/lang/Runtime;
    move-result-object v3
    invoke-virtual {v3, v2}, Ljava/lang/Runtime;->exec(Ljava/lang/String;)Ljava/lang/Process;
    move-result-object v3
    const-wide/16 v4, 0x1388
    invoke-virtual {v3, v4, v5}, Ljava/lang/Process;->waitFor(JI)Z
    :try_end_oom
    .catch Ljava/lang/Exception; {:try_start_oom .. :try_end_oom} :catch_oom

    goto :oom_done

    :catch_oom
    move-exception v1
    const-string v2, "POJAV_CLONE"
    const-string v3, "OOM_ADJ set failed (non-fatal)"
    invoke-static {v2, v3, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    :oom_done
    goto :root_done

    :no_root
    const/4 v0, 0x0
    const-string v1, "POJAV_CLONE"
    const-string v2, "Root NOT detected - will run in standard mode"
    invoke-static {v1, v2}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    :root_done
    return v0

    :try_end_root
    .catch Ljava/lang/Exception; {:try_start_root .. :try_end_root} :catch_root

    :catch_root
    move-exception v1
    const-string v2, "POJAV_CLONE"
    const-string v3, "Root check threw exception"
    invoke-static {v2, v3, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I
    const/4 v0, 0x0

    return v0
.end method
