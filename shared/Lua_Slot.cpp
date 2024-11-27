#include "Lua_Slot.h"

static int slot_index(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    const char *key = luaL_checkstring(L, 2);

    if (!slotUserdata->slot)
    {
        luaL_error(L, "Attempt to index a destroyed slot");
        return 1;
    }

    Slot &slot = *slotUserdata->slot;

    if (strcmp(key, "name") == 0)
    {
        lua_pushstring(L, slot.getData().getName().buffer());
        return 1;
    }
    else if (strcmp(key, "x") == 0)
    {
        lua_pushnumber(L, slot.getBone().getWorldX());
        return 1;
    }
    else if (strcmp(key, "y") == 0)
    {
        lua_pushnumber(L, -slot.getBone().getWorldY());
        return 1;
    }
    else if (strcmp(key, "rotation") == 0)
    {
        lua_pushnumber(L, -slot.getBone().getWorldRotationX());
        return 1;
    }
    else if (strcmp(key, "xScale") == 0)
    {
        lua_pushnumber(L, slot.getBone().getWorldScaleX());
        return 1;
    }
    else if (strcmp(key, "yScale") == 0)
    {
        lua_pushnumber(L, slot.getBone().getWorldScaleY());
        return 1;
    }
    else if (strcmp(key, "r") == 0)
    {
        lua_pushnumber(L, slot.getColor().r);
        return 1;
    }
    else if (strcmp(key, "g") == 0)
    {
        lua_pushnumber(L, slot.getColor().g);
        return 1;
    }
    else if (strcmp(key, "b") == 0)
    {
        lua_pushnumber(L, slot.getColor().b);
        return 1;
    }
    else if (strcmp(key, "alpha") == 0)
    {
        lua_pushnumber(L, slot.getColor().a);
        return 1;
    }
    else if (strcmp(key, "bone") == 0)
    {
        lua_pushstring(L, slot.getBone().getData().getName().buffer());
        return 1;
    }
    else if (strcmp(key, "attachment") == 0)
    {
        Attachment *attachment = slot.getAttachment();
        if (!attachment)
        {
            lua_pushnil(L);
        }
        else
        {
            const char *attachmentName = attachment->getName().buffer();
            lua_pushstring(L, attachmentName);
        }
        return 1;
    }
    else if (strcmp(key, "color") == 0)
    {
        lua_createtable(L, 0, 4);
        Color color = slot.getColor();
        lua_pushstring(L, "r");
        lua_pushnumber(L, color.r);
        lua_settable(L, -3);
        lua_pushstring(L, "g");
        lua_pushnumber(L, color.g);
        lua_settable(L, -3);
        lua_pushstring(L, "b");
        lua_pushnumber(L, color.b);
        lua_settable(L, -3);
        lua_pushstring(L, "a");
        lua_pushnumber(L, color.a);
        lua_settable(L, -3);
        return 1;
    }

    return 0;
}

static int slot_newindex(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    const char *key = luaL_checkstring(L, 2);

    if (strcmp(key, "x") == 0)
    {
        float x = luaL_checknumber(L, 3);
        slotUserdata->slot->getBone().setX(x);
        return 0;
    }
    else if (strcmp(key, "y") == 0)
    {
        float y = luaL_checknumber(L, 3);
        slotUserdata->slot->getBone().setY(-y);
        return 0;
    }
    else if (strcmp(key, "rotation") == 0)
    {
        float rotation = luaL_checknumber(L, 3);
        slotUserdata->slot->getBone().setRotation(-rotation);
        return 0;
    }
    else if (strcmp(key, "xScale") == 0)
    {
        float xScale = luaL_checknumber(L, 3);
        slotUserdata->slot->getBone().setScaleX(xScale);
        return 0;
    }
    else if (strcmp(key, "yScale") == 0)
    {
        float yScale = luaL_checknumber(L, 3);
        slotUserdata->slot->getBone().setScaleY(yScale);
        return 0;
    }
    else if (strcmp(key, "alpha") == 0)
    {
        float alpha = luaL_checknumber(L, 3);
        slotUserdata->slot->getColor().a = alpha;
        return 0;
    }
    else if (strcmp(key, "r") == 0)
    {
        float r = luaL_checknumber(L, 3);
        slotUserdata->slot->getColor().r = r;
        return 0;
    }
    else if (strcmp(key, "g") == 0)
    {
        float g = luaL_checknumber(L, 3);
        slotUserdata->slot->getColor().g = g;
        return 0;
    }
    else if (strcmp(key, "b") == 0)
    {
        float b = luaL_checknumber(L, 3);
        slotUserdata->slot->getColor().b = b;
        return 0;
    }
    else if (strcmp(key, "alpha") == 0)
    {
        float alpha = luaL_checknumber(L, 3);
        slotUserdata->slot->getColor().a = alpha;

        return 0;
    }
    else if (strcmp(key, "attachment") == 0)
    {
        const char *attachmentName = luaL_checkstring(L, 3);

        if (strcmp(attachmentName, "null") == 0)
        {
            slotUserdata->slot->setAttachment(nullptr);
            return 0;
        }

        Attachment *attachment = slotUserdata->slot->getSkeleton().getAttachment(slotUserdata->slot->getData().getIndex(), attachmentName);
        if (!attachment)
        {
            slotUserdata->slot->setAttachment(nullptr);
            return 0;
        }

        slotUserdata->slot->setAttachment(attachment);

        return 0;
    }

    return 0;
}

static int slot_gc(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    delete slotUserdata;

    return 0;
}

void getSlotMt(lua_State *L)
{
    luaL_getmetatable(L, "SpineSlot");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "SpineSlot");

        lua_pushstring(L, "__index");
        lua_pushcfunction(L, slot_index);
        lua_settable(L, -3);

        lua_pushstring(L, "__newindex");
        lua_pushcfunction(L, slot_newindex);
        lua_settable(L, -3);

        lua_pushcfunction(L, slot_gc);
        lua_setfield(L, -2, "__gc");
    }
}