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
    // Constructor: Initializes the vector with 'size' LuaTableHolder instances
    MeshManager(lua_State *L, int size)
    {
        meshHolders.reserve(size);
        for (int i = 0; i < size; ++i)
        {
            meshHolders.emplace_back(L);
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
            // Utilize move assignment to avoid copy issues
            meshHolders[index] = LuaTableHolder(L);
        }
    }

    // Additional utility functions can be added here as needed
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
    std::vector<LuaTableHolder> meshes; // Holds a collection of Lua tables for meshes
    std::vector<bool> meshSet;

    // Default constructor
    SpineSkeleton()
        : skeleton(nullptr), state(nullptr), stateData(nullptr),
          atlas(nullptr), skeletonData(nullptr), group(),
          meshes()
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
            // Clean up existing resources if necessary
            // (Assuming ownership semantics; adjust as needed)
            // For example:
            // if (skeleton) { delete skeleton; }
            // Similarly for other pointers

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
        // Clean up Spine objects if this class owns them
        // For example:
        // if (skeletonData) { delete skeletonData; }
        // Similarly for other pointers
        // Ensure that LuaTableHolder destructors are called automatically
    }
};

// Function declarations
int create(lua_State *L);
int skeleton_setAnimation(lua_State *L);
int skeleton_update(lua_State *L);
int skeleton_render(lua_State *L, SpineSkeleton *skeletonUserdata, SkeletonRenderer &skeletonRenderer);
int skeleton_dispose(lua_State *L);
int skeleton_gc(lua_State *L);
int skeleton_setToSetupPose(lua_State *L);
int skeleton_index(lua_State *L);
int skeleton_newindex(lua_State *L);
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
