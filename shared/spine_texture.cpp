#include "spine_texture.h"
#include <string>
#include <spine/Atlas.h>

void SpineTextureLoader::load(spine::AtlasPage &page, const spine::String &path)
{
    page.texture = new std::string(path.buffer());
}

void SpineTextureLoader::unload(void *texture)
{
    delete (std::string *)texture;
}
