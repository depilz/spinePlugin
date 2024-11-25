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
