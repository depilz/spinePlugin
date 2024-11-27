#include "Lua_Skeleton.h"
#include "Lua_Slot.h"
#include "SpineRenderer.h"

static SpineSkeleton *luaL_getSkeletonUserdata(lua_State *L)
{
    // check first argument is a table
    if (!lua_istable(L, 1))
    {
        luaL_argerror(L, 1, "SpineSkeleton expected. If this is a function call, you might have used '.' instead of ':'");
        return 0;
    }

    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);

    if (lua_isnil(L, -1))
    {
        luaL_argerror(L, 1, "SpineSkeleton expected, got table");
        return 0;
    }

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");
    
    lua_pop(L, 1);

    return skeletonUserdata;
}

void getSkeletonMt(lua_State *L){
    luaL_getmetatable(L, "SpineSkeleton");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "SpineSkeleton");

        lua_pushcfunction(L, skeleton_gc);
        lua_setfield(L, -2, "__gc");
    }
}

void getSpineObjectMt(lua_State *L)
{
    luaL_getmetatable(L, "SpineObject");
    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "SpineObject");

        lua_pushstring(L, "__index");
        lua_pushcfunction(L, skeleton_index);
        lua_settable(L, -3);

        lua_pushstring(L, "__newindex");
        lua_pushcfunction(L, skeleton_newindex);
        lua_settable(L, -3);

        luaL_Reg methods[] = {
            {"updateState", updateState},
            {"draw", skeletonDraw},
            {"removeSelf", removeSelf},
            {"setFillColor", setFillColor},

            {"setDefaultMix", setDefaultMix},
            {"setMix", setMix},

            {"physicsRotate", physicsRotate},
            {"physicsTranslate", physicsTranslate},
            {"setToSetupPose", setToSetupPose},

            {"setAnimation", setAnimation},
            {"addAnimation", addAnimation},
            {"findAnimation", findAnimation},
            {"getCurrentAnimation", getCurrentAnimation},
            {"getAnimations", getAnimations},

            {"getSlot", getSlot},
            {"getSlotNames", getSlotNames},

            {"getIKConstraint", getIKConstraint},

            {"getSkins", getSkins},
            {"setSkin", setSkin},

            {"setTimeScale", setTimeScale},
            {"getTimeScale", getTimeScale},
            {"clearTracks", clearTracks},

            {"setAttachment", setAttachment},
            {"getAttachments", getAttachments},

            {"inject", injectObject},
            {"eject", ejectObject},

            {NULL, NULL}};
        luaL_register(L, NULL, methods);
    }
}

int skeleton_index(lua_State *L)
{
    const char *key = luaL_checkstring(L, 2);

    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    if (strcmp(key, "isActive") == 0)
    {
        lua_pushboolean(L, skeletonUserdata->state->getTracks().size() > 0);
        return 1;
    }

    // Fallback to methods
    lua_getmetatable(L, 1);
    lua_pushvalue(L, 2);
    lua_rawget(L, -2);

    if (!lua_isnil(L, -1))
    {
        return 1;
    }

    skeletonUserdata->groupmt__index->pushTable();
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_call(L, 2, 1);

    if (!lua_isnil(L, -1))
    {
        return 1;
    }

    return 0;
}

int skeleton_newindex(lua_State *L)
{
    lua_pushstring(L, "_skeleton");
    lua_rawget(L, 1);

    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, -1, "SpineSkeleton");

    skeletonUserdata->groupmt__newindex->pushTable();
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_pushvalue(L, 3);
    lua_call(L, 3, 0);

    return 0;
}

int skeleton_gc(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = (SpineSkeleton *)luaL_checkudata(L, 1, "SpineSkeleton");

    if (skeletonUserdata->skeleton)
    {
        skeletonUserdata->~SpineSkeleton();
    }

    return 0;
}




// skeleton:getSkins()
int getSkins(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

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

// skeleton:setSkin(skinName)
int setSkin(lua_State *L)
{
    if (lua_gettop(L) != 2)
    {
        luaL_error(L, "Expected 2 arguments: self, skinName");
        return 0;
    }

    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    const char *skinName = luaL_checkstring(L, 2);

    Skeleton *skeleton = skeletonUserdata->skeleton;
    SkeletonData *skeletonData = skeletonUserdata->skeletonData;

    if (!skinName)
    {
        luaL_argerror(L, 2, "Skin name is required");
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




// skeleton:setToSetupPose()
int setToSetupPose(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    skeletonUserdata->skeleton->setToSetupPose();

    return 0;
}




// skeleton:setAnimation(trackIndex, animationName, loop)
int setAnimation(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
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

// skeleton:addAnimation(trackIndex, animationName, loop, delay)
int addAnimation(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
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

// skeleton:findAnimation(animationName)
int findAnimation(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
    const char *animationName = luaL_checkstring(L, 2);

    Animation *animation = skeletonUserdata->skeletonData->findAnimation(animationName);

    lua_pushboolean(L, animation != nullptr);

    return 1;
}

// skeleton:getCurrentAnimation()
int getCurrentAnimation(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    TrackEntry *entry = skeletonUserdata->state->getCurrent(0);
    if (!entry)
    {
        lua_pushnil(L);
        return 1;
    }

    const char *animationName = entry->getAnimation()->getName().buffer();
    lua_pushstring(L, animationName);

    return 1;
}

// skeleton:getAnimations()
int getAnimations(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

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



// skeleton:setDefaultMix(mix)
int setDefaultMix(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    float mix = luaL_checknumber(L, 2);

    skeletonUserdata->stateData->setDefaultMix(mix);
}

// skeleton:setMix(from, to, mix)
int setMix(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

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

    skeletonUserdata->stateData->setMix(fromAnimation, toAnimation, mix / 1000);
    return 0;
}





// skeleton:updateState(deltaTime)
int updateState(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }
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

    return 0;
}

// skeleton:draw()
int skeletonDraw(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    skeletonUserdata->skeleton->updateWorldTransform(Physics_Update);

    skeletonRender(L, skeletonUserdata);

    return 0;
}

void skeletonRender(lua_State *L, SpineSkeleton *skeletonUserdata)
{
    Skeleton *skeleton = skeletonUserdata->skeleton;
    SkeletonRenderer skeletonRenderer;
    RenderCommand *command = skeletonRenderer.render(*skeleton);
    LuaTableHolder *newMesh = skeletonUserdata->newMesh;

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
        size_t numVertices = command->numVertices;
        size_t numIndices = command->numIndices;

        BlendMode blendMode = command->blendMode;

        bool existingMesh = meshes.isMeshValid(i);

        if (existingMesh)
        {
            LuaTableHolder &mesh = meshes[i];
            if (meshIndices[i] != numIndices)
            {
                engine_removeMesh(L, &mesh);
                existingMesh = false;
                mesh.releaseTable();
            }
            else
            {
                engine_updateMesh(L, &mesh, positions, numVertices, uvs, indices, numIndices, texture, blendMode, colors);
            }
        }

        if (!existingMesh)
        {
            engine_drawMesh(L, positions, numVertices, uvs, indices, numIndices, texture, blendMode, colors, newMesh);

            lua_pushvalue(L, 1);
            skeletonUserdata->groupInsert->pushTable();
            lua_pushvalue(L, -2);
            lua_pushnumber(L, i + 1);
            lua_pushvalue(L, -5);
            lua_call(L, 3, 0);
            lua_pop(L, 1);

            meshes.setMesh(L, i);
            meshIndices[i] = numIndices;

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

    auto &injection = skeletonUserdata->injection;
    if (!injection.isEmpty())
    {
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
}


// skeleton:setAttachment(slotName, attachmentName)
int setAttachment(lua_State *L) {
    if (lua_gettop(L) != 3) {
        luaL_error(L, "Expected 3 arguments: self, slotName, attachmentName");
        return 0;
    }

    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    const char *slotName = luaL_checkstring(L, 2);
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


// skeleton:getAttachments(slot)
int getAttachments(lua_State *L)
{
    SpineSkeleton* skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata) {
        return 0;
    }

    const char* slotName = luaL_checkstring(L, 2);

    Slot* slot = skeletonUserdata->skeleton->findSlot(slotName);
    if (!slot) {
        luaL_error(L, "Slot not found: %s", slotName);
        return 0;
    }
//
//    Skin* skin = skeletonUserdata->skeleton->getSkin();
//    const Vector<const char*>& attachmentNames = skin->getAttachments(slot->getData().getIndex());
//    int n = attachmentNames.size();
//    lua_createtable(L, n, 0);
//
//    for (int i = 0; i < n; i++) {
//        lua_pushstring(L, attachmentNames[i]);
//        lua_rawseti(L, -2, i + 1);
//    }

    return 1;
}

// skeleton:getSlot(slotName)
int getSlot(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    const char *slotName = luaL_checkstring(L, 2);

    Slot *slot = skeletonUserdata->skeleton->findSlot(slotName);

    if (!slot)
    {
        luaL_error(L, "Slot not found: %s", slotName);
        return 0;
    }

    LuaSlot *slotUserdata = (LuaSlot *)lua_newuserdata(L, sizeof(LuaSlot));
    new (slotUserdata) LuaSlot(L, slot);

    return 1;
}


// skeleton:getSlotNames()
int getSlotNames(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

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

// skeleton:getIKConstraint(ikConstraintName)
int getIKConstraint(lua_State *L)
{
    return 1;
}



// skeleton:setTimeScale(timeScale)
int setTimeScale(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    float timeScale = luaL_checknumber(L, 2);
    skeletonUserdata->state->setTimeScale(timeScale);

    return 0;
}

// skeleton:getTimeScale()
int getTimeScale(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    float timeScale = skeletonUserdata->state->getTimeScale(); 
    lua_pushnumber(L, timeScale);

    return 1;
}





// skeleton:physicsTranslate(x, y)
int physicsTranslate(lua_State *L){
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    float x = luaL_checknumber(L, 2);
    float y = luaL_checknumber(L, 3);

    skeletonUserdata->skeleton->physicsTranslate(x, -y);

    return 0;
}

// skeleton:physicsRotate(x, y, degrees)
int physicsRotate(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    float x = luaL_checknumber(L, 2);
    float y = luaL_checknumber(L, 3);
    float degrees = luaL_checknumber(L, 4);

    skeletonUserdata->skeleton->physicsRotate(x, y, degrees);

    return 0;
}




// skeleton:setFillColor(r, g, b, a)
int setFillColor(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    int argCount = lua_gettop(L);
    double r, g, b, a;

    switch (argCount)
    {
    case 1:
        luaL_argerror(L, 2, "number expected, got nil");
        return 0;
    case 2:
        r = luaL_checknumber(L, 2);
        g = r;
        b = r;
        a = r;
        break;
    case 3:
        r = luaL_checknumber(L, 2);
        g = r;
        b = r;
        a = luaL_checknumber(L, 3);
        break;
    case 4:
        r = luaL_checknumber(L, 2);
        g = luaL_checknumber(L, 3);
        b = luaL_checknumber(L, 4);
        a = 1;
        break;
    default:
        r = luaL_checknumber(L, 2);
        g = luaL_checknumber(L, 3);
        b = luaL_checknumber(L, 4);
        a = luaL_checknumber(L, 5);
        break;
    }


    skeletonUserdata->skeleton->getColor().set(r, g, b, a);

    return 0;
}



// skeleton:inject(slotName, object, listener)
int injectObject(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    if (!skeletonUserdata->injection.isEmpty())
    {
        luaL_error(L, "SpineObject already has an injected object");
        return 0;
    }

    skeletonUserdata->groupInsert->pushTable();
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_call(L, 2, 0);

    if (!lua_istable(L, 2))
    {
        luaL_argerror(L, 3, "Expected displayObject");
        return 0;
    }

    LuaTableHolder object(L, 2);

    const char *slotName = luaL_checkstring(L, 3);

    if (!lua_isfunction(L, 4))
    {
        luaL_argerror(L, 4, "Expected listener function");
        return 0;
    }

    LuaTableHolder callback(L, 4);

    skeletonUserdata->injection.set(slotName, object, callback);

    return 0;
}

// skeleton:eject()
int ejectObject(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    skeletonUserdata->injection.clear();

    return 0;
}



// skeleton:clearTracks()
int clearTracks(lua_State *L)
{
    SpineSkeleton *skeletonUserdata = luaL_getSkeletonUserdata(L);
    if (!skeletonUserdata)
    {
        return 0;
    }

    skeletonUserdata->state->clearTracks();

    return 0;
}

// skeleton:removeSelf()
int removeSelf(lua_State *L)
{
    if (!lua_istable(L, 1))
    {
        luaL_error(L, "SpineSkeleton expected. If this is a function call, you might have used '.' instead of ':'");
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

    skeletonUserdata->groupRemoveSelf->pushTable();
    lua_pushvalue(L, 1);
    lua_call(L, 1, 0);

    // lua_pushnil(L);
    // lua_setmetatable(L, 1);

    skeletonUserdata->~SpineSkeleton();

    return 0;
}

