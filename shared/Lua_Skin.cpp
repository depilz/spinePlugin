#include "Lua_Skin.h"
#include "Lua_Attachment.h"
#include <cmath>

static int skin_index(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");

    if (!skinUserdata->skin)
    {
        return 0;
    }

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
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");

    if (!skinUserdata->skin)
    {
        return 0;
    }

    const char *key = luaL_checkstring(L, 2);

    if (strcmp(key, "r") == 0)
    {
        float r = luaL_checknumber(L, 3);
        skinUserdata->skin->getColor().r = r;
        return 0;
    }
    else if (strcmp(key, "g") == 0)
    {
        float g = luaL_checknumber(L, 3);
        skinUserdata->skin->getColor().g = g;
        return 0;
    }
    else if (strcmp(key, "b") == 0)
    {
        float b = luaL_checknumber(L, 3);
        skinUserdata->skin->getColor().b = b;
        return 0;
    }
    else if (strcmp(key, "a") == 0)
    {
        float a = luaL_checknumber(L, 3);
        skinUserdata->skin->getColor().a = a;
        return 0;
    }
    else if (strcmp(key, "color") == 0)
    {
        luaL_checktype(L, 3, LUA_TTABLE);

        Color &color = skinUserdata->skin->getColor();

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

    return 0;
}

// Helper function to get a Skin pointer from Lua argument (supports string name or Skin object)
static Skin* getSkinFromArg(lua_State *L, int argIndex, SkeletonData *skeletonData)
{
    if (lua_isstring(L, argIndex))
    {
        // Lookup by name
        const char *skinName = lua_tostring(L, argIndex);
        if (!skeletonData)
        {
            fprintf(stderr, "WARNING: Cannot lookup skin by name: no SkeletonData available\n");
            return nullptr;
        }
        Skin *foundSkin = skeletonData->findSkin(skinName);
        if (!foundSkin)
        {
            fprintf(stderr, "WARNING: Skin not found: %s\n", skinName);
            return nullptr;
        }
        return foundSkin;
    }
    else if (lua_isuserdata(L, argIndex))
    {
        // Direct Skin object
        LuaSkin *otherSkinUserdata = (LuaSkin *)luaL_checkudata(L, argIndex, "SpineSkin");
        if (otherSkinUserdata->skeletonData != skeletonData)
            luaL_argerror(L, argIndex, "Skin belongs to different skeleton data");
        return otherSkinUserdata->skin;
    }
    else
    {
        fprintf(stderr, "WARNING: Expected skin name (string) or Skin object\n");
        return nullptr;
    }
}

// Helper function to get slot index from Lua argument (supports string name or integer index)
static int getSlotIndexFromArg(lua_State *L, int argIndex, SkeletonData *skeletonData)
{
    if (lua_isnumber(L, argIndex))
    {
        // Direct slot index
        lua_Number value = luaL_checknumber(L, argIndex);
        if (!skeletonData || !std::isfinite(value) || value < 0 || value >= skeletonData->getSlots().size() || value != std::floor(value))
            return luaL_argerror(L, argIndex, "Slot index must be a zero-based integer within the skeleton data");
        return static_cast<int>(value);
    }
    else if (lua_isstring(L, argIndex))
    {
        // Lookup by slot name
        const char *slotName = lua_tostring(L, argIndex);
        if (!skeletonData)
        {
            fprintf(stderr, "WARNING: Cannot lookup slot by name: no SkeletonData available\n");
            return -1;
        }
        SlotData *slotData = skeletonData->findSlot(slotName);
        if (!slotData)
        {
            fprintf(stderr, "WARNING: Slot not found: %s\n", slotName);
            return -1;
        }
        return slotData->getIndex();
    }
    else
    {
        fprintf(stderr, "WARNING: Expected slot index (number) or slot name (string)\n");
        return -1;
    }
}

// skin:addSkin(skinNameOrObject)
// Adds all attachments from another skin (shares references, does not copy)
// Returns: boolean success
static int addSkin(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_pushboolean(L, false);
        return 1;
    }

    Skin *otherSkin = getSkinFromArg(L, 2, skinUserdata->skeletonData);
    if (!otherSkin)
    {
        lua_pushboolean(L, false);
        return 1;
    }

    if (otherSkin != skinUserdata->skin) skinUserdata->skin->addSkin(otherSkin);
    lua_pushboolean(L, true);
    return 1;
}

// skin:copySkin(skinNameOrObject)
// Deep copies all attachments from another skin
// Returns: boolean success
static int copySkin(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_pushboolean(L, false);
        return 1;
    }

    Skin *otherSkin = getSkinFromArg(L, 2, skinUserdata->skeletonData);
    if (!otherSkin)
    {
        lua_pushboolean(L, false);
        return 1;
    }

    if (otherSkin != skinUserdata->skin) skinUserdata->skin->copySkin(otherSkin);
    lua_pushboolean(L, true);
    return 1;
}

// skin:getName()
// Returns the name of the skin
static int getName(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_pushnil(L);
        return 1;
    }

    lua_pushstring(L, skinUserdata->skin->getName().buffer());
    return 1;
}

// skin:setAttachment(slotIndex, name, attachment, [sourceSkin])
// Sets an attachment in the skin, optionally copying bones/constraints from source skin
// Returns: boolean success
static int setAttachment(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_pushboolean(L, false);
        return 1;
    }
    
    int slotIndex = getSlotIndexFromArg(L, 2, skinUserdata->skeletonData);
    if (slotIndex < 0)
    {
        lua_pushboolean(L, false);
        return 1;
    }
    
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
    if (lua_gettop(L) >= 5 && !lua_isnil(L, 5))
    {
        sourceSkin = getSkinFromArg(L, 5, skinUserdata->skeletonData);
        if (!sourceSkin)
        {
            lua_pushboolean(L, false);
            return 1;
        }
    }
    
    if (attachment)
    {
        // Copy the attachment instead of just referencing it
        Attachment *copiedAttachment = attachment->copy();
        skinUserdata->skin->setAttachment(slotIndex, name, copiedAttachment);
        
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
    
    lua_pushboolean(L, true);
    return 1;
}

// skin:getAttachment(slotIndex, name)
// Returns a specific attachment from the skin
static int getAttachment(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_pushnil(L);
        return 1;
    }
    
    int slotIndex = getSlotIndexFromArg(L, 2, skinUserdata->skeletonData);
    if (slotIndex < 0)
    {
        lua_pushnil(L);
        return 1;
    }
    
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

// skin:removeAttachment(slotIndex, name)
// Removes an attachment from the skin
// Returns: boolean success
static int removeAttachment(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_pushboolean(L, false);
        return 1;
    }
    
    int slotIndex = getSlotIndexFromArg(L, 2, skinUserdata->skeletonData);
    if (slotIndex < 0)
    {
        lua_pushboolean(L, false);
        return 1;
    }
    
    const char *name = luaL_checkstring(L, 3);
    
    skinUserdata->skin->removeAttachment(slotIndex, name);
    lua_pushboolean(L, true);
    return 1;
}

// skin:findNamesForSlot(slotIndex)
// Returns all attachment names for a specific slot
static int findNamesForSlot(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_newtable(L);
        return 1;
    }
    
    int slotIndex = getSlotIndexFromArg(L, 2, skinUserdata->skeletonData);
    if (slotIndex < 0)
    {
        lua_newtable(L);
        return 1;
    }
    
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

// skin:findAttachmentsForSlot(slotIndex)
// Returns all attachment objects for a specific slot
static int findAttachmentsForSlot(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_newtable(L);
        return 1;
    }
    
    int slotIndex = getSlotIndexFromArg(L, 2, skinUserdata->skeletonData);
    if (slotIndex < 0)
    {
        lua_newtable(L);
        return 1;
    }
    
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
// Returns a table of attachment information with attachment objects
static int getAttachments(lua_State *L)
{
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_newtable(L);
        return 1;
    }

    lua_newtable(L);
    
    Skin::AttachmentMap::Entries entries = skinUserdata->skin->getAttachments();
    int index = 1;
    
    while (entries.hasNext())
    {
        Skin::AttachmentMap::Entry &entry = entries.next();
        
        lua_newtable(L);
        
        lua_pushstring(L, "slotIndex");
        lua_pushinteger(L, entry._slotIndex);
        lua_settable(L, -3);
        
        lua_pushstring(L, "name");
        lua_pushstring(L, entry._name.buffer());
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
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_newtable(L);
        return 1;
    }
    
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
    LuaSkin *skinUserdata = (LuaSkin *)luaL_checkudata(L, 1, "SpineSkin");
    
    if (!skinUserdata->skin)
    {
        lua_newtable(L);
        return 1;
    }
    
    Vector<ConstraintData *> &constraints = skinUserdata->skin->getConstraints();
    lua_createtable(L, static_cast<int>(constraints.size()), 0);
    
    for (size_t i = 0; i < constraints.size(); i++)
    {
        lua_pushstring(L, constraints[i]->getName().buffer());
        lua_rawseti(L, -2, static_cast<int>(i + 1));
    }
    
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

