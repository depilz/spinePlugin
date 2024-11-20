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

// injected object
// if an object is injected into the skeleton, it will be set to the corresponding slot and will trigger the listener on every update
// it is used as follows:
// injection:set("slotName", object, luaListener)
// where object is a display object
// then later in the render we first get the slot name and keep an eye on it
// injection:getSlotName()
// once we find the slot, we call the listener with sharing the relevant information
// injection:pushListener()
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
    spine::Atlas *atlas;
    spine::SkeletonData *skeletonData;
    LuaAnimationStateListener *stateListener;
    InjectedObject injection;

    MeshManager meshes;
    std::vector<int> meshIndices;

    // Default constructor
    SpineSkeleton(lua_State *L)
        : skeleton(nullptr), state(nullptr), stateData(nullptr),
          atlas(nullptr), skeletonData(nullptr),
          meshes(20), meshIndices(20),
          stateListener(nullptr), injection()
    {
    }

    // Delete copy constructor and copy assignment operator to prevent copying
    SpineSkeleton(const SpineSkeleton &) = delete;
    SpineSkeleton &operator=(const SpineSkeleton &) = delete;

    // Implement move constructor
    SpineSkeleton(SpineSkeleton &&other) noexcept
        : skeleton(other.skeleton), state(other.state),
          stateData(other.stateData), atlas(other.atlas),
          skeletonData(other.skeletonData),
          meshes(std::move(other.meshes))
    {
        // Nullify the pointers in the moved-from object to prevent double deletion
        other.skeleton = nullptr;
        other.state = nullptr;
        other.stateData = nullptr;
        other.atlas = nullptr;
        other.skeletonData = nullptr;
    }

    // Implement move assignment operator
    SpineSkeleton &operator=(SpineSkeleton &&other) noexcept
    {
        if (this != &other)
        {
            skeleton = other.skeleton;
            state = other.state;
            stateData = other.stateData;
            atlas = other.atlas;
            skeletonData = other.skeletonData;

            meshes = std::move(other.meshes);

            // Nullify the pointers in the moved-from object
            other.skeleton = nullptr;
            other.state = nullptr;
            other.stateData = nullptr;
            other.atlas = nullptr;
            other.skeletonData = nullptr;
        }
        return *this;
    }

    // Destructor
    ~SpineSkeleton()
    {
        if (skeleton)
        {
            delete state;
            delete stateData;
            delete skeleton;
            delete skeletonData;
            delete atlas;

            meshIndices.clear();
            meshes.clear();
            injection.clear();

            if (stateListener)
            {
                delete stateListener;
                stateListener = nullptr;
            }

            skeleton = nullptr;
            state = nullptr;
            stateData = nullptr;
            atlas = nullptr;
            skeletonData = nullptr;
        }
    }
};

// Function declarations
int create(lua_State *L);
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
