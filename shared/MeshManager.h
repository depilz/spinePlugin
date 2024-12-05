#include <vector>
#include <cassert>
#include "LuaTableHolder.h"
#include "Texture.h"


struct MeshData
{
    LuaTableHolder mesh;
    int index;
    size_t numIndices;
    Texture *texture;
    spine::BlendMode blendMode;
    uint32_t *colors; // You might need to copy this if it's an array
    bool used;        // Flag to indicate if the mesh was used in the current frame
};

class MeshManager
{
private:
    std::vector<MeshData> meshDataList;

public:
    MeshManager(int size)
    {
        meshDataList.reserve(size);
        for (int i = 0; i < size; i++)
        {
            meshDataList.push_back(MeshData());
        }
    }

    size_t size() const
    {
        size_t count = 0;
        for (const auto &meshData : meshDataList)
        {
            if (meshData.mesh.isValid())
            {
                ++count;
            }
        }
        return count;
    }

    // Pushes the Lua table at the specified index onto the Lua stack
    void pushMesh(int index)
    {
        if (index >= 0 && index < static_cast<int>(meshDataList.size()))
        {
            meshDataList[index].mesh.pushTable();
        }
    }

    void newMesh(lua_State *L, int index, size_t numIndices, Texture *texture, spine::BlendMode blendMode, uint32_t *colors, bool used)
    {
        for (auto &meshData : meshDataList)
        {
            if (!meshData.mesh.isValid())
            {
                meshData.mesh = LuaTableHolder(L);
                meshData.index = index;
                meshData.numIndices = numIndices;
                meshData.texture = texture;
                meshData.blendMode = blendMode;
                meshData.colors = colors;
                meshData.used = used;
                return;
            }
        }

        // If no empty slot was found, add a new mesh
        meshDataList.push_back({LuaTableHolder(L), index, numIndices, texture, blendMode, colors, used});
    }

    bool isMeshValid(int index) const
    {
        return index >= 0 &&
               index < static_cast<int>(meshDataList.size()) &&
               meshDataList[index].mesh.isValid();
    }

    MeshData &operator[](int index)
    {
        if (index >= static_cast<int>(meshDataList.size()))
        {
            meshDataList.resize(index + 1);
        }
        return meshDataList[index];
    }

    void removeMesh(int index)
    {
        // if (index >= 0 && index < static_cast<int>(meshDataList.size()))
        // {
            meshDataList[index].mesh.releaseTable();
            meshDataList[index].index = -1;
            meshDataList[index].numIndices = 0;
            meshDataList[index].texture = nullptr;
            meshDataList[index].colors = nullptr;
            meshDataList[index].used = false;
        // }
    }

    void clear()
    {
        for (auto &meshData : meshDataList)
        {
            meshData.mesh.releaseTable();
        }

        meshDataList.clear();
    }

    // Add begin() and end() member functions
    std::vector<MeshData>::iterator begin() { return meshDataList.begin(); }
    std::vector<MeshData>::iterator end() { return meshDataList.end(); }
    std::vector<MeshData>::const_iterator begin() const { return meshDataList.begin(); }
    std::vector<MeshData>::const_iterator end() const { return meshDataList.end(); }

    // Add erase() member function
    std::vector<MeshData>::iterator erase(std::vector<MeshData>::const_iterator position)
    {
        return meshDataList.erase(position);
    }
};
