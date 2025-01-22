using namespace spine;

class SplitData
{
private:
    bool splitted;
    LuaTableHolder group;
    std::vector<int> slotsIndices;

public:
    Vector<RenderCommand *> commandsInSplit;
    Vector<RenderCommand *> commandsNotInSplit;

    SplitData(const SplitData &) = delete;
    SplitData &operator=(const SplitData &) = delete;

    SplitData() : splitted(false)
    {}

    bool isSplitted() const
    {
        return splitted;
    }

    void setSlotIndices(std::vector<int> &slotsIndices)
    {
        this->slotsIndices = std::move(slotsIndices);
    }

    std::vector<int> &getSlotIndices()
    {
        return slotsIndices;
    }

    void setGroup(lua_State *L, int index)
    {
        splitted = true;
        group = LuaTableHolder(L, index);
    }

    void pushGroup(lua_State *L)
    {
        group.pushTable(L);
    }

    LuaTableHolder releaseGroup()
    {
        splitted = false;
        return std::move(group);
    }

    void clear()
    {
        splitted = false;
        group.releaseTable();
        slotsIndices.clear();
    }
};
