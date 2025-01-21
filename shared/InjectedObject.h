using namespace spine;

class InjectedObject
{
private:
    int slotIndex;
    LuaTableHolder object;
    LuaTableHolder listener;

public:
    bool updated;

    InjectedObject(const InjectedObject &) = delete;
    InjectedObject &operator=(const InjectedObject &) = delete;

    InjectedObject()
    {
    }

    InjectedObject(int slotIndex, LuaTableHolder &object)
    {
        this->slotIndex = slotIndex;
        this->object = std::move(object);
    }

    InjectedObject(int slotIndex, LuaTableHolder &object, LuaTableHolder &listener)
    {
        this->slotIndex = slotIndex;
        this->object = std::move(object);
        this->listener = std::move(listener);
    }

    InjectedObject(InjectedObject &&other) noexcept
        : slotIndex(std::move(other.slotIndex)),
          object(std::move(other.object)),
          listener(std::move(other.listener))
    {
    }

    InjectedObject &operator=(InjectedObject &&other) noexcept
    {
        if (this != &other)
        {
            slotIndex = std::move(other.slotIndex);
            object = std::move(other.object);
            listener = std::move(other.listener);
        }
        return *this;
    }

    void clear()
    {
        object.releaseTable();
        listener.releaseTable();
    }

    void setSlotIndex(int slotIndex)
    {
        this->slotIndex = slotIndex;
    }

    int getSlotIndex() const
    {
        return slotIndex;
    }

    void pushListener(lua_State *L)
    {
        listener.pushTable(L);
    }

    void pushObject(lua_State *L)
    {
        object.pushTable(L);
    }

    bool isEmpty()
    {
        return !object.isValid();
    }

    bool hasListener()
    {
        return listener.isValid();
    }
};
