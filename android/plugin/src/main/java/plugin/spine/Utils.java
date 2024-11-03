package plugin.spine;

abstract class Utils extends LuaUtils {
    static int clamp(int value, int min, int max) {
        if (value > max) {
            return max;
        } else if (value < min) {
            return min;
        } else {
            return value;
        }
    }

    static double clamp(double value, double min, double max) {
        if (value > max) {
            return max;
        } else if (value < min) {
            return min;
        } else {
            return value;
        }
    }
}
