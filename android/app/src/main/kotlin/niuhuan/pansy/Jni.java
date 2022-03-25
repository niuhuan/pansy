package niuhuan.pansy;

public class Jni {

    public static native void setRoot(final String path);

    static {
        System.loadLibrary("native");
    }

}
