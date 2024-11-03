#ifndef SPINE_TEXTURE_H
#define SPINE_TEXTURE_H

#include <spine/TextureLoader.h>
#include "CoronaLua.h"
#include "CoronaGraphics.h"

class SpineTextureLoader : public spine::TextureLoader
{
public:
    virtual void load(spine::AtlasPage &page, const spine::String &path);
    virtual void unload(void *texture);
};

#endif // SPINE_TEXTURE_H
