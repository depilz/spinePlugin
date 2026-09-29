#include "Lua_Slot.h"
#include "Lua_Bone.h"

static int slot_index(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    const char *key = luaL_checkstring(L, 2);

    if (!slotUserdata->slot)
    {
        return 0;
    }

    Slot &slot = *slotUserdata->slot;

    if (strcmp(key, "name") == 0)
    {
        lua_pushstring(L, slot.getData().getName().buffer());
        return 1;
    }
    else if (strcmp(key, "r") == 0)
    {
        lua_pushnumber(L, slot.getSolarColor().r);
        return 1;
    }
    else if (strcmp(key, "g") == 0)
    {
        lua_pushnumber(L, slot.getSolarColor().g);
        return 1;
    }
    else if (strcmp(key, "b") == 0)
    {
        lua_pushnumber(L, slot.getSolarColor().b);
        return 1;
    }
    else if (strcmp(key, "alpha") == 0)
    {
        lua_pushnumber(L, slot.getSolarColor().a);
        return 1;
    }
    else if (strcmp(key, "bone") == 0)
    {
        LuaBone *boneUserdata = (LuaBone *)lua_newuserdata(L, sizeof(LuaBone));
        new (boneUserdata) LuaBone(L, &slot.getBone());
        lua_getfenv(L, 1); // 1.2.6: same anchor as the parent wrapper (pins the skeleton)
        lua_setfenv(L, -2);

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
        Color color = slot.getSolarColor();
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

    // fallback to methods
    lua_getmetatable(L, 1);
    lua_pushvalue(L, 2);
    lua_rawget(L, -2);
    if (!lua_isnil(L, -1))
    {
        return 1;
    }

    return 0;
}

static void setAttachment(lua_State *L, LuaSlot *slotUserdata)
{
    const char *attachmentName = luaL_checkstring(L, 3);

    if (strcmp(attachmentName, "null") == 0)
    {
        slotUserdata->slot->setAttachment(nullptr);
        return;
    }

    Slot &slot = *slotUserdata->slot;
    int slotIndex = slot.getData().getIndex();
    
    Skin *skin;
    spine::String attachmentNameStr;

    // does the attachment name includes the skin name?
    const char *skinName = strchr(attachmentName, '/');

    if (skinName)
    {
        spine::String fullStr(attachmentName);
        int skinNameLength = static_cast<int>(skinName - attachmentName);
        spine::String skinNameStr = fullStr.substring(0, skinNameLength);

        skin = slotUserdata->slot->getSkeleton().getData()->findSkin(skinNameStr);
        if (!skin)
        {
            printf("Skin not found: %s\n", skinNameStr.buffer());
            return;
        }

        attachmentNameStr = fullStr.substring(skinNameLength + 1);
    }
    else
    {
        skin = slotUserdata->slot->getSkeleton().getData()->getDefaultSkin();
        attachmentNameStr = attachmentName;
    }

    Attachment *attachment = skin->getAttachment(slotIndex, attachmentNameStr);

    if (!attachment)
    {
        printf("Attachment \"%s\" not found in skin \"%s\"\n", attachmentName, skin->getName().buffer());
        return;
    }

    slotUserdata->slot->setAttachment(attachment);
}

static int slot_newindex(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    if (!slotUserdata->slot)
    {
        return 0;
    }

    const char *key = luaL_checkstring(L, 2);

    if (strcmp(key, "r") == 0)
    {
        float r = luaL_checknumber(L, 3);
        slotUserdata->slot->getSolarColor().r = r;
        return 0;
    }
    else if (strcmp(key, "g") == 0)
    {
        float g = luaL_checknumber(L, 3);
        slotUserdata->slot->getSolarColor().g = g;
        return 0;
    }
    else if (strcmp(key, "b") == 0)
    {
        float b = luaL_checknumber(L, 3);
        slotUserdata->slot->getSolarColor().b = b;
        return 0;
    }
    else if (strcmp(key, "alpha") == 0)
    {
        float alpha = luaL_checknumber(L, 3);
        slotUserdata->slot->getSolarColor().a = alpha;

        return 0;
    }
    else if (strcmp(key, "attachment") == 0)
    {
        setAttachment(L, slotUserdata);

        return 0;
    }
    else if (strcmp(key, "color") == 0)
    {
        luaL_checktype(L, 3, LUA_TTABLE);

        Color &color = slotUserdata->slot->getSolarColor();

        lua_getfield(L, 3, "r");
        if (lua_isnumber(L, -1))
        {
            color.r = lua_tonumber(L, -1);
        }
        lua_pop(L, 1);

        lua_getfield(L, 3, "g");
        if (lua_isnumber(L, -1))
        {
            color.g = lua_tonumber(L, -1);
        }
        lua_pop(L, 1);

        lua_getfield(L, 3, "b");
        if (lua_isnumber(L, -1))
        {
            color.b = lua_tonumber(L, -1);
        }
        lua_pop(L, 1);

        lua_getfield(L, 3, "a");
        if (lua_isnumber(L, -1))
        {
            color.a = lua_tonumber(L, -1);
        }
        lua_pop(L, 1);

        printf("Set slot color: %f %f %f %f\n", color.r, color.g, color.b, color.a);

        return 0;
    }

    return 0;
}

static int getAttachments(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    if (!slotUserdata->slot)
    {
        return 0;
    }

    Slot &slot = *slotUserdata->slot;

    // return a table with all the attachments available in all the skins
    lua_newtable(L);

    int i = 1;
    SkeletonData *skeletonData = slot.getSkeleton().getData();

    for (int skinIndex = 0; skinIndex < skeletonData->getSkins().size(); ++skinIndex)
    {
        Skin *skin = skeletonData->getSkins()[skinIndex];

        Vector<Attachment *> attachments;
        skin->findAttachmentsForSlot(slot.getData().getIndex(), attachments);

        for (int attachmentIndex = 0; attachmentIndex < attachments.size(); ++attachmentIndex)
        {
            Attachment *attachment = attachments[attachmentIndex];

            lua_pushstring(L, attachment->getName().buffer());
            lua_rawseti(L, -2, i++);
        }

        attachments.clear();
    }

    return 1;
}

static int getSkinAttachments(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");
    const char *skinName = luaL_checkstring(L, 2);

    if (!slotUserdata->slot)
    {
        return 0;
    }

    Slot &slot = *slotUserdata->slot;

    // return a table with all the attachments available in the skin
    lua_newtable(L);

    SkeletonData *skeletonData = slot.getSkeleton().getData();
    Skin *skin = skeletonData->findSkin(skinName);

    if (!skin)
    {
        return 0;
    }

    int i = 1;
    Vector<Attachment *> attachments;
    skin->findAttachmentsForSlot(slot.getData().getIndex(), attachments);

    for (int attachmentIndex = 0; attachmentIndex < attachments.size(); ++attachmentIndex)
    {
        Attachment *attachment = attachments[attachmentIndex];

        lua_pushstring(L, attachment->getName().buffer());
        lua_rawseti(L, -2, i++);
    }

    attachments.clear();

    return 1;
}

static int slot_gc(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    slotUserdata->~LuaSlot();

    return 0;
}

void getSlotMt(lua_State *L)
{
    if (luaL_newmetatable(L, "SpineSlot"))
    {
        lua_pushcfunction(L, slot_index);
        lua_setfield(L, -2, "__index");

        lua_pushcfunction(L, slot_newindex);
        lua_setfield(L, -2, "__newindex");

        lua_pushcfunction(L, getAttachments);
        lua_setfield(L, -2, "getAttachments");

        lua_pushcfunction(L, getSkinAttachments);
        lua_setfield(L, -2, "getSkinAttachments");

        lua_pushcfunction(L, slot_gc);
        lua_setfield(L, -2, "__gc");
    }
}
