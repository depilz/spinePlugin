#include "Lua_Skin.h"
#include "Lua_Attachment.h"
#include "Lua_Slot.h"

static LuaSkin *checkSkin(lua_State *L, int index)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, index, "SpineSkin");
    if (!skinUserdata->skin) luaL_argerror(L, index, "Invalid Skin object");
    return skinUserdata;
}

// Every skin mutator and colour write goes through this: data skins are read-only, custom skins are mutable.
static LuaSkin *checkWritableSkin(lua_State *L, int index)
{
    LuaSkin *skinUserdata = checkSkin(L, index);
    if (skinUserdata->isDataSkin())
        luaL_error(L, "Skin '%s' is read-only (a data skin); use skeleton:createSkin() for a mutable skin",
                   skinUserdata->skin->getName().buffer());
    return skinUserdata;
}

Skin *luaL_checkSkinArg(lua_State *L, int argIndex, SkeletonData *skeletonData)
{
    if (lua_type(L, argIndex) == LUA_TSTRING)
    {
        const char *skinName = lua_tostring(L, argIndex);
        Skin *skin = skeletonData ? skeletonData->findSkin(skinName) : nullptr;
        if (!skin) luaL_error(L, "Skin not found: %s", skinName);
        return skin;
    }
    LuaSkin *other = (LuaSkin *)luaL_testudata_compat(L, argIndex, "SpineSkin");
    if (!other) luaL_argerror(L, argIndex, "skin name (string) or Skin object expected");
    if (!other->skin) luaL_argerror(L, argIndex, "Invalid Skin object");
    if (other->skeletonData != skeletonData) luaL_argerror(L, argIndex, "Skin belongs to different skeleton data");
    return other->skin;
}

int luaL_checkSlotArg(lua_State *L, int argIndex, SkeletonData *skeletonData)
{
    if (lua_type(L, argIndex) == LUA_TSTRING)
    {
        const char *slotName = lua_tostring(L, argIndex);
        SlotData *slotData = skeletonData ? skeletonData->findSlot(slotName) : nullptr;
        if (!slotData) luaL_error(L, "Slot not found: %s", slotName);
        return slotData->getIndex();
    }
    LuaSlot *slot = (LuaSlot *)luaL_testudata_compat(L, argIndex, "SpineSlot");
    if (!slot) luaL_argerror(L, argIndex, "slot name (string) or Slot object expected");
    slot->checkAlive(L);
    if (!slot->dataOwner || slot->dataOwner->getObject() != skeletonData)
        luaL_argerror(L, argIndex, "Slot belongs to different skeleton data");
    return slot->slot->getData().getIndex();
}

// Readable keys that skin_newindex does not write.
static const char *const readOnlyKeys[] = {"name", NULL};

static int skin_index(lua_State *L)
{
    LuaSkin *skinUserdata = checkSkin(L, 1);

    const char *key = luaL_checkstring(L, 2);

    Skin &skin = *skinUserdata->skin;

    if (strcmp(key, "name") == 0)
    {
        lua_pushstring(L, skin.getName().buffer());
        return 1;
    }
    else if (strcmp(key, "r") == 0)
    {
        lua_pushnumber(L, skin.getColor().r);
        return 1;
    }
    else if (strcmp(key, "g") == 0)
    {
        lua_pushnumber(L, skin.getColor().g);
        return 1;
    }
    else if (strcmp(key, "b") == 0)
    {
        lua_pushnumber(L, skin.getColor().b);
        return 1;
    }
    else if (strcmp(key, "a") == 0)
    {
        lua_pushnumber(L, skin.getColor().a);
        return 1;
    }
    else if (strcmp(key, "color") == 0)
    {
        lua_createtable(L, 0, 4);
        Color &color = skin.getColor();
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

static int skin_newindex(lua_State *L)
{
    checkSkin(L, 1);

    const char *key = luaL_checkstring(L, 2);

    if (strcmp(key, "r") == 0)
    {
        float r = luaL_checknumber(L, 3);
        checkWritableSkin(L, 1)->skin->getColor().r = r;
        return 0;
    }
    else if (strcmp(key, "g") == 0)
    {
        float g = luaL_checknumber(L, 3);
        checkWritableSkin(L, 1)->skin->getColor().g = g;
        return 0;
    }
    else if (strcmp(key, "b") == 0)
    {
        float b = luaL_checknumber(L, 3);
        checkWritableSkin(L, 1)->skin->getColor().b = b;
        return 0;
    }
    else if (strcmp(key, "a") == 0)
    {
        float a = luaL_checknumber(L, 3);
        checkWritableSkin(L, 1)->skin->getColor().a = a;
        return 0;
    }
    else if (strcmp(key, "color") == 0)
    {
        luaL_checktype(L, 3, LUA_TTABLE);

        Color &color = checkWritableSkin(L, 1)->skin->getColor();

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

    for (const char *const *readOnly = readOnlyKeys; *readOnly; readOnly++)
    {
        if (strcmp(key, *readOnly) == 0)
            return luaL_error(L, "SpineSkin: property '%s' is read-only", key);
    }
    return luaL_error(L, "SpineSkin: unknown property '%s'", key);
}

// skin:addSkin(skinNameOrObject)
// Adds all attachments from another skin (shares references, does not copy)
// Returns: the skin
static int addSkin(lua_State *L)
{
    LuaSkin *skinUserdata = checkWritableSkin(L, 1);

    Skin *otherSkin = luaL_checkSkinArg(L, 2, skinUserdata->skeletonData);

    if (otherSkin != skinUserdata->skin) spc::addSkin(skinUserdata->skin, otherSkin);
    lua_settop(L, 1);
    return 1;
}

// skin:copySkin(skinNameOrObject)
// Deep copies all attachments from another skin
// Returns: the skin
static int copySkin(lua_State *L)
{
    LuaSkin *skinUserdata = checkWritableSkin(L, 1);

    Skin *otherSkin = luaL_checkSkinArg(L, 2, skinUserdata->skeletonData);

    if (otherSkin != skinUserdata->skin) spc::copySkin(skinUserdata->skin, otherSkin);
    lua_settop(L, 1);
    return 1;
}

// skin:getName()
// Returns the name of the skin
static int getName(lua_State *L)
{
    LuaSkin *skinUserdata = checkSkin(L, 1);

    lua_pushstring(L, skinUserdata->skin->getName().buffer());
    return 1;
}

// skin:setAttachment(slot, name, attachment, [sourceSkin])
// Sets an attachment in the skin (shares the object; use attachment:copy() for an own one),
// optionally copying bones/constraints from source skin
// Returns: the skin
static int setAttachment(lua_State *L)
{
    LuaSkin *skinUserdata = checkWritableSkin(L, 1);
    
    int slotIndex = luaL_checkSlotArg(L, 2, skinUserdata->skeletonData);
    
    const char *name = luaL_checkstring(L, 3);
    
    if (!name[0]) return luaL_argerror(L, 3, "Attachment lookup name must not be empty");
    Attachment *attachment = nullptr;
    Skin *sourceSkin = nullptr;
    if (!lua_isnil(L, 4))
    {
        LuaAttachment *value = (LuaAttachment *)luaL_checkudata(L, 4, "SpineAttachment");
        if (!value->attachment) return luaL_argerror(L, 4, "Invalid attachment");
        if (value->dataOwner != skinUserdata->dataOwner)
            return luaL_argerror(L, 4, "Attachment belongs to different skeleton data");
        attachment = value->attachment;
    }

    // Check for optional source skin parameter
    if (!lua_isnoneornil(L, 5)) sourceSkin = luaL_checkSkinArg(L, 5, skinUserdata->skeletonData);
    
    if (attachment)
    {
        skinUserdata->skin->setAttachment(slotIndex, name, attachment);
        
        // If source skin provided, copy its bones and constraints
        if (sourceSkin)
        {
            Vector<BoneData *> &bones = sourceSkin->getBones();
            for (size_t i = 0; i < bones.size(); i++)
            {
                if (!skinUserdata->skin->getBones().contains(bones[i]))
                {
                    skinUserdata->skin->getBones().add(bones[i]);
                }
            }
            
            Vector<ConstraintData *> &constraints = sourceSkin->getConstraints();
            for (size_t i = 0; i < constraints.size(); i++)
            {
                if (!skinUserdata->skin->getConstraints().contains(constraints[i]))
                {
                    skinUserdata->skin->getConstraints().add(constraints[i]);
                }
            }
        }
    }
    else
    {
        skinUserdata->skin->removeAttachment(slotIndex, name);
    }
    
    lua_settop(L, 1);
    return 1;
}

// skin:getAttachment(slot, name)
// Returns a specific attachment from the skin
static int getAttachment(lua_State *L)
{
    LuaSkin *skinUserdata = checkSkin(L, 1);
    
    int slotIndex = luaL_checkSlotArg(L, 2, skinUserdata->skeletonData);
    
    const char *name = luaL_checkstring(L, 3);
    
    Attachment *attachment = skinUserdata->skin->getAttachment(slotIndex, name);
    
    if (!attachment)
    {
        lua_pushnil(L);
        return 1;
    }
    
    LuaAttachment *attachmentUserdata = (LuaAttachment *)lua_newuserdata(L, sizeof(LuaAttachment));
    new (attachmentUserdata) LuaAttachment(L, attachment, skinUserdata->dataOwner);
    
    return 1;
}

// skin:removeAttachment(slot, name)
// Removes an attachment from the skin
// Returns: the skin
static int removeAttachment(lua_State *L)
{
    LuaSkin *skinUserdata = checkWritableSkin(L, 1);
    
    int slotIndex = luaL_checkSlotArg(L, 2, skinUserdata->skeletonData);
    
    const char *name = luaL_checkstring(L, 3);
    
    skinUserdata->skin->removeAttachment(slotIndex, name);
    lua_settop(L, 1);
    return 1;
}

// skin:clear()
// Removes all attachments, bones and constraints from the skin
// Returns: the skin
static int clear(lua_State *L)
{
    Skin *skin = checkWritableSkin(L, 1)->skin;

    // Collect the keys first: removing while iterating would invalidate the entries.
    Vector<size_t> slotIndices;
    Vector<String> names;
    Skin::AttachmentMap::Entries entries = skin->getAttachments();
    while (entries.hasNext())
    {
        Skin::AttachmentMap::Entry &entry = entries.next();
        slotIndices.add(entry._slotIndex);
        names.add(spc::entryName(entry));
    }
    for (size_t i = 0; i < names.size(); i++) skin->removeAttachment(slotIndices[i], names[i]);

    skin->getBones().clear();
    skin->getConstraints().clear();
    lua_settop(L, 1);
    return 1;
}

// skin:findNamesForSlot(slot)
// Returns all attachment names for a specific slot
static int findNamesForSlot(lua_State *L)
{
    LuaSkin *skinUserdata = checkSkin(L, 1);
    
    int slotIndex = luaL_checkSlotArg(L, 2, skinUserdata->skeletonData);
    
    Vector<String> names;
    skinUserdata->skin->findNamesForSlot(slotIndex, names);
    
    lua_createtable(L, static_cast<int>(names.size()), 0);
    for (size_t i = 0; i < names.size(); i++)
    {
        lua_pushstring(L, names[i].buffer());
        lua_rawseti(L, -2, static_cast<int>(i + 1));
    }
    
    return 1;
}

// skin:findAttachmentsForSlot(slot)
// Returns all attachment objects for a specific slot
static int findAttachmentsForSlot(lua_State *L)
{
    LuaSkin *skinUserdata = checkSkin(L, 1);
    
    int slotIndex = luaL_checkSlotArg(L, 2, skinUserdata->skeletonData);
    
    Vector<Attachment *> attachments;
    skinUserdata->skin->findAttachmentsForSlot(slotIndex, attachments);
    
    lua_createtable(L, static_cast<int>(attachments.size()), 0);
    for (size_t i = 0; i < attachments.size(); i++)
    {
        if (attachments[i])
        {
            LuaAttachment *attachmentUserdata = (LuaAttachment *)lua_newuserdata(L, sizeof(LuaAttachment));
            new (attachmentUserdata) LuaAttachment(L, attachments[i], skinUserdata->dataOwner);
        }
        else
        {
            lua_pushnil(L);
        }
        lua_rawseti(L, -2, static_cast<int>(i + 1));
    }
    
    return 1;
}

// skin:getAttachments()
// Returns a table of entry records {slotName, placeholder, attachment}
static int getAttachments(lua_State *L)
{
    LuaSkin *skinUserdata = checkSkin(L, 1);

    lua_newtable(L);
    
    Skin::AttachmentMap::Entries entries = skinUserdata->skin->getAttachments();
    int index = 1;
    
    while (entries.hasNext())
    {
        Skin::AttachmentMap::Entry &entry = entries.next();
        
        lua_newtable(L);
        
        lua_pushstring(L, "slotName");
        lua_pushstring(L, skinUserdata->skeletonData->getSlots()[entry._slotIndex]->getName().buffer());
        lua_settable(L, -3);
        
        lua_pushstring(L, "placeholder");
        lua_pushstring(L, spc::entryName(entry).buffer());
        lua_settable(L, -3);
        
        lua_pushstring(L, "attachment");
        if (entry._attachment)
        {
            LuaAttachment *attachmentUserdata = (LuaAttachment *)lua_newuserdata(L, sizeof(LuaAttachment));
            new (attachmentUserdata) LuaAttachment(L, entry._attachment, skinUserdata->dataOwner);
        }
        else
        {
            lua_pushnil(L);
        }
        lua_settable(L, -3);
        
        lua_rawseti(L, -2, index++);
    }
    
    return 1;
}

// skin:getBones()
// Returns the bones associated with this skin
static int getBones(lua_State *L)
{
    LuaSkin *skinUserdata = checkSkin(L, 1);
    
    Vector<BoneData *> &bones = skinUserdata->skin->getBones();
    lua_createtable(L, static_cast<int>(bones.size()), 0);
    
    for (size_t i = 0; i < bones.size(); i++)
    {
        lua_pushstring(L, bones[i]->getName().buffer());
        lua_rawseti(L, -2, static_cast<int>(i + 1));
    }
    
    return 1;
}

// skin:getConstraints()
// Returns the constraints associated with this skin
static int getConstraints(lua_State *L)
{
    LuaSkin *skinUserdata = checkSkin(L, 1);
    
    Vector<ConstraintData *> &constraints = skinUserdata->skin->getConstraints();
    lua_createtable(L, static_cast<int>(constraints.size()), 0);
    
    for (size_t i = 0; i < constraints.size(); i++)
    {
        lua_pushstring(L, constraints[i]->getName().buffer());
        lua_rawseti(L, -2, static_cast<int>(i + 1));
    }
    
    return 1;
}

// Lua calls __eq only for two SpineSkin userdata: same native skin, never raises (D7).
static int skin_eq(lua_State *L)
{
    lua_pushboolean(L, ((LuaSkin *)lua_touserdata(L, 1))->skin == ((LuaSkin *)lua_touserdata(L, 2))->skin);
    return 1;
}

static int skin_gc(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");

    skinUserdata->~LuaSkin();

    return 0;
}

void getSkinMt(lua_State *L)
{
    luaL_getmetatable(L, "SpineSkin");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "SpineSkin");

        lua_pushstring(L, "__index");
        lua_pushcfunction(L, skin_index);
        lua_settable(L, -3);

        lua_pushstring(L, "__newindex");
        lua_pushcfunction(L, skin_newindex);
        lua_settable(L, -3);

        lua_pushcfunction(L, skin_gc);
        lua_setfield(L, -2, "__gc");

        lua_pushcfunction(L, skin_eq);
        lua_setfield(L, -2, "__eq");

        // Register methods
        lua_pushstring(L, "addSkin");
        lua_pushcfunction(L, addSkin);
        lua_settable(L, -3);

        lua_pushstring(L, "copySkin");
        lua_pushcfunction(L, copySkin);
        lua_settable(L, -3);

        lua_pushstring(L, "getName");
        lua_pushcfunction(L, getName);
        lua_settable(L, -3);

        lua_pushstring(L, "getAttachment");
        lua_pushcfunction(L, getAttachment);
        lua_settable(L, -3);

        lua_pushstring(L, "getAttachments");
        lua_pushcfunction(L, getAttachments);
        lua_settable(L, -3);

        lua_pushstring(L, "setAttachment");
        lua_pushcfunction(L, setAttachment);
        lua_settable(L, -3);

        lua_pushstring(L, "removeAttachment");
        lua_pushcfunction(L, removeAttachment);
        lua_settable(L, -3);

        lua_pushstring(L, "clear");
        lua_pushcfunction(L, clear);
        lua_settable(L, -3);

        lua_pushstring(L, "findNamesForSlot");
        lua_pushcfunction(L, findNamesForSlot);
        lua_settable(L, -3);

        lua_pushstring(L, "findAttachmentsForSlot");
        lua_pushcfunction(L, findAttachmentsForSlot);
        lua_settable(L, -3);

        lua_pushstring(L, "getBones");
        lua_pushcfunction(L, getBones);
        lua_settable(L, -3);

        lua_pushstring(L, "getConstraints");
        lua_pushcfunction(L, getConstraints);
        lua_settable(L, -3);
    }
}

