#include "spine_skeleton.h"
#include "spine_texture.h"
#include "spine_renderer.h"
#include <spine/Extension.h>
#include <vector> // Include for std::vector

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
    new (skeletonUserdata) SpineSkeleton(L);
    skeletonUserdata->skeleton = skeleton;
    skeletonUserdata->state = state;
    skeletonUserdata->stateData = stateData;
    skeletonUserdata->atlas = atlas;
    skeletonUserdata->skeletonData = skeletonData;
    

    // Set metatable
    get_skeleton_metatable(L);
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

    // Set the metatable
    get_spineObject_metatable(L);
    lua_setmetatable(L, -2);

    return 1;
}

void get_skeleton_metatable(lua_State *L){
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

        // Add garbage collection method
        lua_pushcfunction(L, skeleton_gc);
        lua_setfield(L, -2, "__gc");
    }
}

void get_spineObject_metatable(lua_State *L){
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
            {"update", skeleton_update},
            {"removeSelf", remove_self},

            {"setAnimation", skeleton_setAnimation},

            {"setDefaultMix", set_default_mix},
            {"setMix", set_mix},

            {"setToSetupPose", skeleton_setToSetupPose},

            {"addAnimation", skeleton_addAnimation},
            {"findAnimation", skeleton_findAnimation},
            {"getAllAnimations", skeleton_getAllAnimations},

            {"getAllSkins", skeleton_getAllSkins},
            {"setSkin", skeleton_setSkin},

            {"setAttachment", skeleton_setAttachment},

            {NULL, NULL}};
        luaL_register(L, NULL, methods);

        // Add garbage collection method
        lua_pushcfunction(L, spine_gc);
        lua_setfield(L, -2, "__gc");
    }
}

int set_default_mix(lua_State *L){
    // 2 arguments: self, mix
    if (lua_gettop(L) != 2)
    {
        luaL_error(L, "Expected 2 arguments: self, mix");
        return 0;
    }

    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    float mix = luaL_checknumber(L, 2);

    skeletonUserdata->stateData->setDefaultMix(mix);
}

int set_mix(lua_State *L){
    // 4 arguments: self, from, to, mix
    if (lua_gettop(L) != 4)
    {
        luaL_error(L, "Expected 4 arguments: self, from, to, mix");
        return 0;
    }

    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    const char *from = luaL_checkstring(L, 2);
    const char *to = luaL_checkstring(L, 3);
    float mix = luaL_checknumber(L, 4);

    Animation *fromAnimation = skeletonUserdata->skeletonData->findAnimation(from);
    if (!fromAnimation)
    {
        luaL_error(L, "Animation not found: %s", from);
        return 0;
    }

    Animation *toAnimation = skeletonUserdata->skeletonData->findAnimation(to);
    if (!toAnimation)
    {
        luaL_error(L, "Animation not found: %s", to);
        return 0;
    }

    skeletonUserdata->stateData->setMix(fromAnimation, toAnimation, mix);
    return 0;

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

int skeleton_addAnimation(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    int trackIndex = luaL_checkint(L, 2);
    const char *animationName = luaL_checkstring(L, 3);
    bool loop = lua_toboolean(L, 4);
    float delay = luaL_checknumber(L, 5);

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);
    if (!animation)
    {
        luaL_error(L, "Animation not found: %s", animationName);
        return 0;
    }

    skeletonUserdata->state->addAnimation(trackIndex, animation, loop, delay);
    return 0;
}

int skeleton_findAnimation(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    const char *animationName = luaL_checkstring(L, 2);

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);

    lua_pushboolean(L, animation != nullptr);

    return 1;
}

int skeleton_getAllAnimations(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    SkeletonData *skeletonData = skeletonUserdata->skeletonData;
    Vector<Animation *> &animations = skeletonData->getAnimations();
    int n = animations.size();
    lua_createtable(L, n, 0);

    for (int i = 0; i < n; i++)
    {
        lua_pushstring(L, animations[i]->getName().buffer());
        lua_rawseti(L, -2, i + 1);
    }

    return 1;
}

int skeleton_getAllSkins(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    SkeletonData *skeletonData = skeletonUserdata->skeletonData;
    Vector<Skin *> &skins = skeletonData->getSkins();
    int n = skins.size();
    lua_createtable(L, n, 0);

    for (int i = 0; i < n; i++)
    {
        lua_pushstring(L, skins[i]->getName().buffer());
        lua_rawseti(L, -2, i + 1);
    }

    return 1;
}

int skeleton_setSkin(lua_State *L)
{
    // 2 arguments: self, skinName
    if (lua_gettop(L) != 2)
    {
        luaL_error(L, "Expected 2 arguments: self, skinName");
        return 0;
    }

    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    const char *skinName = luaL_checkstring(L, 2);

    Skeleton *skeleton = skeletonUserdata->skeleton;
    SkeletonData *skeletonData = skeletonUserdata->skeletonData;

    if (!skinName)
    {
        luaL_error(L, "Skin name is required");
        return 0;
    }

    Skin *skin = skeletonData->findSkin(skinName);
    if (!skin)
    {
        luaL_error(L, "Skin not found: %s", skinName);
        return 0;
    }

    skeleton->setSkin(skin);
    skeleton->setSlotsToSetupPose();

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

    auto &meshes = skeletonUserdata->meshes;
    auto &meshIndices = skeletonUserdata->meshIndices;

    while (command)
    {
        float *positions = command->positions;
        float *uvs = command->uvs;
        uint32_t *colors = command->colors;
        uint16_t *indices = command->indices;
        Texture *texture = (Texture *)command->texture;

        BlendMode blendMode = command->blendMode;

        bool existingMesh = meshes.isMeshValid(i);

        if (existingMesh)
        {
            LuaTableHolder &mesh = meshes[i];
            if(meshIndices[i] != command->numIndices)
            {
                engine_removeMesh(L, &mesh);
                existingMesh = false;
                meshes[i].releaseTable();
            } 
            else
            {   
                engine_updateMesh(L, &mesh, command->positions, command->numVertices, command->uvs, command->indices, command->numIndices, texture, blendMode, command->colors);
            }
        }

        if (!existingMesh)
        {
            engine_drawMesh(L, command->positions, command->numVertices, command->uvs, command->indices, command->numIndices, texture, blendMode, command->colors);

            skeletonUserdata->group.pushTable();
            lua_getfield(L, -1, "insert");
            lua_pushvalue(L, -2);
            lua_pushnumber(L, i + 1);
            lua_pushvalue(L, -5);
            lua_call(L, 3, 0);
            lua_pop(L, 1); // Pop the group

            // initialize mesh
            meshes.setMesh(L, i);
            meshIndices[i] = command->numIndices;

            lua_pop(L, 1);
        }
        command = command->next;
        i++;
    }

    while (meshes.isMeshValid(i))
    {
        LuaTableHolder &mesh = meshes[i];
        engine_removeMesh(L, &mesh);
        meshes[i].releaseTable();
        i++;
    }

    lua_pop(L, -1);

    return 0;
}

int skeleton_setToSetupPose(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    skeletonUserdata->skeleton->setToSetupPose();
    return 0;
}

int remove_self(lua_State *L)
{
    if (!lua_istable(L, 1))
    {
        luaL_error(L, "table expected. If this is a function call, you might have used '.' instead of ':'");
        return 0;
    }
    
    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);
    
    if (lua_isnil(L, -1))
    {
        luaL_error(L, "Skeleton already removed");
        return 0;
     }

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_pop(L, 1);

    // remove skeleton
    lua_pushnil(L);
    lua_setfield(L, 1, "_skeleton");
    lua_pushnil(L);
    lua_setfield(L, 1, "_proxy");
    lua_pushnil(L);
    lua_setfield(L, 1, "_class");

    // remove display group
    skeletonUserdata->group.pushTable();
    lua_getfield(L, -1, "removeSelf");
    lua_pushvalue(L, -2);
    lua_call(L, 1, 0);

    skeletonUserdata->~SpineSkeleton();

    return 0;
}

int skeleton_gc(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    if(skeletonUserdata->skeleton)
    {
        skeletonUserdata->~SpineSkeleton();
    }

    return 0;
}

int spine_gc(lua_State *L)
{
    return 0;
}

int skeleton_index(lua_State* L) {
    const char* key = luaL_checkstring(L, 2);

    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);

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
    //     lua_pushcfunction(L, remove_self);
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

int skeleton_setAttachment(lua_State *L) {
    // 3 arguments: self, slotName, attachmentName
    if (lua_gettop(L) != 3) {
        luaL_error(L, "Expected 3 arguments: self, slotName, attachmentName");
        return 0;
    }

    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton* skeletonUserdata = (SpineSkeleton*)luaL_checkudata(L, -1, "SpineSkeleton");
    const char* slotName = luaL_checkstring(L, 2);
    const char* attachmentName = luaL_checkstring(L, 3);

    Slot* slot = skeletonUserdata->skeleton->findSlot(slotName);
    if (!slot) {
        luaL_error(L, "Slot not found: %s", slotName);
        return 0;
    }

    Attachment* attachment = nullptr;
    if (strcmp(attachmentName, "null") != 0) {
        Skin* skin = skeletonUserdata->skeleton->getSkin();
        attachment = skin->getAttachment(slot->getData().getIndex(), attachmentName);
        if (!attachment) {
            luaL_error(L, "Attachment not found: %s", attachmentName);
            return 0;
        }
    }

    slot->setAttachment(attachment);

    return 0;
}

    // read skeleton json
    SkeletonData *
    SkeletonJson_readSkeletonDataFile(const char *filename, Atlas *atlas, float scale)
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

