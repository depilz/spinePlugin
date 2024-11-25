#pragma once

#include <string>
#include <vector>
#include <map>
#include <any>
#include <iostream>
#include <cassert>

#include "CoronaLua.h"
#include "CoronaMacros.h"

class LuaTask;
class Table;
class Scheme;

class LuaUtils {
public:
    static std::string TAG;
    static bool isDebug;
    static lua_State* _L;
    static std::vector<LuaTask*> tasks;

    static const std::string ResourceDirectory;
    static const std::string DocumentsDirectory;
    static const std::string CachesDirectory;
    static const std::string TemporaryDirectory;

    static void setTag(const std::string& tag);
    static void enableDebug();
    static void debugLog(const std::string& message);
    static void log(const std::string& message);
    static void assertCondition(bool condition, const std::string& message);
    static void checkArgCount(lua_State* L, int countExact);
    static void checkArgCount(lua_State* L, int countFrom, int countTo);
    static void pushValue(lua_State *L, const std::any &object);
    static void pushHashtable(lua_State *L, const std::map<std::string, std::any> &hashtable);
    static std::map<std::string, std::any> newEvent(const std::string& name);
    static void dispatchEvent(int listener, const std::map<std::string, std::any>& event);
    static void dispatchEvent(int listener, const std::map<std::string, std::any>& event, bool deleteRef);
    static std::string pathForFile(lua_State* L, const std::string& filename, const std::string& baseDir);
    static void executeTasks(lua_State* L);

private:
    LuaUtils() = delete;
};

class LuaTask {
public:
    int listener;
    std::map<std::string, std::any> event;
    bool delete_ref;

    LuaTask();
};

class Table {
public:
    Table(lua_State* L, int index);
    void parse(Scheme* scheme);

private:
    lua_State* _L;
    int _index;
    std::map<std::string, std::any> _hashtable;
    Scheme* _scheme;
};

class Scheme {
public:
    Scheme();
    void any(const std::string& path);
    void string(const std::string& path);
    void number(const std::string& path);
    void boolean(const std::string& path);
    void table(const std::string& path);
    void function(const std::string& path);
    void listener(const std::string& path);
    void listener(const std::string& path, const std::string& eventName);
    void userdata(const std::string& path);
    void numeric(const std::string& path);
    void byteArray(const std::string& path);
    std::any get(const std::string& path);

    int LuaTypeNumeric;
    int LuaTypeByteArray;
    int LuaTypeAny;

private:
    std::map<std::string, std::any> scheme;
};

