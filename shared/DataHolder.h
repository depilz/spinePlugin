#pragma once
#include "CoronaLua.h"
#include <memory>

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
void DataHolder<T>::push(lua_State *L, const std::shared_ptr<DataHolder<T>> &holder)
{
    void *userdata = lua_newuserdata(L, sizeof(std::shared_ptr<DataHolder<T>>));
    new (userdata) std::shared_ptr<DataHolder<T>>(holder); // Placement new

    if (luaL_newmetatable(L, "DataHolder"))
    {
        lua_pushcfunction(L, [](lua_State *L) -> int
                          {
            auto* userdata = static_cast<std::shared_ptr<DataHolder<T>>*>(lua_touserdata(L, 1));
            if (userdata) {
                userdata->~shared_ptr();
            }
            return 0; });
        lua_setfield(L, -2, "__gc");
    }
    lua_setmetatable(L, -2);
}

template <typename T>
std::shared_ptr<DataHolder<T>> DataHolder<T>::check(lua_State *L, int index)
{
    auto *userdata = static_cast<std::shared_ptr<DataHolder<T>> *>(luaL_checkudata(L, index, "DataHolder"));
    if (!userdata)
    {
        luaL_error(L, "Invalid userdata");
    }
    return *userdata;
}
