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