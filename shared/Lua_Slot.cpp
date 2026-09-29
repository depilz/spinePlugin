#include "Lua_Slot.h"
#include "Lua_Bone.h"
#include "Lua_Attachment.h"
#include <set>
#include <string>

static int slot_index(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    const char *key = luaL_checkstring(L, 2);

    slotUserdata->checkAlive(L);
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
        new (boneUserdata) LuaBone(L, &slot.getBone(), &slot.getSkeleton(), slotUserdata->alive);

        return 1;
    }
    else if (strcmp(key, "attachment") == 0)
    {
        Attachment *attachment = spc::pose(slot).getAttachment();
        if (!attachment)
        {
            lua_pushnil(L);
        }
        else
        {
            LuaAttachment *attachmentUserdata = (LuaAttachment *)lua_newuserdata(L, sizeof(LuaAttachment));
            new (attachmentUserdata) LuaAttachment(L, attachment, slotUserdata->dataOwner);
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
    else if (strcmp(key, "attachmentLocked") == 0)
    {
        lua_pushboolean(L, slot.isAttachmentLocked());
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
    // Check if it's nil - clear attachment
    if (lua_isnil(L, 3))
    {
        spc::pose(*slotUserdata->slot).setAttachment(nullptr);
        return;
    }

    // Check if it's a LuaAttachment userdata
    if (lua_isuserdata(L, 3))
    {
        // Manually check if it's the correct type by checking the metatable
        if (lua_getmetatable(L, 3))
        {
            luaL_getmetatable(L, "SpineAttachment");
            if (lua_rawequal(L, -1, -2))
            {
                // It's a SpineAttachment userdata
                lua_pop(L, 2); // Pop both metatables
                LuaAttachment *attachmentUserdata = (LuaAttachment *)lua_touserdata(L, 3);
                if (attachmentUserdata && attachmentUserdata->attachment)
                {
                    if (attachmentUserdata->dataOwner != slotUserdata->dataOwner)
                        luaL_argerror(L, 3, "Attachment belongs to different skeleton data");
                    spc::pose(*slotUserdata->slot).setAttachment(attachmentUserdata->attachment);
                    return;
                }
            }
            else
            {
                lua_pop(L, 2); // Pop both metatables
            }
        }
    }

    // Otherwise, treat it as a string (attachment name from current/default skin)
    const char *attachmentName = luaL_checkstring(L, 3);

    Slot &slot = *slotUserdata->slot;
    int slotIndex = slot.getData().getIndex();
    
    Attachment *attachment = slot.getSkeleton().getAttachment(slotIndex, attachmentName);
    if (!attachment)
    {
        luaL_error(L, "Attachment not found: %s", attachmentName);
        return;
    }

    spc::pose(*slotUserdata->slot).setAttachment(attachment);
}

// slot:setAttachmentFromSkin(skinName, attachmentName)
// Returns: boolean success
static int setAttachmentFromSkin(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    slotUserdata->checkAlive(L);
    if (!slotUserdata->slot)
    {
        lua_pushboolean(L, false);
        return 1;
    }

    const char *skinName = luaL_checkstring(L, 2);
    const char *attachmentName = luaL_checkstring(L, 3);

    Slot &slot = *slotUserdata->slot;
    int slotIndex = slot.getData().getIndex();

    // Find the specified skin
    Skin *skin = spc::data(slot.getSkeleton()).findSkin(skinName);
    if (!skin)
    {
        fprintf(stderr, "WARNING: Skin not found: %s\n", skinName);
        lua_pushboolean(L, false);
        return 1;
    }

    // Get the attachment from the skin
    Attachment *attachment = skin->getAttachment(slotIndex, attachmentName);
    if (!attachment)
    {
        fprintf(stderr, "WARNING: Attachment \"%s\" not found in skin \"%s\"\n", attachmentName, skinName);
        lua_pushboolean(L, false);
        return 1;
    }

    spc::pose(slot).setAttachment(attachment);
    lua_pushboolean(L, true);
    return 1;
}

static int slot_newindex(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    slotUserdata->checkAlive(L);
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

        return 0;
    }
    else if (strcmp(key, "attachmentLocked") == 0)
    {
        bool locked = lua_toboolean(L, 3);
        slotUserdata->slot->setAttachmentLocked(locked);
        return 0;
    }

    return 0;
}

static int getAttachments(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    slotUserdata->checkAlive(L);
    if (!slotUserdata->slot)
    {
        return 0;
    }

    Slot &slot = *slotUserdata->slot;

    // return a table with all the attachments available in all the skins
    lua_newtable(L);

    int i = 1;
    SkeletonData *skeletonData = &spc::data(slot.getSkeleton());

    for (int skinIndex = 0; skinIndex < skeletonData->getSkins().size(); ++skinIndex)
    {
        Skin *skin = skeletonData->getSkins()[skinIndex];

        Vector<Attachment *> attachments;
        skin->findAttachmentsForSlot(slot.getData().getIndex(), attachments);

        for (int attachmentIndex = 0; attachmentIndex < attachments.size(); ++attachmentIndex)
        {
            Attachment *attachment = attachments[attachmentIndex];

            LuaAttachment *attachmentUserdata = (LuaAttachment *)lua_newuserdata(L, sizeof(LuaAttachment));
            new (attachmentUserdata) LuaAttachment(L, attachment, slotUserdata->dataOwner);
            lua_rawseti(L, -2, i++);
        }

        attachments.clear();
    }

    return 1;
}

static int getSkinAttachments(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");
    const char *skinName = luaL_optstring(L, 2, NULL);

    slotUserdata->checkAlive(L);
    if (!slotUserdata->slot)
    {
        return 0;
    }

    Slot &slot = *slotUserdata->slot;

    // return a table with all the attachments available in the skin
    lua_newtable(L);

    SkeletonData *skeletonData = &spc::data(slot.getSkeleton());
    Skin *skin = skinName ? skeletonData->findSkin(skinName) : slot.getSkeleton().getSkin();
    if (!skinName && !skin)
    {
        skin = skeletonData->getDefaultSkin();
    }

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

        LuaAttachment *attachmentUserdata = (LuaAttachment *)lua_newuserdata(L, sizeof(LuaAttachment));
        new (attachmentUserdata) LuaAttachment(L, attachment, slotUserdata->dataOwner);
        lua_rawseti(L, -2, i++);
    }

    attachments.clear();

    return 1;
}

// With no name, enumerate effective lookup entries: current skin first, then
// default entries not shadowed by the current skin. A name selects exactly one skin.
static int getAttachmentEntries(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");
    slotUserdata->checkAlive(L);
    const char *skinName = luaL_optstring(L, 2, nullptr);
    Skeleton &skeleton = slotUserdata->slot->getSkeleton();
    Skin *skin = skinName ? spc::data(skeleton).findSkin(skinName) : skeleton.getSkin();
    if (skinName && !skin) return 0;

    lua_newtable(L);
    std::set<std::string> seen;
    Skin *sources[] = {skin, skinName ? nullptr : spc::data(skeleton).getDefaultSkin()};
    int index = 1;
    int slotIndex = slotUserdata->slot->getData().getIndex();
    for (Skin *source : sources)
    {
        if (!source) continue;
        auto entries = source->getAttachments();
        while (entries.hasNext())
        {
            auto &entry = entries.next();
            if (entry._slotIndex != slotIndex || !seen.insert(spc::entryName(entry).buffer()).second) continue;
            lua_createtable(L, 0, 4);
            lua_pushinteger(L, slotIndex);
            lua_setfield(L, -2, "slotIndex");
            lua_pushstring(L, spc::entryName(entry).buffer());
            lua_setfield(L, -2, "name");
            lua_pushstring(L, source->getName().buffer());
            lua_setfield(L, -2, "skinName");
            auto *attachment = (LuaAttachment *)lua_newuserdata(L, sizeof(LuaAttachment));
            new (attachment) LuaAttachment(L, entry._attachment, slotUserdata->dataOwner);
            lua_setfield(L, -2, "attachment");
            lua_rawseti(L, -2, index++);
        }
    }
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

        lua_pushcfunction(L, getAttachmentEntries);
        lua_setfield(L, -2, "getAttachmentEntries");

        lua_pushcfunction(L, getSkinAttachments);
        lua_setfield(L, -2, "getSkinAttachments");

        lua_pushcfunction(L, setAttachmentFromSkin);
        lua_setfield(L, -2, "setAttachmentFromSkin");

        lua_pushcfunction(L, slot_gc);
        lua_setfield(L, -2, "__gc");
    }
}
