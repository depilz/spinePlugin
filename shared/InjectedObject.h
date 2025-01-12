using namespace spine;

class InjectedObject
{
private:
    String slotName;
    LuaTableHolder object;
    LuaTableHolder listener;

public:
    bool updated;

    InjectedObject(const InjectedObject &) = delete;
    InjectedObject &operator=(const InjectedObject &) = delete;

    InjectedObject()
    {
    }

    InjectedObject(const String &slotName, LuaTableHolder &object)
    {
        this->slotName = slotName;
        this->object = std::move(object);
    }

    InjectedObject(const String &slotName, LuaTableHolder &object, LuaTableHolder &listener)
    {
        this->slotName = slotName;
        this->object = std::move(object);
        this->listener = std::move(listener);
    }

    InjectedObject(InjectedObject &&other) noexcept
        : slotName(std::move(other.slotName)),
          object(std::move(other.object)),
          listener(std::move(other.listener))
    {
    }

    InjectedObject &operator=(InjectedObject &&other) noexcept
    {
        if (this != &other)
        {
            slotName = std::move(other.slotName);
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

    void setSlotName(const String &slotName)
    {
        this->slotName = slotName;
    }

    const String &getSlotName() const
    {
        return slotName;
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
        return slotName.isEmpty();
    }

    bool hasListener()
    {
        return listener.isValid();
    }
};
