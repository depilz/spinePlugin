#include <cstddef>
#include "CoronaLua.h"
#include <string>
#include "BlendMode.h"

// A single vertex with UV
struct Vertex {
   // Position in x/y plane
   float x, y;

   // UV coordinates
   float u, v;

   // Packed RGBA color
    unsigned int color;
};

// Define the Texture struct to hold a Lua reference
struct Texture
{
    const char *path;

    // Constructor to create a Texture with a given path
    Texture(const std::string &pathStr)
    {
        path = new char[pathStr.length() + 1]; // Allocate memory for the path
        strcpy((char *)path, pathStr.c_str()); // Copy the string into the allocated memory
    }

    // Destructor to clean up the allocated memory
    ~Texture()
    {
        delete[] path; // Free the allocated memory for the path
    }

    // Copy constructor to handle copying of Texture objects
    Texture(const Texture &other)
    {
        path = new char[strlen(other.path) + 1];
        strcpy((char *)path, other.path);
    }

    // Assignment operator to handle assignment of Texture objects
    Texture &operator=(const Texture &other)
    {
        if (this != &other)
        {
            delete[] path; // Free existing path
            path = new char[strlen(other.path) + 1];
            strcpy((char *)path, other.path);
        }
        return *this;
    }
};

#include "spine_skeleton.h"

// Draw the given mesh.
// - vertices is a pointer to an array of Vertex structures
// - indices is a pointer to an array of indices. Consecutive indices of 3 form a triangle.
// - numIndices the number of indices, must be divisible by 3, as there are 3 vertices in a triangle.
// - texture the texture to use
// - blendMode the blend mode to use
void engine_drawMesh(lua_State *L, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, Texture *texture, spine::BlendMode blendMode, uint32_t *colors);
void engine_updateMesh(lua_State *L, LuaTableHolder *meshHolder, float *positions, size_t numVertices, float *uvs, unsigned short *indices, size_t numIndices, Texture *texture, spine::BlendMode blendMode, uint32_t *colors);
