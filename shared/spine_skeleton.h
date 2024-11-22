// SpineSkeleton.h
#ifndef SPINE_SKELETON_H
#define SPINE_SKELETON_H

#include "CoronaLua.h"
#include <string>
#include <cassert>
#include <spine/spine.h>
#include <vector>
#include "LuaTableHolder.h"
#include "lua_animation_state_listener.h"

using namespace spine;

// MeshManager class manages a collection of LuaTableHolder instances
class MeshManager
{
private:
    std::vector<LuaTableHolder> meshHolders;

public:
    MeshManager(int size)
    {
        meshHolders.reserve(size);
        for (int i = 0; i < size; i++)
        {
            meshHolders.push_back(LuaTableHolder());
        }
    }
    
    // Pushes the Lua table at the specified index onto the Lua stack
    void pushMesh(int index)
    {
        if (index >= 0 && index < static_cast<int>(meshHolders.size()))
        {
            meshHolders[index].pushTable();
        }
    }

    // Sets the LuaTableHolder at the specified index to a new table
    void setMesh(lua_State *L, int index)
    {
        if (index >= 0 && index < static_cast<int>(meshHolders.size()))
        {
            meshHolders[index] = LuaTableHolder(L);
        }
    }

    int isMeshValid(int index)
    {
        return index >= 0 && index < static_cast<int>(meshHolders.size()) && meshHolders[index].isValid();
    }

    LuaTableHolder &operator[](int index)
    {
        assert(index >= 0 && index < static_cast<int>(meshHolders.size()));
        return meshHolders[index];
    }
    
    void clear()
    {
        for (auto &mesh : meshHolders)
        {
            mesh.releaseTable();
        }
    }

};

class InjectedObject
{
private:
    std::string slotName;
    LuaTableHolder object;
    LuaTableHolder listener;

public:
    void set(const std::string &slotName, LuaTableHolder &object, LuaTableHolder &listener)
    {
        this->slotName = slotName;
        this->object = std::move(object);
        this->listener = std::move(listener);
    }

    void clear()
    {
        object.releaseTable();
        listener.releaseTable();
    }

    const std::string &getSlotName() const
    {
        return slotName;
    }

    void pushListener()
    {
        listener.pushTable();
    }

    void pushObject()
    {
        object.pushTable();
    }

    bool isEmpty()
    {
        return slotName.empty();
    }
};


// SpineSkeleton structure holds various Spine-related objects and Lua tables
struct SpineSkeleton
{
    spine::Skeleton *skeleton;
    spine::AnimationState *state;
    spine::AnimationStateData *stateData;
    spine::SkeletonData *skeletonData;
    LuaAnimationStateListener *stateListener;
    LuaTableHolder *groupmt__index;
    LuaTableHolder *groupmt__newindex;
    InjectedObject injection;
    int skeletonDataRef;
    lua_State *L;

    MeshManager meshes;
    std::vector<int> meshIndices;

    // Default constructor
    SpineSkeleton(lua_State *L)
        : skeleton(nullptr), state(nullptr), stateData(nullptr),
          skeletonData(nullptr),
          meshes(20), meshIndices(20),
          stateListener(nullptr), 
          groupmt__index(nullptr), groupmt__newindex(nullptr),
          injection(), skeletonDataRef(LUA_NOREF), 
          L(L)
    {
    }

    // Delete copy constructor and copy assignment operator to prevent copying
    SpineSkeleton(const SpineSkeleton &) = delete;
    SpineSkeleton &operator=(const SpineSkeleton &) = delete;

    // Implement move constructor
    SpineSkeleton(SpineSkeleton &&other) noexcept
        : skeleton(other.skeleton), state(other.state),
          stateData(other.stateData),
          skeletonData(other.skeletonData),
          meshes(std::move(other.meshes))
    {
        other.skeleton = nullptr;
        other.state = nullptr;
        other.stateData = nullptr;
        other.skeletonData = nullptr;
    }

    SpineSkeleton &operator=(SpineSkeleton &&other) noexcept
    {
        if (this != &other)
        {
            skeleton = other.skeleton;
            state = other.state;
            stateData = other.stateData;
            skeletonData = other.skeletonData;
            stateListener = other.stateListener;

            meshes = std::move(other.meshes);
            meshIndices = std::move(other.meshIndices);

            groupmt__index = std::move(other.groupmt__index);
            groupmt__newindex = std::move(other.groupmt__newindex);
            stateListener = std::move(other.stateListener);
            injection = std::move(other.injection);

            skeletonDataRef = other.skeletonDataRef;

            L = other.L;

            // Nullify the pointers in the moved-from object
            other.skeleton = nullptr;
            other.state = nullptr;
            other.stateData = nullptr;
            other.skeletonData = nullptr;
            other.groupmt__index = nullptr;
            other.groupmt__newindex = nullptr;
            other.stateListener = nullptr;
            other.skeletonDataRef = LUA_NOREF;
        }
        return *this;
    }

    ~SpineSkeleton()
    {
        if (skeleton)
        {
            delete state;
            delete stateData;
            delete skeleton;

            meshIndices.clear();
            meshes.clear();
            injection.clear();

            if (stateListener)
            {
                delete stateListener;
                stateListener = nullptr;
            }

            groupmt__index->releaseTable();
            delete groupmt__index;
            groupmt__newindex->releaseTable();
            delete groupmt__newindex;

            luaL_unref(L, LUA_REGISTRYINDEX, skeletonDataRef);
            skeletonDataRef = LUA_NOREF;

            if (stateListener)
            {
                delete stateListener;
                stateListener = nullptr;
            }            

            L = nullptr;

            skeleton = nullptr;
            state = nullptr;
            stateData = nullptr;
            skeletonData = nullptr;
        }
    }
};


int create(lua_State *L);
int load_atlas(lua_State *L);
int load_skeleton_data(lua_State *L);
void get_skeleton_metatable(lua_State *L);
void get_spineObject_metatable(lua_State *L);
int skeleton_index(lua_State *L);
int skeleton_newindex(lua_State *L);
int skeleton_render(lua_State *L, SpineSkeleton *skeletonUserdata);
int spine_gc(lua_State *L);
int skeleton_gc(lua_State *L);

int update_state(lua_State *L);
int skeleton_draw(lua_State *L);
int set_time_scale(lua_State *L);
int get_time_scale(lua_State *L);
int skeleton_stop(lua_State *L);
int set_fill_color(lua_State *L);
int remove_self(lua_State *L);

int set_animation(lua_State *L);
int add_animation(lua_State *L);
int find_animation(lua_State *L);
int get_all_animations(lua_State *L);
int get_all_slots(lua_State *L);

int physics_rotate(lua_State *L);
int physics_translate(lua_State *L);

int set_default_mix(lua_State *L);
int set_mix(lua_State *L);

int get_all_skins(lua_State *L);
int set_skin(lua_State *L);

int skeleton_setToSetupPose(lua_State *L);

int skeleton_setAttachment(lua_State *L);

int inject_object(lua_State *L);
int eject_object(lua_State *L);

SkeletonData *SkeletonJson_readSkeletonDataFile(const char *filename, Atlas *atlas, float scale);
SkeletonData *SkeletonBinary_readSkeletonDataFile(const char *filename, Atlas *atlas, float scale);

// Solar2dExtension class extending DefaultSpineExtension
class Solar2dExtension : public DefaultSpineExtension
{
public:
    Solar2dExtension();
    virtual ~Solar2dExtension();
};

#endif // SPINE_SKELETON_H
