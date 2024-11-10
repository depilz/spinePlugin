// SpineSkeleton.h
#ifndef SPINE_SKELETON_H
#define SPINE_SKELETON_H

#include "CoronaLua.h"
#include <string>
#include <cassert>
#include <spine/spine.h>
#include <vector>
#include "LuaTableHolder.h" // Use quotes for user-defined headers

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

// SpineSkeleton structure holds various Spine-related objects and Lua tables
struct SpineSkeleton
{
    spine::Skeleton *skeleton;
    spine::AnimationState *state;
    spine::AnimationStateData *stateData;
    spine::Atlas *atlas;
    spine::SkeletonData *skeletonData;

    LuaTableHolder group;               // Holds a Lua table for the group
    MeshManager meshes;                 // Manages a collection of Lua tables for meshes
    std::vector<int> meshIndices;

    // Default constructor
    SpineSkeleton(lua_State *L)
        : skeleton(nullptr), state(nullptr), stateData(nullptr),
          atlas(nullptr), skeletonData(nullptr), group(),
          meshes(100), meshIndices(100)
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
          group(std::move(other.group)),
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

            group = std::move(other.group);
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

            group.releaseTable();

            meshIndices.clear();
            meshes.clear();

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
int skeleton_render(lua_State *L, SpineSkeleton *skeletonUserdata, SkeletonRenderer &skeletonRenderer);
int spine_gc(lua_State *L);
int skeleton_gc(lua_State *L);

int skeleton_update(lua_State *L);
int remove_self(lua_State *L);

int skeleton_setAnimation(lua_State *L);
int skeleton_addAnimation(lua_State *L);
int skeleton_findAnimation(lua_State *L);
int skeleton_getAllAnimations(lua_State *L);

int set_default_mix(lua_State *L);
int set_mix(lua_State *L);

int skeleton_getAllSkins(lua_State *L);
int skeleton_setSkin(lua_State *L);

int skeleton_setToSetupPose(lua_State *L);

int skeleton_setAttachment(lua_State *L);

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
