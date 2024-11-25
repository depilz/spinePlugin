#include "LuaUtils.h"
#include "CoronaLua.h"
#include "CoronaMacros.h"
#include <iostream>
#include <cassert>

std::string LuaUtils::TAG = "plugin";
bool LuaUtils::isDebug = false;
lua_State* LuaUtils::_L = nullptr;
std::vector<LuaTask*> LuaUtils::tasks;

const std::string LuaUtils::ResourceDirectory = "ResourceDirectory";
const std::string LuaUtils::DocumentsDirectory = "DocumentsDirectory";
const std::string LuaUtils::CachesDirectory = "CachesDirectory";
const std::string LuaUtils::TemporaryDirectory = "TemporaryDirectory";

void LuaUtils::setTag(const std::string& tag) {
    TAG = tag;
}

void LuaUtils::enableDebug() {
    isDebug = true;
}

void LuaUtils::debugLog(const std::string& message) {
    if (isDebug) {
        std::cout << TAG << ": " << message << std::endl;
    }
}

void LuaUtils::log(const std::string& message) {
    std::cout << TAG << ": " << message << std::endl;
}

void LuaUtils::checkArgCount(lua_State* L, int countExact) {
    int count = lua_gettop(L);
    assertCondition(count == countExact, "This function requires " + std::to_string(countExact) + " arguments. Got " + std::to_string(count) + ".");
}

void LuaUtils::checkArgCount(lua_State* L, int countFrom, int countTo) {
    int count = lua_gettop(L);
    assertCondition(count >= countFrom && count <= countTo, "This function requires from " + std::to_string(countFrom) + " to " + std::to_string(countTo) + " arguments. Got " + std::to_string(count) + ".");
}

void LuaUtils::assertCondition(bool condition, const std::string& message) {
    if (!condition) {
        luaL_error(_L, message.c_str());
    }
}

void LuaUtils::pushHashtable(lua_State *L, const std::map<std::string, std::any> &hashtable)
{
    lua_newtable(L);
    int tableIndex = lua_gettop(L);
    for (const auto &pair : hashtable)
    {
        pushValue(L, pair.first);
        pushValue(L, pair.second);
        lua_settable(L, tableIndex);
    }
}

void LuaUtils::pushValue(lua_State *L, const std::any &object)
{
    if (!object.has_value())
    {
        lua_pushnil(L);
    }
    else if (object.type() == typeid(std::string))
    {
        lua_pushstring(L, std::any_cast<std::string>(object).c_str());
    }
    else if (object.type() == typeid(const char *))
    {
        lua_pushstring(L, std::any_cast<const char *>(object));
    }
    else if (object.type() == typeid(char *))
    {
        lua_pushstring(L, std::any_cast<char *>(object));
    }
    else if (object.type() == typeid(int))
    {
        lua_pushinteger(L, std::any_cast<int>(object));
    }
    else if (object.type() == typeid(short))
    {
        lua_pushinteger(L, static_cast<int>(std::any_cast<short>(object)));
    }
    else if (object.type() == typeid(long))
    {
        lua_pushnumber(L, static_cast<double>(std::any_cast<long>(object)));
    }
    else if (object.type() == typeid(long long))
    {
        lua_pushnumber(L, static_cast<double>(std::any_cast<long long>(object)));
    }
    else if (object.type() == typeid(float))
    {
        lua_pushnumber(L, static_cast<double>(std::any_cast<float>(object)));
    }
    else if (object.type() == typeid(double))
    {
        lua_pushnumber(L, std::any_cast<double>(object));
    }
    else if (object.type() == typeid(bool))
    {
        lua_pushboolean(L, std::any_cast<bool>(object));
    }
    else if (object.type() == typeid(std::vector<char>))
    {
        const std::vector<char> &data = std::any_cast<std::vector<char>>(object);
        lua_pushlstring(L, data.data(), data.size());
    }
    else if (object.type() == typeid(std::vector<uint8_t>))
    {
        const std::vector<uint8_t> &data = std::any_cast<std::vector<uint8_t>>(object);
        lua_pushlstring(L, reinterpret_cast<const char *>(data.data()), data.size());
    }
    // else if (object.type() == typeid(LuaPushable *))
    // {
    //     std::any_cast<LuaPushable *>(object)->push(L);
    // }
    else if (object.type() == typeid(std::vector<std::any>))
    {
        const std::vector<std::any> &arr = std::any_cast<std::vector<std::any>>(object);
        std::map<std::string, std::any> hashtable;
        int i = 1;
        for (const auto &o : arr)
        {
            hashtable[std::to_string(i)] = o;
            i++;
        }
        pushHashtable(L, hashtable);
    }
    else if (object.type() == typeid(std::map<std::string, std::any>))
    {
        pushHashtable(L, std::any_cast<std::map<std::string, std::any>>(object));
    }
    else
    {
        luaL_error(L, "LuaUtils.pushValue(): failed to push an object: unknown type %s", object.type().name());
    }
}

std::map<std::string, std::any> LuaUtils::newEvent(const std::string& name) {
    std::map<std::string, std::any> event;
    event["name"] = name;
    return event;
}

void LuaUtils::dispatchEvent(int listener, const std::map<std::string, std::any>& event) {
    dispatchEvent(listener, event, false);
}

void LuaUtils::dispatchEvent(int listener, const std::map<std::string, std::any>& event, bool deleteRef) {
    if ((listener == LUA_REFNIL) || (listener == LUA_NOREF)) {
        return;
    }
    LuaTask* task = new LuaTask();
    task->listener = listener;
    task->event = event;
    task->delete_ref = deleteRef;
    tasks.push_back(task);
}

std::string LuaUtils::pathForFile(lua_State* L, const std::string& filename, const std::string& baseDir) {
    if (!filename.empty() && !baseDir.empty()) {
        lua_getglobal(L, "system");
        lua_getfield(L, -1, "pathForFile");
        lua_pushstring(L, filename.c_str());
        lua_getfield(L, -3, baseDir.c_str());
        lua_call(L, 2, 1);  // Call system.pathForFile() with 2 arguments and 1 return value.
        std::string path = lua_tostring(L, -1);
        lua_pop(L, 1);
        return path;
    }
    return "";
}

void LuaUtils::executeTasks(lua_State* L) {
    _L = L;
    while (!tasks.empty()) {
        LuaTask* task = tasks.front();
		lua_rawgeti(L, LUA_REGISTRYINDEX, task->listener);
		pushHashtable(L, task->event);
        lua_call(L, 1, 0);
        if (task->delete_ref) {
			luaL_unref(L, LUA_REGISTRYINDEX, task->listener);
        }
        tasks.erase(tasks.begin());
        delete task;
    }
}

LuaTask::LuaTask() : listener(LUA_REFNIL), delete_ref(false) {}
