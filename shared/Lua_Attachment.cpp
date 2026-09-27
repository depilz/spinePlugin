#include "Lua_Attachment.h"
#include "spine/RegionAttachment.h"
#include "spine/MeshAttachment.h"
#include "spine/BoundingBoxAttachment.h"
#include "spine/PathAttachment.h"
#include "spine/PointAttachment.h"
#include "spine/ClippingAttachment.h"
#include "spine/AttachmentType.h"
#include "spine/Slot.h"
#include "Lua_Slot.h"

static const char* getAttachmentTypeName(Attachment *attachment)
{
    if (!attachment)
    {
        return "none";
    }

    if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
    {
        return "region";
    }
    else if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
    {
        return "mesh";
    }
    else if (attachment->getRTTI().instanceOf(BoundingBoxAttachment::rtti))
    {
        return "boundingbox";
    }
    else if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
    {
        return "path";
    }
    else if (attachment->getRTTI().instanceOf(PointAttachment::rtti))
    {
        return "point";
    }
    else if (attachment->getRTTI().instanceOf(ClippingAttachment::rtti))
    {
        return "clipping";
    }

    return "unknown";
}

static int attachment_index(lua_State *L)
{
    LuaAttachment *attachmentUserdata = (LuaAttachment *)luaL_checkudata(L, 1, "SpineAttachment");

    const char *key = luaL_checkstring(L, 2);

    if (!attachmentUserdata->attachment)
    {
        return 0;
    }

    Attachment *attachment = attachmentUserdata->attachment;

    if (strcmp(key, "name") == 0)
    {
        lua_pushstring(L, attachment->getName().buffer());
        return 1;
    }
    else if (strcmp(key, "type") == 0)
    {
        lua_pushstring(L, getAttachmentTypeName(attachment));
        return 1;
    }
    else if (strcmp(key, "color") == 0)
    {
        Color *color = nullptr;

        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            color = &static_cast<RegionAttachment *>(attachment)->getColor();
        }
        else if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            color = &static_cast<MeshAttachment *>(attachment)->getColor();
        }
        else if (attachment->getRTTI().instanceOf(PointAttachment::rtti))
        {
            color = &static_cast<PointAttachment *>(attachment)->getColor();
        }
        else if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
        {
            color = &static_cast<PathAttachment *>(attachment)->getColor();
        }
        else if (attachment->getRTTI().instanceOf(BoundingBoxAttachment::rtti))
        {
            color = &static_cast<BoundingBoxAttachment *>(attachment)->getColor();
        }
        else if (attachment->getRTTI().instanceOf(ClippingAttachment::rtti))
        {
            color = &static_cast<ClippingAttachment *>(attachment)->getColor();
        }

        if (color)
        {
            lua_createtable(L, 0, 4);
            lua_pushstring(L, "r");
            lua_pushnumber(L, color->r);
            lua_settable(L, -3);
            lua_pushstring(L, "g");
            lua_pushnumber(L, color->g);
            lua_settable(L, -3);
            lua_pushstring(L, "b");
            lua_pushnumber(L, color->b);
            lua_settable(L, -3);
            lua_pushstring(L, "a");
            lua_pushnumber(L, color->a);
            lua_settable(L, -3);
            return 1;
        }
        else
        {
            lua_pushnil(L);
            return 1;
        }
    }
    else if (strcmp(key, "width") == 0)
    {
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<RegionAttachment *>(attachment)->getWidth());
            return 1;
        }
        else if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<MeshAttachment *>(attachment)->getWidth());
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "height") == 0)
    {
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<RegionAttachment *>(attachment)->getHeight());
            return 1;
        }
        else if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<MeshAttachment *>(attachment)->getHeight());
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "path") == 0)
    {
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            lua_pushstring(L, static_cast<RegionAttachment *>(attachment)->getPath().buffer());
            return 1;
        }
        else if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            lua_pushstring(L, static_cast<MeshAttachment *>(attachment)->getPath().buffer());
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    // RegionAttachment properties
    else if (strcmp(key, "x") == 0)
    {
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<RegionAttachment *>(attachment)->getX());
            return 1;
        }
        else if (attachment->getRTTI().instanceOf(PointAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<PointAttachment *>(attachment)->getX());
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "y") == 0)
    {
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<RegionAttachment *>(attachment)->getY());
            return 1;
        }
        else if (attachment->getRTTI().instanceOf(PointAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<PointAttachment *>(attachment)->getY());
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "rotation") == 0)
    {
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<RegionAttachment *>(attachment)->getRotation());
            return 1;
        }
        else if (attachment->getRTTI().instanceOf(PointAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<PointAttachment *>(attachment)->getRotation());
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "scaleX") == 0)
    {
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<RegionAttachment *>(attachment)->getScaleX());
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "scaleY") == 0)
    {
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<RegionAttachment *>(attachment)->getScaleY());
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    // MeshAttachment properties
    else if (strcmp(key, "triangles") == 0)
    {
        if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            Vector<unsigned short> &triangles = static_cast<MeshAttachment *>(attachment)->getTriangles();
            lua_createtable(L, (int)triangles.size(), 0);
            for (size_t i = 0; i < triangles.size(); i++)
            {
                lua_pushnumber(L, triangles[i]);
                lua_rawseti(L, -2, (int)(i + 1));
            }
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "hullLength") == 0)
    {
        if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            lua_pushnumber(L, static_cast<MeshAttachment *>(attachment)->getHullLength());
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    // PathAttachment properties
    else if (strcmp(key, "closed") == 0)
    {
        if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
        {
            lua_pushboolean(L, spc::pathClosed(*static_cast<PathAttachment *>(attachment)));
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "constantSpeed") == 0)
    {
        if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
        {
            lua_pushboolean(L, spc::pathConstantSpeed(*static_cast<PathAttachment *>(attachment)));
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "lengths") == 0)
    {
        if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
        {
            Vector<float> &lengths = static_cast<PathAttachment *>(attachment)->getLengths();
            lua_createtable(L, (int)lengths.size(), 0);
            for (size_t i = 0; i < lengths.size(); i++)
            {
                lua_pushnumber(L, lengths[i]);
                lua_rawseti(L, -2, (int)(i + 1));
            }
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    // VertexAttachment properties
    else if (strcmp(key, "vertices") == 0)
    {
        VertexAttachment *vertexAttachment = nullptr;
        if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }
        else if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }
        else if (attachment->getRTTI().instanceOf(BoundingBoxAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }
        else if (attachment->getRTTI().instanceOf(ClippingAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }

        if (vertexAttachment)
        {
            Vector<float> &vertices = vertexAttachment->getVertices();
            lua_createtable(L, (int)vertices.size(), 0);
            for (size_t i = 0; i < vertices.size(); i++)
            {
                lua_pushnumber(L, vertices[i]);
                lua_rawseti(L, -2, (int)(i + 1));
            }
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "bones") == 0)
    {
        VertexAttachment *vertexAttachment = nullptr;
        if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }
        else if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }
        else if (attachment->getRTTI().instanceOf(BoundingBoxAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }
        else if (attachment->getRTTI().instanceOf(ClippingAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }

        if (vertexAttachment)
        {
            Vector<int> &bones = vertexAttachment->getBones();
            lua_createtable(L, (int)bones.size(), 0);
            for (size_t i = 0; i < bones.size(); i++)
            {
                lua_pushnumber(L, bones[i]);
                lua_rawseti(L, -2, (int)(i + 1));
            }
            return 1;
        }
        lua_pushnil(L);
        return 1;
    }
    else if (strcmp(key, "worldVerticesLength") == 0)
    {
        VertexAttachment *vertexAttachment = nullptr;
        if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }
        else if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }
        else if (attachment->getRTTI().instanceOf(BoundingBoxAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }
        else if (attachment->getRTTI().instanceOf(ClippingAttachment::rtti))
        {
            vertexAttachment = static_cast<VertexAttachment *>(attachment);
        }

        if (vertexAttachment)
        {
            lua_pushnumber(L, vertexAttachment->getWorldVerticesLength());
            return 1;
        }
        lua_pushnil(L);
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

static int attachment_newindex(lua_State *L)
{
    LuaAttachment *attachmentUserdata = (LuaAttachment *)luaL_checkudata(L, 1, "SpineAttachment");

    if (!attachmentUserdata->attachment)
    {
        return 0;
    }

    const char *key = luaL_checkstring(L, 2);

    Attachment *attachment = attachmentUserdata->attachment;

    if (strcmp(key, "color") == 0)
    {
        luaL_checktype(L, 3, LUA_TTABLE);

        Color *color = nullptr;

        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            color = &static_cast<RegionAttachment *>(attachment)->getColor();
        }
        else if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            color = &static_cast<MeshAttachment *>(attachment)->getColor();
        }
        else if (attachment->getRTTI().instanceOf(PointAttachment::rtti))
        {
            color = &static_cast<PointAttachment *>(attachment)->getColor();
        }
        else if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
        {
            color = &static_cast<PathAttachment *>(attachment)->getColor();
        }
        else if (attachment->getRTTI().instanceOf(BoundingBoxAttachment::rtti))
        {
            color = &static_cast<BoundingBoxAttachment *>(attachment)->getColor();
        }
        else if (attachment->getRTTI().instanceOf(ClippingAttachment::rtti))
        {
            color = &static_cast<ClippingAttachment *>(attachment)->getColor();
        }

        if (color)
        {
            lua_getfield(L, 3, "r");
            if (lua_isnumber(L, -1))
            {
                color->r = lua_tonumber(L, -1);
            }
            lua_pop(L, 1);

            lua_getfield(L, 3, "g");
            if (lua_isnumber(L, -1))
            {
                color->g = lua_tonumber(L, -1);
            }
            lua_pop(L, 1);

            lua_getfield(L, 3, "b");
            if (lua_isnumber(L, -1))
            {
                color->b = lua_tonumber(L, -1);
            }
            lua_pop(L, 1);

            lua_getfield(L, 3, "a");
            if (lua_isnumber(L, -1))
            {
                color->a = lua_tonumber(L, -1);
            }
            lua_pop(L, 1);
        }

        return 0;
    }
    else if (strcmp(key, "width") == 0)
    {
        float width = luaL_checknumber(L, 3);
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            static_cast<RegionAttachment *>(attachment)->setWidth(width);
        }
        else if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            static_cast<MeshAttachment *>(attachment)->setWidth(width);
        }
        return 0;
    }
    else if (strcmp(key, "height") == 0)
    {
        float height = luaL_checknumber(L, 3);
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            static_cast<RegionAttachment *>(attachment)->setHeight(height);
        }
        else if (attachment->getRTTI().instanceOf(MeshAttachment::rtti))
        {
            static_cast<MeshAttachment *>(attachment)->setHeight(height);
        }
        return 0;
    }
    // RegionAttachment setters
    else if (strcmp(key, "x") == 0)
    {
        float x = luaL_checknumber(L, 3);
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            static_cast<RegionAttachment *>(attachment)->setX(x);
        }
        else if (attachment->getRTTI().instanceOf(PointAttachment::rtti))
        {
            static_cast<PointAttachment *>(attachment)->setX(x);
        }
        return 0;
    }
    else if (strcmp(key, "y") == 0)
    {
        float y = luaL_checknumber(L, 3);
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            static_cast<RegionAttachment *>(attachment)->setY(y);
        }
        else if (attachment->getRTTI().instanceOf(PointAttachment::rtti))
        {
            static_cast<PointAttachment *>(attachment)->setY(y);
        }
        return 0;
    }
    else if (strcmp(key, "rotation") == 0)
    {
        float rotation = luaL_checknumber(L, 3);
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            static_cast<RegionAttachment *>(attachment)->setRotation(rotation);
        }
        else if (attachment->getRTTI().instanceOf(PointAttachment::rtti))
        {
            static_cast<PointAttachment *>(attachment)->setRotation(rotation);
        }
        return 0;
    }
    else if (strcmp(key, "scaleX") == 0)
    {
        float scaleX = luaL_checknumber(L, 3);
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            static_cast<RegionAttachment *>(attachment)->setScaleX(scaleX);
        }
        return 0;
    }
    else if (strcmp(key, "scaleY") == 0)
    {
        float scaleY = luaL_checknumber(L, 3);
        if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
        {
            static_cast<RegionAttachment *>(attachment)->setScaleY(scaleY);
        }
        return 0;
    }
    // PathAttachment setters
    else if (strcmp(key, "closed") == 0)
    {
        bool closed = lua_toboolean(L, 3);
        if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
        {
            static_cast<PathAttachment *>(attachment)->setClosed(closed);
        }
        return 0;
    }
    else if (strcmp(key, "constantSpeed") == 0)
    {
        bool constantSpeed = lua_toboolean(L, 3);
        if (attachment->getRTTI().instanceOf(PathAttachment::rtti))
        {
            static_cast<PathAttachment *>(attachment)->setConstantSpeed(constantSpeed);
        }
        return 0;
    }

    return 0;
}

static int attachment_computeWorldVertices(lua_State *L)
{
    LuaAttachment *attachmentUserdata = (LuaAttachment *)luaL_checkudata(L, 1, "SpineAttachment");
    
    if (!attachmentUserdata->attachment)
    {
        return 0;
    }

    // Second argument should be a slot
    LuaSlot *slotUserdata = (LuaSlot *)luaL_checkudata(L, 2, "SpineSlot");
    slotUserdata->checkAlive(L);
    if (attachmentUserdata->dataOwner != slotUserdata->dataOwner)
        return luaL_argerror(L, 2, "Slot belongs to different skeleton data");
    if (!slotUserdata->slot)
    {
        return 0;
    }

    Attachment *attachment = attachmentUserdata->attachment;
    Slot *slot = slotUserdata->slot;

    // Handle RegionAttachment (4 vertices = 8 floats)
    if (attachment->getRTTI().instanceOf(RegionAttachment::rtti))
    {
        RegionAttachment *regionAttachment = static_cast<RegionAttachment *>(attachment);
        float worldVertices[8];
        spc::regionWorldVertices(*regionAttachment, *slot, worldVertices);
        
        lua_createtable(L, 8, 0);
        for (int i = 0; i < 8; i++)
        {
            lua_pushnumber(L, worldVertices[i]);
            lua_rawseti(L, -2, i + 1);
        }
        return 1;
    }
    // Handle VertexAttachment types (Mesh, Path, BoundingBox, Clipping)
    else if (attachment->getRTTI().instanceOf(MeshAttachment::rtti) ||
             attachment->getRTTI().instanceOf(PathAttachment::rtti) ||
             attachment->getRTTI().instanceOf(BoundingBoxAttachment::rtti) ||
             attachment->getRTTI().instanceOf(ClippingAttachment::rtti))
    {
        VertexAttachment *vertexAttachment = static_cast<VertexAttachment *>(attachment);
        size_t worldVerticesLength = vertexAttachment->getWorldVerticesLength();
        
        Vector<float> worldVertices;
        worldVertices.setSize(worldVerticesLength, 0);
        
        spc::vertexWorldVertices(*vertexAttachment, *slot, worldVertices);
        
        lua_createtable(L, (int)worldVerticesLength, 0);
        for (size_t i = 0; i < worldVerticesLength; i++)
        {
            lua_pushnumber(L, worldVertices[i]);
            lua_rawseti(L, -2, (int)(i + 1));
        }
        return 1;
    }

    lua_pushnil(L);
    return 1;
}

static int attachment_gc(lua_State *L)
{
    LuaAttachment *attachmentUserdata = (LuaAttachment *)luaL_checkudata(L, 1, "SpineAttachment");

    attachmentUserdata->~LuaAttachment();

    return 0;
}

void getAttachmentMt(lua_State *L)
{
    if (luaL_newmetatable(L, "SpineAttachment"))
    {
        lua_pushcfunction(L, attachment_index);
        lua_setfield(L, -2, "__index");

        lua_pushcfunction(L, attachment_newindex);
        lua_setfield(L, -2, "__newindex");

        lua_pushcfunction(L, attachment_gc);
        lua_setfield(L, -2, "__gc");

        // Methods
        lua_pushcfunction(L, attachment_computeWorldVertices);
        lua_setfield(L, -2, "computeWorldVertices");
    }
}

