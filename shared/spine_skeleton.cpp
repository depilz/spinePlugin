#include "spine_skeleton.h"
#include "spine_texture.h"
#include "spine_renderer.h"
#include <spine/Extension.h>
#include <vector> // Include for std::vector

using namespace spine;

int create(lua_State *L)
{
    // Parse parameters from Lua
    if (!lua_istable(L, 1))
    {
        luaL_error(L, "Expected parameter table");
        return 0;
    }

    lua_getfield(L, 1, "skeletonFile");
    const char *skeletonFile = lua_tostring(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, 1, "atlasFile");
    const char *atlasFile = lua_tostring(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, 1, "scale");
    float scale = lua_isnumber(L, -1) ? lua_tonumber(L, -1) : 1.0f;
    lua_pop(L, 1);

    if (!skeletonFile || !atlasFile)
    {
        luaL_error(L, "skeletonFile and atlasFile are required");
        return 0;
    }

    // Create a custom texture loader
    SpineTextureLoader *textureLoader = new SpineTextureLoader();

    // Load the atlas
    Atlas *atlas = new Atlas(atlasFile, textureLoader);

    // Load skeleton data
    // is it a json or binary file?
    SkeletonData *skeletonData = nullptr;
    if (strstr(skeletonFile, ".json"))
    {
        skeletonData = SkeletonJson_readSkeletonDataFile(skeletonFile, atlas, scale);
    }
    else if (strstr(skeletonFile, ".skel"))
    {
        skeletonData = SkeletonBinary_readSkeletonDataFile(skeletonFile, atlas, scale);
    }

    if (!skeletonData)
    {
        luaL_error(L, "Failed to load skeleton data");
        delete atlas;
        delete textureLoader;
        return 0;
    }

    // Create skeleton and animation state
    Skeleton *skeleton = new Skeleton(skeletonData);
    AnimationStateData *stateData = new AnimationStateData(skeletonData);
    AnimationState *state = new AnimationState(stateData);

    // Allocate userdata
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)lua_newuserdata(L, sizeof(SpineSkeleton));
    skeletonUserdata->skeleton = skeleton;
    skeletonUserdata->state = state;
    skeletonUserdata->stateData = stateData;
    skeletonUserdata->atlas = atlas;
    skeletonUserdata->skeletonData = skeletonData;

    skeletonUserdata->meshes.reserve(100);
    skeletonUserdata->meshSet.reserve(100);

    // Set metatable
    luaL_getmetatable(L, "SpineSkeleton");
    if (lua_isnil(L, -1))
    {
        // Metatable doesn't exist yet; create it
        lua_pop(L, 1); // Pop nil
        luaL_newmetatable(L, "SpineSkeleton");

        // Set __index
        lua_pushstring(L, "__index");
        lua_pushcfunction(L, skeleton_index);
        lua_settable(L, -3);

        // Set __newindex
        lua_pushstring(L, "__newindex");
        lua_pushcfunction(L, skeleton_newindex);
        lua_settable(L, -3);

        // Register methods
        luaL_Reg methods[] = {
            {NULL, NULL}
        };
        luaL_register(L, NULL, methods);
    }

    // Set the metatable
    lua_setmetatable(L, -2);

    lua_newtable(L);
    lua_pushstring(L, "_skeleton");
    lua_pushvalue(L, -3);
    lua_settable(L, -3);


    // attach a display group to our userdata
    lua_getglobal(L, "display");
    lua_getfield(L, -1, "newGroup");
    lua_call(L, 0, 1);

    lua_pushvalue(L, -1);

    skeletonUserdata->group = LuaTableHolder(L);

    lua_remove(L, -2);

    lua_getfield(L, -1, "_proxy");
    lua_setfield(L, -3, "_proxy");
    lua_getfield(L, -1, "_class");
    lua_setfield(L, -3, "_class");

    lua_remove(L, -1);

    // Set metatable
    luaL_getmetatable(L, "SpineObject");
    if (lua_isnil(L, -1))
    {
        // Metatable doesn't exist yet; create it
        lua_pop(L, 1); // Pop nil
        luaL_newmetatable(L, "SpineObject");

        // Set __index
        lua_pushstring(L, "__index");
        lua_pushcfunction(L, skeleton_index);
        lua_settable(L, -3);

        // Set __newindex
        lua_pushstring(L, "__newindex");
        lua_pushcfunction(L, skeleton_newindex);
        lua_settable(L, -3);

        // Register methods
        luaL_Reg methods[] = {
            {"setAnimation", skeleton_setAnimation},
            {"update", skeleton_update},
            {"dispose", skeleton_dispose},
            {"setToSetupPose", skeleton_setToSetupPose},
            {"dispose", skeleton_dispose},

            // {"setSkin", skeleton_setSkin},
            // {"setAttachment", skeleton_setAttachment},
            // {"updateWorldTransform", skeleton_updateWorldTransform},
            {NULL, NULL}
        };
        luaL_register(L, NULL, methods);

        // Add garbage collection method
        lua_pushcfunction(L, skeleton_gc);
        lua_setfield(L, -2, "__gc");
    }

    // Set the metatable
    lua_setmetatable(L, -2);
    

    return 1;
    }

int skeleton_setAnimation(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    int trackIndex = luaL_checkint(L, 2);
    const char *animationName = luaL_checkstring(L, 3);
    bool loop = lua_toboolean(L, 4);

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);
    if (!animation)
    {
        luaL_error(L, "Animation not found: %s", animationName);
        return 0;
    }

    skeletonUserdata->state->setAnimation(trackIndex, animation, loop);
    return 0;
}

int skeleton_update(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    float deltaTime = luaL_checknumber(L, 2);

    skeletonUserdata->state->update(deltaTime);
    skeletonUserdata->state->apply(*skeletonUserdata->skeleton);
    skeletonUserdata->skeleton->update(deltaTime);
    skeletonUserdata->skeleton->updateWorldTransform(Physics_Update);

    // Render the skeleton
    SkeletonRenderer skeletonRenderer;
    skeleton_render(L, skeletonUserdata, skeletonRenderer);

    return 0;
}

int skeleton_render(lua_State *L, SpineSkeleton * skeletonUserdata, SkeletonRenderer &skeletonRenderer)
{
    Skeleton *skeleton = skeletonUserdata->skeleton;
    RenderCommand *command = skeletonRenderer.render(*skeleton);
    // we need to have ids for each command, so we can update already existing meshes
    // for that we can't use the index, but the slot name
    int i = 0;
    while (command)
    {
        float *positions = command->positions;
        float *uvs = command->uvs;
        uint32_t *colors = command->colors;
        uint16_t *indices = command->indices;
        Texture *texture = (Texture *)command->texture;
        
        BlendMode blendMode = command->blendMode;

        auto &meshes = skeletonUserdata->meshes;

        if (meshes[i].isValid())
        {
            LuaTableHolder &mesh = meshes[i];
            engine_updateMesh(L, &mesh, command->positions, command->numVertices, command->uvs, command->indices, command->numIndices, texture, blendMode, command->colors);
        }
        else
        {
            engine_drawMesh(L, command->positions, command->numVertices, command->uvs, command->indices, command->numIndices, texture, blendMode, command->colors);

            skeletonUserdata->group.pushTable();
            lua_getfield(L, -1, "insert");
            lua_pushvalue(L, -2);
            lua_pushvalue(L, -4);
            lua_call(L, 2, 0);
            lua_pop(L, 1); // Pop the group

            // initialize mesh
            meshes[i].initialize(L);
            lua_pop(L, 1);
        }
        command = command->next;
        i++;
    }
    
    return 0; // Return 0 to indicate no values are pushed to Lua
}

int skeleton_setToSetupPose(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    skeletonUserdata->skeleton->setToSetupPose();
    return 0;
}

int skeleton_dispose(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    delete skeletonUserdata->state;
    delete skeletonUserdata->stateData;
    delete skeletonUserdata->skeleton;
    delete skeletonUserdata->skeletonData;
    delete skeletonUserdata->atlas;
    // The textureLoader is deleted within atlas destructor

    skeletonUserdata->state = nullptr;
    skeletonUserdata->stateData = nullptr;
    skeletonUserdata->skeleton = nullptr;
    skeletonUserdata->skeletonData = nullptr;
    skeletonUserdata->atlas = nullptr;

    return 0;
}

int skeleton_gc(lua_State *L)
{
    return skeleton_dispose(L);
}

int skeleton_index(lua_State* L) {
    const char* key = luaL_checkstring(L, 2);

    lua_getfield(L, 1, "_skeleton");

    SpineSkeleton* skeletonUserdata = (SpineSkeleton*)luaL_checkudata(L, -1, "SpineSkeleton");

    if (strcmp(key, "x") == 0) {
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "x");
        lua_getfield(L, -2, "x");
        return 1;
    }

    if (strcmp(key, "y") == 0) {
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "y");
        lua_getfield(L, -2, "y");
        return 1;
    }

    if (strcmp(key, "xScale") == 0) {
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "xScale");
        lua_getfield(L, -2, "xScale");
        return 1;
    }

    if (strcmp(key, "yScale") == 0) {
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "yScale");
        lua_getfield(L, -2, "yScale");
        return 1;
    }

    if (strcmp(key, "rotation") == 0) {
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "rotation");
        lua_getfield(L, -2, "rotation");
        return 1;
    }

    if (strcmp(key, "isVisible") == 0) {
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "isVisible");
        lua_getfield(L, -2, "isVisible");
        return 1;
    }

    if (strcmp(key, "alpha") == 0) {
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "alpha");
        lua_getfield(L, -2, "alpha");
        return 1;
    }

    // if (strcmp(key, "dispose") == 0) {
    //     lua_pushcfunction(L, skeleton_dispose);
    //     return 1;
    // }

    // if (strcmp(key, "setToSetupPose") == 0) {
    //     lua_pushcfunction(L, skeleton_setToSetupPose);
    //     return 1;
    // }



    // Fallback to methods
    lua_getmetatable(L, 1);
    lua_pushvalue(L, 2);
    lua_rawget(L, -2);

    if (!lua_isnil(L, -1)) {
        return 1;
    }
    return 0;
}

// __newindex metamethod
int skeleton_newindex(lua_State* L) {
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton* skeletonUserdata = (SpineSkeleton*)luaL_checkudata(L, -1, "SpineSkeleton");
    const char* key = luaL_checkstring(L, 2);

    if (strcmp(key, "x") == 0) {
        float x = luaL_checknumber(L, 3);
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "x");
        lua_pushnumber(L, x);
        lua_settable(L, -3);
        return 0;
    }
    if (strcmp(key, "y") == 0) {
        float y = luaL_checknumber(L, 3);
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "y");
        lua_pushnumber(L, y);
        lua_settable(L, -3);
        return 0;
    }

    if (strcmp(key, "xScale") == 0) {
        float xScale = luaL_checknumber(L, 3);
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "xScale");
        lua_pushnumber(L, xScale);
        lua_settable(L, -3);
        return 0;
    }

    if (strcmp(key, "yScale") == 0) {
        float yScale = luaL_checknumber(L, 3);
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "yScale");
        lua_pushnumber(L, yScale);
        lua_settable(L, -3);
        return 0;
    }

    if (strcmp(key, "rotation") == 0) {
        float rotation = luaL_checknumber(L, 3);
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "rotation");
        lua_pushnumber(L, rotation);
        lua_settable(L, -3);
        return 0;
    }

    if (strcmp(key, "isVisible") == 0) {
        bool isVisible = lua_toboolean(L, 3);
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "isVisible");
        lua_pushboolean(L, isVisible);
        lua_settable(L, -3);
        return 0;
    }

    if (strcmp(key, "alpha") == 0) {
        float alpha = luaL_checknumber(L, 3);
        skeletonUserdata->group.pushTable();
        lua_pushstring(L, "alpha");
        lua_pushnumber(L, alpha);
        lua_settable(L, -3);
        return 0;
    }



    // Optionally handle other properties or throw an error
    luaL_error(L, "Attempting to set undefined property '%s'", key);
    return 0;
}

// read skeleton json
SkeletonData *SkeletonJson_readSkeletonDataFile(const char *filename, Atlas *atlas, float scale)
{

    SkeletonJson *json = new SkeletonJson(atlas);
    json->setScale(scale);
    SkeletonData *skeletonData = json->readSkeletonDataFile(filename);
    delete json;
    return skeletonData;
}

// read skeleton binary
SkeletonData *SkeletonBinary_readSkeletonDataFile(const char *filename, Atlas *atlas, float scale)
{
    SkeletonBinary *binary = new SkeletonBinary(atlas);
    binary->setScale(scale);
    SkeletonData *skeletonData = binary->readSkeletonDataFile(filename);
    delete binary;
    return skeletonData;
}




    Solar2dExtension::Solar2dExtension() : DefaultSpineExtension()
{
}

Solar2dExtension::~Solar2dExtension() {}

SpineExtension *spine::getDefaultExtension()
{
    return new Solar2dExtension();
}

// Register all functions (if not already done)
int luaopen_spine_skeleton(lua_State* L) {
    luaL_Reg functions[] = {
        {"create", create},
        {NULL, NULL}
    };
    luaL_register(L, "SpineObject", functions);
    return 1;
}
