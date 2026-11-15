package android.app

import android.content.pm.PackageManager

/** Synthetic Android boundary. No microphone exists in this JVM fixture. */
class Activity {
    var permission = true
    var permissionRequests = 0
    var requestedCode = 0
    fun checkSelfPermission(permissionName: String): Int =
        if (permission) PackageManager.PERMISSION_GRANTED else PackageManager.PERMISSION_DENIED
    fun requestPermissions(permissions: Array<String>, code: Int) {
        permissionRequests++
        requestedCode = code
    }
}
