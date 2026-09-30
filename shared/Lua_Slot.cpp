#include "Lua_Slot.h"
#include "Lua_Bone.h"
#include "Lua_Attachment.h"
#include "Lua_Skin.h"
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
    else if (strcmp(key, "a") == 0 || strcmp(key, "alpha") == 0)
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
#if SPINE_43()
    else if (strcmp(key, "appliedAttachment") == 0)
    {
        // the applied pose's attachment, the one the renderer draws: a slider can key it apart from slot.attachment
        Attachment *attachment = spc::applied(slot).getAttachment();
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
#endif
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
    else if (strcmp(key, "darkColor") == 0)
    {
        // the slot's float dark colour, nil for a slot without one (fixed by its SlotData for the slot's lifetime)
        if (!spc::applied(slot).hasDarkColor())
        {
            lua_pushnil(L);
            return 1;
        }
        lua_createtable(L, 0, 3);
        Color dark = spc::applied(slot).getDarkColor();
        lua_pushstring(L, "r");
        lua_pushnumber(L, dark.r);
        lua_settable(L, -3);
        lua_pushstring(L, "g");
        lua_pushnumber(L, dark.g);
        lua_settable(L, -3);
        lua_pushstring(L, "b");
        lua_pushnumber(L, dark.b);
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

// slot:setAttachmentFromSkin(skin, attachmentName)
// Returns: the slot
static int setAttachmentFromSkin(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    slotUserdata->checkAlive(L);

    Slot &slot = *slotUserdata->slot;
    Skin *skin = luaL_checkSkinArg(L, 2, &spc::data(slot.getSkeleton()));
    const char *attachmentName = luaL_checkstring(L, 3);

    Attachment *attachment = skin->getAttachment(slot.getData().getIndex(), attachmentName);
    if (!attachment)
        return luaL_error(L, "Attachment '%s' not found in skin '%s' for slot '%s'", attachmentName,
                          skin->getName().buffer(), slot.getData().getName().buffer());

    spc::pose(slot).setAttachment(attachment);
    lua_settop(L, 1);
    return 1;
}

// Readable keys that slot_newindex does not write.
static const char *const readOnlyKeys[] = {"name", "bone", NULL};

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
    else if (strcmp(key, "a") == 0 || strcmp(key, "alpha") == 0)
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
    else if (strcmp(key, "darkColor") == 0)
    {
        return luaL_error(L, "SpineSlot: property 'darkColor' is read-only; the skeleton data and its animations set it");
    }
#if SPINE_43()
    else if (strcmp(key, "appliedAttachment") == 0)
    {
        return luaL_error(L, "SpineSlot: property 'appliedAttachment' is read-only; it is the attachment the renderer draws — set slot.attachment");
    }
#endif

    for (const char *const *readOnly = readOnlyKeys; *readOnly; readOnly++)
    {
        if (strcmp(key, *readOnly) == 0)
            return luaL_error(L, "SpineSlot: property '%s' is read-only", key);
    }
    return luaL_error(L, "SpineSlot: unknown property '%s'", key);
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

// slot:getSkinAttachments([skin]): without a skin, the applied skin or else the default skin.
static int getSkinAttachments(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");

    slotUserdata->checkAlive(L);

    Slot &slot = *slotUserdata->slot;
    SkeletonData *skeletonData = &spc::data(slot.getSkeleton());
    Skin *skin = lua_isnoneornil(L, 2) ? slot.getSkeleton().getSkin() : luaL_checkSkinArg(L, 2, skeletonData);
    if (!skin)
    {
        skin = skeletonData->getDefaultSkin();
    }

    // return a table with all the attachments available in the skin
    lua_newtable(L);

    if (!skin)
    {
        return 1;
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

// With no skin, enumerate effective lookup entries: current skin first, then
// default entries not shadowed by the current skin. A skin argument selects exactly that skin.
static int getAttachmentEntries(lua_State *L)
{
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");
    slotUserdata->checkAlive(L);
    Skeleton &skeleton = slotUserdata->slot->getSkeleton();
    bool explicitSkin = !lua_isnoneornil(L, 2);
    Skin *skin = explicitSkin ? luaL_checkSkinArg(L, 2, &spc::data(skeleton)) : skeleton.getSkin();

    lua_newtable(L);
    std::set<std::string> seen;
    Skin *sources[] = {skin, explicitSkin ? nullptr : spc::data(skeleton).getDefaultSkin()};
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
            lua_pushstring(L, slotUserdata->slot->getData().getName().buffer());
            lua_setfield(L, -2, "slotName");
            lua_pushstring(L, spc::entryName(entry).buffer());
            lua_setfield(L, -2, "placeholder");
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

// Same native slot of the same skeleton instance; raises if either skeleton was removed (D7).
static int slot_eq(lua_State *L)
{
    LuaSlot *a = (LuaSlot *)luaL_checkudata(L, 1, "SpineSlot");
    LuaSlot *b = (LuaSlot *)luaL_checkudata(L, 2, "SpineSlot");
    a->checkAlive(L);
    b->checkAlive(L);
    lua_pushboolean(L, a->slot == b->slot && a->alive == b->alive);
    return 1;
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

        lua_pushcfunction(L, slot_eq);
        lua_setfield(L, -2, "__eq");
    }
}
