package plugin.spine;

import android.graphics.Bitmap;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Log;

import com.ansca.corona.CoronaActivity;
import com.ansca.corona.CoronaEnvironment;
import com.ansca.corona.CoronaLua;
import com.ansca.corona.CoronaRuntime;
import com.ansca.corona.CoronaRuntimeTask;
import com.ansca.corona.storage.FileContentProvider;
import com.naef.jnlua.JavaFunction;
import com.naef.jnlua.LuaRuntimeException;
import com.naef.jnlua.LuaState;
import com.naef.jnlua.LuaType;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;

abstract class LuaUtils {
    static String PHASE_KEY = "phase";
    static String IS_ERROR_KEY = "isError";
    static String ERROR_CODE_KEY = "errorCode";
    static String ERROR_MESSAGE_KEY = "errorMessage";
    private static String TAG = "debug";
    private static boolean isDebug = false;

    static void setTag(String tag) {
        TAG = tag;
    }

    static void enableDebug() {
        isDebug = true;
    }

    static void debugLog(String message) {
        if (isDebug) {
            Log.d(TAG, message);
        }
    }

    static void log(String message) {
        Log.w(TAG, message);
    }

    static void checkArgCount(LuaState L, int countExact) {
        int count = L.getTop();
        if (count != countExact) {
            throw new LuaRuntimeException("This function requires " + countExact + " arguments. Got " + count + ".");
        }
    }

    static void checkArgCount(LuaState L, int countFrom, int countTo) {
        int count = L.getTop();
        if ((count < countFrom) || (count > countTo)) {
            throw new LuaRuntimeException(
                    "This function requires from " + countFrom + " to " + countTo + " arguments. Got " + count + ".");
        }
    }

    static void deleteRefIfNotNil(LuaState L, int ref) {
        if ((ref != CoronaLua.REFNIL) && (ref != CoronaLua.NOREF)) {
            CoronaLua.deleteRef(L, ref);
        }
    }

    static void put(Hashtable<Object, Object> hastable, String key, Object value) {
        if (value != null) {
            hastable.put(key, value);
        }
    }

    static Hashtable<Object, Object> newEvent(String name) {
        Hashtable<Object, Object> event = new Hashtable<>();
        event.put("name", name);
        return event;
    }

    static void dispatchEvent(final int listener, final Hashtable<Object, Object> event) {
        dispatchEvent(listener, event, false);
    }

    static void dispatchEvent(final Integer listener, final Hashtable<Object, Object> event, final boolean deleteRef) {
        if ((listener == null) || (listener == CoronaLua.REFNIL) || (listener == CoronaLua.NOREF)) {
            return;
        }
        CoronaRuntimeTask task = new CoronaRuntimeTask() {
            public void executeUsing(CoronaRuntime runtime) {
                LuaState L = runtime.getLuaState();
                pushHashtable(L, event);
                try {
                    CoronaLua.dispatchEvent(L, listener, 0);
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
                if (deleteRef) {
                    deleteRefIfNotNil(L, listener);
                }
            }
        };
        CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
        if (activity != null) {
            activity.getRuntimeTaskDispatcher().send(task);
        }
    }

    static void setJavaFunctionAsField(LuaState L, String name, JavaFunction function) {
        L.pushJavaFunction(function);
        L.setField(-2, name);
    }

    static String pathForFile(LuaState L, String filename, LuaLightuserdata baseDir) {
        if ((filename != null) && baseDir != null) {
            L.getGlobal("system");
            L.getField(-1, "pathForFile");
            L.pushString(filename);
            L.getField(-3, baseDirToString(baseDir.pointer));
            L.call(2, 1); // Call system.pathForFile() with 2 arguments and 1 return value.
            String path = L.toString(-1);
            L.pop(1);
            return path;
        }
        return null;
    }

    static class Dirs {
        static String ResourceDirectory = "ResourceDirectory";
        static String DocumentsDirectory = "DocumentsDirectory";
        static String CachesDirectory = "CachesDirectory";
        static String TemporaryDirectory = "TemporaryDirectory";
        static long resourceDirectoryPointer;
        static long documentsDirectoryPointer;
        static long cachesDirectoryPointer;
        static long temporaryDirectoryPointer;
    }

    static String baseDirToString(long baseDir) {
        if (baseDir == Dirs.resourceDirectoryPointer) {
            return Dirs.ResourceDirectory;
        } else if (baseDir == Dirs.documentsDirectoryPointer) {
            return Dirs.DocumentsDirectory;
        } else if (baseDir == Dirs.cachesDirectoryPointer) {
            return Dirs.CachesDirectory;
        } else if (baseDir == Dirs.temporaryDirectoryPointer) {
            return Dirs.TemporaryDirectory;
        }
        return null;
    }

    static void getDirPointers(LuaState L) {
        L.getGlobal("system");

        L.getField(-1, Dirs.ResourceDirectory);
        Dirs.resourceDirectoryPointer = L.toPointer(-1);
        L.pop(1);

        L.getField(-1, Dirs.DocumentsDirectory);
        Dirs.documentsDirectoryPointer = L.toPointer(-1);
        L.pop(1);

        L.getField(-1, Dirs.CachesDirectory);
        Dirs.cachesDirectoryPointer = L.toPointer(-1);
        L.pop(1);

        L.getField(-1, Dirs.TemporaryDirectory);
        Dirs.temporaryDirectoryPointer = L.toPointer(-1);
        L.pop(1);

        L.pop(1);
    }

    static void pushBaseDir(LuaState L, Long baseDirPointer) {
        L.getGlobal("system");

        if (baseDirPointer == Dirs.resourceDirectoryPointer) {
            L.getField(-1, Dirs.ResourceDirectory);
        } else if (baseDirPointer == Dirs.documentsDirectoryPointer) {
            L.getField(-1, Dirs.DocumentsDirectory);
        } else if (baseDirPointer == Dirs.cachesDirectoryPointer) {
            L.getField(-1, Dirs.CachesDirectory);
        } else if (baseDirPointer == Dirs.temporaryDirectoryPointer) {
            L.getField(-1, Dirs.TemporaryDirectory);
        } else {
            L.pushNil();
        }

        L.remove(-2);
    }

    static Bitmap getBitmap(LuaState L, String filename, LuaLightuserdata baseDir) {
        Bitmap bitmap = null;
        CoronaActivity activity = CoronaEnvironment.getCoronaActivity();
        if (activity != null) {
            try {
                bitmap = MediaStore.Images.Media.getBitmap(activity.getContentResolver(),
                        FileContentProvider.createContentUriForFile(activity, Utils.pathForFile(L, filename, baseDir)));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return bitmap;
    }

    static class LuaLightuserdata {
        long pointer;

        LuaLightuserdata(long pointer) {
            this.pointer = pointer;
        }
    }

    static class LuaValue {
        int reference = CoronaLua.REFNIL;

        LuaValue(LuaState L, int index) {
            reference = CoronaLua.newRef(L, index);
        }

        void delete(LuaState L) {
            if (reference != CoronaLua.REFNIL) {
                CoronaLua.deleteRef(L, reference);
            }
        }
    }

    interface LuaPushable {
        void push(LuaState L);
    }

    static class Table {
        private LuaState L;
        private int index;
        private Hashtable<Object, Object> hashtable;
        private Scheme scheme;

        Table(LuaState L, int index) {
            this.L = L;
            this.index = index;
        }

        Table parse(Scheme scheme) {
            this.scheme = scheme;
            hashtable = toHashtable(L, index, null);
            return this;
        }

        Boolean getBoolean(String path, Boolean defaultValue) {
            Boolean result = getBoolean(path);
            if (result != null) {
                return result;
            } else {
                return defaultValue;
            }
        }

        Boolean getBoolean(String path) {
            if ((get(path) != null) && (get(path) instanceof Boolean)) {
                return (Boolean) get(path);
            } else {
                return null;
            }
        }

        String getString(String path, String defaultValue) {
            String result = getString(path);
            if (result != null) {
                return result;
            } else {
                return defaultValue;
            }
        }

        String getString(String path) {
            if ((get(path) != null) && (get(path) instanceof String)) {
                return (String) get(path);
            } else {
                return null;
            }
        }

        String getStringNotNull(String path) {
            String result = getString(path);
            if (result != null) {
                return result;
            } else {
                throw new LuaRuntimeException("ERROR: Table's property '" + path + "' is not a string.");
            }
        }

        Double getDouble(String path, double defaultValue) {
            Double result = getDouble(path);
            if (result != null) {
                return result;
            } else {
                return defaultValue;
            }
        }

        Double getDouble(String path) {
            if ((get(path) != null) && (get(path) instanceof Double)) {
                return (Double) get(path);
            } else {
                return null;
            }
        }

        Double getDoubleNotNull(String path) {
            Double result = getDouble(path);
            if (result != null) {
                return result;
            } else {
                throw new LuaRuntimeException("ERROR: Table's property '" + path + "' is not a number.");
            }
        }

        Integer getInteger(String path, int defaultValue) {
            Integer result = getInteger(path);
            if (result != null) {
                return result;
            } else {
                return defaultValue;
            }
        }

        Integer getInteger(String path) {
            if ((get(path) != null) && (get(path) instanceof Double)) {
                return ((Double) get(path)).intValue();
            } else {
                return null;
            }
        }

        Integer getIntegerNotNull(String path) {
            Integer result = getInteger(path);
            if (result != null) {
                return result;
            } else {
                throw new LuaRuntimeException("ERROR: Table's property '" + path + "' is not a number.");
            }
        }

        Long getLong(String path, long defaultValue) {
            Long result = getLong(path);
            if (result != null) {
                return result;
            } else {
                return defaultValue;
            }
        }

        Long getLong(String path) {
            if ((get(path) != null) && (get(path) instanceof Double)) {
                return ((Double) get(path)).longValue();
            } else {
                return null;
            }
        }

        Long getLongNotNull(String path) {
            Long result = getLong(path);
            if (result != null) {
                return result;
            } else {
                throw new LuaRuntimeException("ERROR: Table's property '" + path + "' is not a number.");
            }
        }

        byte[] getByteArray(String path, byte[] defaultValue) {
            byte[] result = getByteArray(path);
            if (result != null) {
                return result;
            } else {
                return defaultValue;
            }
        }

        byte[] getByteArray(String path) {
            if ((get(path) != null) && (get(path) instanceof byte[])) {
                return (byte[]) get(path);
            } else {
                return null;
            }
        }

        byte[] getByteArrayNotNull(String path) {
            byte[] result = getByteArray(path);
            if (result != null) {
                return result;
            } else {
                throw new LuaRuntimeException("ERROR: Table's property '" + path + "' is not a byte array.");
            }
        }

        LuaLightuserdata getLightuserdata(String path, Long defaultValue) {
            LuaLightuserdata result = getLightuserdata(path);
            if (result != null) {
                return result;
            } else {
                return new LuaLightuserdata(defaultValue);
            }
        }

        LuaLightuserdata getLightuserdata(String path) {
            if ((get(path) != null) && (get(path) instanceof LuaLightuserdata)) {
                return (LuaLightuserdata) get(path);
            } else {
                return null;
            }
        }

        LuaLightuserdata getLightuserdataNull(String path) {
            LuaLightuserdata result = getLightuserdata(path);
            if (result != null) {
                return result;
            } else {
                throw new LuaRuntimeException("ERROR: Table's property '" + path + "' is not a lightuserdata.");
            }
        }

        Integer getListener(String path, Integer defaultValue) {
            Integer result = getListener(path);
            if (result != null) {
                return result;
            } else {
                return defaultValue;
            }
        }

        Integer getListener(String path) {
            if ((get(path) != null) && (get(path) instanceof Integer)) {
                return (Integer) get(path);
            } else {
                return null;
            }
        }

        Hashtable<Object, Object> getTable(String path, Hashtable<Object, Object> defaultValue) {
            Hashtable<Object, Object> result = getTable(path);
            if (result != null) {
                return result;
            } else {
                return defaultValue;
            }
        }

        @SuppressWarnings("unchecked")
        Hashtable<Object, Object> getTable(String path) {
            if ((get(path) != null) && (get(path) instanceof Hashtable)) {
                return (Hashtable<Object, Object>) get(path);
            } else {
                return null;
            }
        }

        Object get(String path) {
            if (path.isEmpty()) {
                return hashtable;
            } else {
                Object current = null;
                for (String p : path.split("\\.")) {
                    if (current == null) {
                        current = hashtable.get(p);
                    } else if (current instanceof Hashtable) {
                        Hashtable h = (Hashtable) current;
                        current = h.get(p);
                    }
                }
                return current;
            }
        }

        private Object toValue(LuaState L, int index, ArrayList<String> pathList) {
            if ((index < 0) && (index > LuaState.REGISTRYINDEX)) {
                index = L.getTop() + index + 1;
            }
            Object o = null;
            if (scheme == null) {
                switch (L.type(index)) {
                    case STRING:
                        o = L.toString(index);
                        break;
                    case NUMBER:
                        o = L.toNumber(index);
                        break;
                    case BOOLEAN:
                        o = L.toBoolean(index);
                        break;
                    case LIGHTUSERDATA:
                        o = new LuaLightuserdata(L.toPointer(index));
                        break;
                    case TABLE:
                        o = toHashtable(L, index, pathList);
                        break;
                }
            } else {
                String path = TextUtils.join(".", pathList);
                Object rule = scheme.get(path);
                switch (L.type(index)) {
                    case STRING:
                        if (rule == LuaType.STRING) {
                            o = L.toString(index);
                        } else if (rule == Scheme.LuaTypeNumeric) {
                            String value = L.toString(index);
                            boolean isNumeric = true;
                            try {
                                Double.parseDouble(value); // Not ignored
                            } catch (NumberFormatException e) {
                                isNumeric = false;
                            }
                            if (isNumeric) {
                                o = value;
                            }
                        } else if (rule == Scheme.LuaTypeByteArray) {
                            o = L.toByteArray(index);
                        }
                        break;
                    case NUMBER:
                        if ((rule == LuaType.NUMBER) || (rule == Scheme.LuaTypeNumeric)) {
                            o = L.toNumber(index);
                        }
                        break;
                    case BOOLEAN:
                        if (rule == LuaType.BOOLEAN) {
                            o = L.toBoolean(index);
                        }
                        break;
                    case LIGHTUSERDATA:
                        if (rule == LuaType.LIGHTUSERDATA) {
                            o = new LuaLightuserdata(L.toPointer(index));
                        }
                        break;
                    case USERDATA:
                        if (rule == LuaType.USERDATA) {
                            o = L.toPointer(index);
                        }
                        break;
                    case FUNCTION:
                        if (rule == LuaType.FUNCTION) {
                            o = CoronaLua.newRef(L, index);
                        } else if (rule instanceof String[]) {
                            String[] ruleArray = (String[]) rule;
                            if (ruleArray[0].equals("listener")) {
                                o = CoronaLua.newRef(L, index);
                            }
                        }
                        break;
                    case TABLE:
                        if (rule == LuaType.TABLE) {
                            o = toHashtable(L, index, pathList);
                        } else if (rule instanceof String[]) {
                            String[] ruleArray = (String[]) rule;
                            if ((ruleArray[0].equals("listener")) && (CoronaLua.isListener(L, index, ruleArray[1]))) {
                                o = CoronaLua.newRef(L, index);
                            }
                        }
                }
            }
            return o;
        }

        private Hashtable<Object, Object> toHashtable(LuaState L, int index, ArrayList<String> pathList) {
            if ((index < 0) && (index > LuaState.REGISTRYINDEX)) {
                index = L.getTop() + index + 1;
            }

            Hashtable<Object, Object> result = new Hashtable<>();
            L.checkType(index, LuaType.TABLE);
            L.pushNil();

            ArrayList<String> path = pathList != null ? pathList : new ArrayList<String>();
            for (; L.next(index); L.pop(1)) {
                Object key = null;
                if (L.type(-2) == LuaType.STRING) {
                    key = L.toString(-2);
                    path.add((String) key);
                } else if (L.type(-2) == LuaType.NUMBER) {
                    key = L.toNumber(-2);
                    path.add("#");
                }
                if (key != null) {
                    Object value = toValue(L, -1, path);
                    if (value != null) {
                        result.put(key, value);
                    }
                    path.remove(path.size() - 1);
                }
            }

            return result;
        }
    }

    static class Scheme {
        Hashtable<String, Object> scheme = new Hashtable<>();

        final static Integer LuaTypeNumeric = 1000;
        final static Integer LuaTypeByteArray = 1001;

        Scheme string(String path) {
            scheme.put(path, LuaType.STRING);
            return this;
        }

        Scheme number(String path) {
            scheme.put(path, LuaType.NUMBER);
            return this;
        }

        Scheme bool(String path) {
            scheme.put(path, LuaType.BOOLEAN);
            return this;
        }

        Scheme table(String path) {
            scheme.put(path, LuaType.TABLE);
            return this;
        }

        Scheme function(String path) {
            scheme.put(path, LuaType.FUNCTION);
            return this;
        }

        Scheme listener(String path) {
            String[] split = path.split("\\.");
            this.listener(path, split[split.length - 1]);
            return this;
        }

        Scheme listener(String path, String eventName) {
            scheme.put(path, new String[] { "listener", eventName });
            return this;
        }

        Scheme lightuserdata(String path) {
            scheme.put(path, LuaType.LIGHTUSERDATA);
            return this;
        }

        Scheme userdata(String path) {
            scheme.put(path, LuaType.USERDATA);
            return this;
        }

        Scheme numeric(String path) {
            scheme.put(path, LuaTypeNumeric);
            return this;
        }

        Scheme byteArray(String path) {
            scheme.put(path, LuaTypeByteArray);
            return this;
        }

        Object get(String path) {
            return scheme.get(path);
        }
    }

    @SuppressWarnings("unchecked")
    static void pushValue(LuaState L, Object object) {
        if (object instanceof String) {
            L.pushString((String) object);
        } else if (object instanceof Integer) {
            L.pushInteger((Integer) object);
        } else if (object instanceof Long) {
            L.pushNumber(((Long) object).doubleValue());
        } else if (object instanceof Double) {
            L.pushNumber((Double) object);
        } else if (object instanceof Boolean) {
            L.pushBoolean((Boolean) object);
        } else if (object instanceof byte[]) {
            L.pushString((byte[]) object);
        } else if (object instanceof LuaLightuserdata) {
            pushBaseDir(L, ((LuaLightuserdata) object).pointer);
        } else if (object instanceof LuaValue) {
            LuaValue value = (LuaValue) object;
            L.ref(value.reference);
            value.delete(L);
        } else if (object instanceof LuaPushable) {
            ((LuaPushable) object).push(L);
        } else if (object instanceof List) {
            Hashtable<Object, Object> hashtable = new Hashtable<>();
            int i = 1;
            for (Object o : (List) object) {
                hashtable.put(i, o);
            }
            pushHashtable(L, hashtable);
        } else if (object instanceof Hashtable) {
            pushHashtable(L, (Hashtable) object);
        } else {
            L.pushNil();
        }
    }

    public static void pushHashtable(LuaState L, Hashtable<Object, Object> hashtable) {
        if (hashtable == null) {
            L.newTable();
        } else {
            L.newTable(0, hashtable.size());
            int tableIndex = L.getTop();
            for (Object o : hashtable.entrySet()) {
                Map.Entry entry = (Map.Entry) o;
                pushValue(L, entry.getKey());
                pushValue(L, entry.getValue());
                L.setTable(tableIndex);
            }
        }
    }
}
