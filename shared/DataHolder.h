#pragma once
#include "CoronaLua.h"
#include <memory>

namespace spine
{
    class Atlas;
    class SkeletonData;
}

template <typename T>
class DataHolder
{
public:
    DataHolder(T *object);
    ~DataHolder();

    static void push(lua_State *L, const std::shared_ptr<DataHolder<T>> &holder);

    static std::shared_ptr<DataHolder<T>> check(lua_State *L, int index);

    T *getObject() const { return object_; }

private:
    // Each holder type has its own registry metatable, named after T, so check() rejects another type's userdata.
    static const char *metatableName();
    static void pushMetatable(lua_State *L);
    static int gc(lua_State *L);

    T *object_;
};

template <typename T>
DataHolder<T>::DataHolder(T *object)
    : object_(object)
{
}

template <typename T>
DataHolder<T>::~DataHolder()
{
    delete object_;
}

template <typename T>
int DataHolder<T>::gc(lua_State *L)
{
    auto *userdata = static_cast<std::shared_ptr<DataHolder<T>> *>(lua_touserdata(L, 1));
    if (userdata)
    {
        userdata->~shared_ptr();
    }
    return 0;
}

// The metatable names are repeated as literals in pushMetatable: tests/api/surface.py reads each owner from
// the literal luaL_newmetatable name.
template <>
inline const char *DataHolder<spine::Atlas>::metatableName() { return "Atlas"; }

template <>
inline void DataHolder<spine::Atlas>::pushMetatable(lua_State *L)
{
    if (luaL_newmetatable(L, "Atlas"))
    {
        lua_pushcfunction(L, gc);
        lua_setfield(L, -2, "__gc");
    }
}

template <>
inline const char *DataHolder<spine::SkeletonData>::metatableName() { return "SkeletonData"; }

template <>
inline void DataHolder<spine::SkeletonData>::pushMetatable(lua_State *L)
{
    if (luaL_newmetatable(L, "SkeletonData"))
    {
        lua_pushcfunction(L, gc);
        lua_setfield(L, -2, "__gc");
    }
}

template <typename T>
void DataHolder<T>::push(lua_State *L, const std::shared_ptr<DataHolder<T>> &holder)
{
    void *userdata = lua_newuserdata(L, sizeof(std::shared_ptr<DataHolder<T>>));
    new (userdata) std::shared_ptr<DataHolder<T>>(holder); // Placement new

    pushMetatable(L);
    lua_setmetatable(L, -2);
}

template <typename T>
std::shared_ptr<DataHolder<T>> DataHolder<T>::check(lua_State *L, int index)
{
    auto *userdata = static_cast<std::shared_ptr<DataHolder<T>> *>(luaL_checkudata(L, index, metatableName()));
    if (!userdata)
    {
        luaL_error(L, "Invalid userdata");
    }
    return *userdata;
}
