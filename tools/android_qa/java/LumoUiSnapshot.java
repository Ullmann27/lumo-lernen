import java.io.File;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * Read-only snapshot of the emulator's actual accessibility hierarchy.
 * Uses the same on-device AOSP bridge and serializer as `uiautomator dump`,
 * but does not require all accessibility events to stop for a full second.
 * It cannot touch controls, alter an app, or write outside a unique QA path.
 */
public final class LumoUiSnapshot {
    private static Object invoke(Object target, String method) throws Exception {
        return target.getClass().getMethod(method).invoke(target);
    }

    private static String errorText(Throwable error) {
        while (error instanceof InvocationTargetException && error.getCause() != null) {
            error = error.getCause();
        }
        return error.getClass().getSimpleName() + ": " + String.valueOf(error.getMessage());
    }

    public static void main(String[] args) {
        Object bridge = null;
        boolean connected = false;
        int exitCode = 2;
        try {
            if (args.length != 1 || !args[0].matches("/sdcard/lumo-ui-[0-9a-f]{32}\\.xml")) {
                throw new IllegalArgumentException("One unique /sdcard/lumo-ui-UUID.xml path is required");
            }
            File output = new File(args[0]);
            if (output.exists()) {
                throw new IllegalArgumentException("Refusing to reuse an existing hierarchy file");
            }
            Class<?> bridgeClass = Class.forName("com.android.uiautomator.core.UiAutomationShellWrapper");
            bridge = bridgeClass.getConstructor().newInstance();
            invoke(bridge, "connect");
            connected = true;
            bridgeClass.getMethod("setCompressedLayoutHierarchy", boolean.class).invoke(bridge, true);
            Object automation = invoke(bridge, "getUiAutomation");
            Method activeRoot = automation.getClass().getMethod("getRootInActiveWindow");
            Object root = null;
            // A fresh connection can precede the first active root. Retry reads
            // for a bounded period without scrolling, tapping or changing time.
            for (int attempt = 0; attempt < 10 && root == null; attempt++) {
                root = activeRoot.invoke(automation);
                if (root == null) Thread.sleep(100);
            }
            if (root == null) throw new IllegalStateException("No active accessibility root");
            Class<?> managerClass = Class.forName("android.hardware.display.DisplayManagerGlobal");
            Object manager = managerClass.getMethod("getInstance").invoke(null);
            Object display = managerClass.getMethod("getRealDisplay", int.class).invoke(manager, 0);
            if (display == null) throw new IllegalStateException("No active display");
            int rotation = ((Integer) invoke(display, "getRotation")).intValue();
            Class<?> pointClass = Class.forName("android.graphics.Point");
            Object point = pointClass.getConstructor().newInstance();
            display.getClass().getMethod("getSize", pointClass).invoke(display, point);
            int width = pointClass.getField("x").getInt(point);
            int height = pointClass.getField("y").getInt(point);
            if (width <= 0 || height <= 0) throw new IllegalStateException("Empty active display");
            Class<?> nodeClass = Class.forName("android.view.accessibility.AccessibilityNodeInfo");
            Class<?> dumperClass = Class.forName("com.android.uiautomator.core.AccessibilityNodeInfoDumper");
            dumperClass.getMethod("dumpWindowToFile", nodeClass, File.class,
                    int.class, int.class, int.class).invoke(null, root, output, rotation, width, height);
            // The AOSP serializer logs IO failures instead of throwing; the
            // fresh path must really have been written before reporting success.
            if (!output.isFile() || output.length() == 0) {
                throw new IllegalStateException("The live serializer did not produce a hierarchy");
            }
            System.out.println("LUMO_UI_SNAPSHOT schema=1 idle_wait=none width=" + width + " height=" + height);
            System.out.println("UI hierchary dumped to: " + output.getAbsolutePath());
            exitCode = 0;
        } catch (Throwable error) {
            System.err.println("LUMO_UI_SNAPSHOT_ERROR " + errorText(error));
        } finally {
            if (connected) {
                try {
                    invoke(bridge, "disconnect");
                } catch (Throwable error) {
                    System.err.println("LUMO_UI_SNAPSHOT_DISCONNECT_ERROR " + errorText(error));
                    exitCode = 2;
                }
            }
        }
        // Do not leave the bridge's handler thread or shell process alive.
        System.exit(exitCode);
    }
}
