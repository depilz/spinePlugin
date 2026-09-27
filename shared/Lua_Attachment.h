#pragma once

#include "CoronaLua.h"
#include "SpineCompat.h"
#include "DataHolder.h"

using namespace spine;

void getAttachmentMt(lua_State* L);

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

