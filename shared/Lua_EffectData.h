#pragma once

#include "CoronaLua.h"
#include <string>
#include <unordered_map>
#include <vector>

// A lightweight container for effect configuration coming from Lua.
// Holds the effect name and a map of attributes, where each attribute is
// either a single number or an array of numbers.
class Lua_EffectData {
public:
    struct AttributeValue {
        enum class Type { Number, Array } type = Type::Number;
        float number = 0.0f;
        std::vector<float> array;

        static AttributeValue Number(float v) {
            AttributeValue a; a.type = Type::Number; a.number = v; return a;
        }
        static AttributeValue Array(const std::vector<float>& v) {
            AttributeValue a; a.type = Type::Array; a.array = v; return a;
        }
    };

    Lua_EffectData() = default;
    explicit Lua_EffectData(const std::string &name): name_(name) {}

    const std::string& name() const { return name_; }
    void setName(const std::string &name) { name_ = name; }

    const std::unordered_map<std::string, AttributeValue>& attributes() const { return attributes_; }
    void clearAttributes() { attributes_.clear(); }
    void setAttribute(const std::string &key, const AttributeValue &value) { attributes_[key] = value; }
    bool hasAttribute(const std::string &key) const { return attributes_.find(key) != attributes_.end(); }
    bool removeAttribute(const std::string &key) { return attributes_.erase(key) > 0; }

private:
    std::string name_;
    std::unordered_map<std::string, AttributeValue> attributes_;
};
