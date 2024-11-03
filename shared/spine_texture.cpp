#include "spine_texture.h"
#include <string>
#include <spine/Atlas.h>
#include "Spine_renderer.h"

#import "CoronaLua.h"

void SpineTextureLoader::load(spine::AtlasPage &page, const spine::String &path)
{
    std::string *texturePath = new std::string(path.buffer());

    Texture *texture = new Texture(*texturePath);

    page.texture = texture;
}

void SpineTextureLoader::unload(void *texture)
{
    delete static_cast<std::string *>(texture);
}
