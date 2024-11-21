#include "spine_skeleton.h"
#include "spine_texture.h"
#include "spine_renderer.h"
#include "LuaUtils.h"
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

    // check if lua listener is provided
    lua_getfield(L, 1, "listener");
    int lua_listener;
    if (lua_isfunction(L, -1))
    {
        lua_listener = luaL_ref(L, LUA_REGISTRYINDEX);
    }
    else
    {
        lua_pop(L, 1);
    }

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

    if (lua_listener)
    {
        LuaAnimationStateListener *stateListener = new LuaAnimationStateListener(L, lua_listener);
        state->setListener(stateListener);
    }

    // Set metatable
    get_skeleton_metatable(L);
    lua_setmetatable(L, -2);


    // attach a display group to our userdata
    lua_getglobal(L, "display");
    lua_getfield(L, -1, "newGroup");
    lua_call(L, 0, 1);
    lua_remove(L, -2);

    lua_pushstring(L, "_skeleton");
    lua_pushvalue(L, -3);
    lua_rawset(L, -3);

    // Set the metatable
    lua_pushstring(L, "_groupmt");
    lua_getmetatable(L, -2);
    lua_rawset(L, -3);

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
            {"updateState", update_state},
            {"draw", skeleton_draw},
            {"removeSelf", remove_self},
            {"setFillColor", set_fill_color},

            {"setDefaultMix", set_default_mix},
            {"setMix", set_mix},

            {"physicsRotate", physics_rotate},
            {"physicsTranslate", physics_translate},
            {"setToSetupPose", skeleton_setToSetupPose},

            {"setAnimation", set_animation},
            {"addAnimation", add_animation},
            {"findAnimation", find_animation},
            {"getAllAnimations", get_all_animations},

            {"getAllSlots", get_all_slots},

            {"getAllSkins", get_all_skins},
            {"setSkin", set_skin},

            {"setTimeScale", set_time_scale},
            {"getTimeScale", get_time_scale},
            {"stop", skeleton_stop},

            {"setAttachment", skeleton_setAttachment},

            {"inject", inject_object},
            {"eject", eject_object},

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

// physics control
int physics_translate(lua_State *L){
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    float x = luaL_checknumber(L, 2);
    float y = luaL_checknumber(L, 3);

    skeletonUserdata->skeleton->physicsTranslate(x, -y);

    return 0;
}

int physics_rotate(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    float x = luaL_checknumber(L, 2);
    float y = luaL_checknumber(L, 3);
    float degrees = luaL_checknumber(L, 4);

    skeletonUserdata->skeleton->physicsRotate(x, y, degrees);

    return 0;
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

    skeletonUserdata->stateData->setMix(fromAnimation, toAnimation, mix/1000);
    return 0;
}

int set_animation(lua_State *L)
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

int add_animation(lua_State *L)
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

int find_animation(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    const char *animationName = luaL_checkstring(L, 2);

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);

    lua_pushboolean(L, animation != nullptr);

    return 1;
}

int get_all_animations(lua_State *L)
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

int get_all_slots(lua_State *L){
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    Skeleton *skeleton = skeletonUserdata->skeleton;
    Vector<Slot *> &slots = skeleton->getSlots();
    int n = slots.size();
    lua_createtable(L, n, 0);

    for (int i = 0; i < n; i++)
    {
        lua_pushstring(L, slots[i]->getData().getName().buffer());
        lua_rawseti(L, -2, i + 1);
    }

    return 1;
}

int get_all_skins(lua_State *L)
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

int set_skin(lua_State *L)
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

int update_state(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    float deltaTime = luaL_checknumber(L, 2);
    deltaTime /= 1000;

    // check if any tracks are playing
    if (skeletonUserdata->state->getTracks().size() == 0)
    {
        return 0;
    }

    skeletonUserdata->state->update(deltaTime);
    skeletonUserdata->state->apply(*skeletonUserdata->skeleton);
    skeletonUserdata->skeleton->update(deltaTime);

    // trigger events
    LuaUtils::executeTasks(L);

    return 0;
}

int skeleton_draw(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    skeletonUserdata->skeleton->updateWorldTransform(Physics_Update);

    skeleton_render(L, skeletonUserdata);

    return 0;
}

int set_time_scale(lua_State *L)
{
    // get skeleton
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    // get time scale
    float timeScale = luaL_checknumber(L, 2);

    // set time scale
    skeletonUserdata->state->setTimeScale(timeScale);

    return 0;
}
int get_time_scale(lua_State *L)
{
    // get skeleton
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    // get time scale
    float timeScale = skeletonUserdata->state->getTimeScale(); 

    // return time scale
    lua_pushnumber(L, timeScale);

    return 1;
}
int skeleton_stop(lua_State *L)
{
    // clear tracks
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    skeletonUserdata->state->clearTracks();

    return 0;
}

int skeleton_render(lua_State *L, SpineSkeleton * skeletonUserdata)
{
    Skeleton *skeleton = skeletonUserdata->skeleton;
    SkeletonRenderer skeletonRenderer;
    RenderCommand *command = skeletonRenderer.render(*skeleton);

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

            lua_pushvalue(L, 1);
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

    // print injection is existing
    auto &injection = skeletonUserdata->injection;
    if (!injection.isEmpty())
    {
        // get slot by name
        const char *slotName = injection.getSlotName().c_str();
        Slot *slot = skeleton->findSlot(slotName);

        injection.pushListener();
        injection.pushObject();

        lua_createtable(L, 0, 7);
        lua_pushstring(L, "slot");
        lua_pushstring(L, slotName);
        lua_settable(L, -3);

        lua_pushstring(L, "x");
        lua_pushnumber(L, slot->getBone().getWorldX());
        lua_settable(L, -3);

        lua_pushstring(L, "y");
        lua_pushnumber(L, -slot->getBone().getWorldY());
        lua_settable(L, -3);

        lua_pushstring(L, "rotation");
        lua_pushnumber(L, -slot->getBone().getWorldRotationX());
        lua_settable(L, -3);

        lua_pushstring(L, "xScale");
        lua_pushnumber(L, slot->getBone().getWorldScaleX());
        lua_settable(L, -3);

        lua_pushstring(L, "yScale");
        lua_pushnumber(L, slot->getBone().getWorldScaleY());
        lua_settable(L, -3);

        lua_pushstring(L, "alpha");
        lua_pushnumber(L, slot->getColor().a);
        lua_settable(L, -3);

        lua_call(L, 2, 0);
        lua_pop(L, 1);
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

int set_fill_color(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    lua_pop(L, 1);

    int argCount = lua_gettop(L);
    double r, g, b, a;

    if (argCount == 2)
    {
        double color = luaL_checknumber(L, 2);
        r = color;
        g = color;
        b = color;
        a = 1;

    } else if (argCount == 3)
    {
        // grayscale
        double color = luaL_checknumber(L, 2);
        r = color;
        g = color;
        b = color;
        a = luaL_checknumber(L, 3);

    } else if (argCount == 4)
    {
        r = luaL_checknumber(L, 2);
        g = luaL_checknumber(L, 3);
        b = luaL_checknumber(L, 4);
        a = 1;

    } else if (argCount == 5)
    {
        r = luaL_checknumber(L, 2);
        g = luaL_checknumber(L, 3);
        b = luaL_checknumber(L, 4);
        a = luaL_checknumber(L, 5);
    }

    skeletonUserdata->skeleton->getColor().set(r, g, b, a);

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
    skeletonUserdata->~SpineSkeleton();
    lua_pop(L, 1);

    // remove display group
    lua_pushstring(L, "_groupmt");
    lua_rawget(L, 1);
    lua_pushstring(L, "__index");
    lua_rawget(L, -2);
    lua_remove(L, -2);
    lua_pushvalue(L, 1);
    lua_pushstring(L, "removeSelf");
    lua_call(L, 2, 1);

    lua_pushvalue(L, 1);
    lua_call(L, 1, 0);

    // lua_pushnil(L);
    // lua_setmetatable(L, 1);

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

    if (strcmp(key, "isActive") == 0) {
        lua_pushboolean(L, skeletonUserdata->state->getTracks().size() > 0);
        return 1;
    }

    // Fallback to methods
    lua_getmetatable(L, 1);
    lua_pushvalue(L, 2);
    lua_rawget(L, -2);

    if (!lua_isnil(L, -1)) {
        return 1;
    }

    lua_pushstring(L, "_groupmt");
    lua_rawget(L, 1);

    lua_getfield(L, -1, "__index");
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_call(L, 2, 1);
    
    if (!lua_isnil(L, -1)) {
        return 1;
    }

    return 0;
}

// __newindex metamethod
int skeleton_newindex(lua_State* L) {
    const char* key = luaL_checkstring(L, 2);

    lua_pushstring(L, "_groupmt");
    lua_rawget(L, 1);

    lua_getfield(L, -1, "__newindex");
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_pushvalue(L, 3);
    lua_call(L, 3, 0);

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

int inject_object(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    // check if already injected
    if (!skeletonUserdata->injection.isEmpty())
    {
        luaL_error(L, "SpineObject already has an injected object");
        return 0;
    }

    // insert object into the group
    lua_getfield(L, 1, "insert");
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_call(L, 2, 0);

    // check 2 is a table
    if (!lua_istable(L, 2))
    {
        luaL_error(L, "Expected table as object");
        return 0;
    }

    LuaTableHolder object(L, 2);

    const char *slotName = luaL_checkstring(L, 3);

    if (!lua_isfunction(L, 4))
    {
        luaL_error(L, "Expected function as listener");
        return 0;
    }

    LuaTableHolder callback(L, 4);

    skeletonUserdata->injection.set(slotName, object, callback);

    return 0;
}

int eject_object(lua_State *L)
{
    lua_getfield(L, 1, "_skeleton");
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    skeletonUserdata->injection.clear();

    return 0;
}


SkeletonData * SkeletonJson_readSkeletonDataFile(const char *filename, Atlas *atlas, float scale)
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

