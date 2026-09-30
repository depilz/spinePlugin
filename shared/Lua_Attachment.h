#pragma once

#include "CoronaLua.h"
#include "SpineCompat.h"
#include "DataHolder.h"

using namespace spine;

void getAttachmentMt(lua_State* L);

#if SPINE_43()
// skeleton:createAttachment's body: the attachment the table at index describes, on dataOwner's atlas, pushed.
int createRegionAttachment(lua_State *L, int table, const std::shared_ptr<DataHolder<SkeletonData>> &dataOwner);
#endif

struct LuaAttachment
{
    lua_State *L;
    Attachment *attachment;

    std::shared_ptr<DataHolder<SkeletonData>> dataOwner;

    LuaAttachment(lua_State *L, Attachment *attachment,
                  std::shared_ptr<DataHolder<SkeletonData>> dataOwner = nullptr)
        : L(L), attachment(attachment), dataOwner(dataOwner)
    {
        if (attachment) attachment->reference();
        getAttachmentMt(L);
        lua_setmetatable(L, -2);
    }

    ~LuaAttachment()
    {
        if (attachment) {
            attachment->dereference();
            if (attachment->getRefCount() == 0) delete attachment;
        }
        attachment = nullptr;
        L = nullptr;
    }
};

