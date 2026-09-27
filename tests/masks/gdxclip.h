// GdxClip: the 4.2 line's reference clipper (gdxclip.cpp), with the interface of spine::SkeletonClipping that the
// comparator's render loop calls.
#pragma once
#include "SpineCompat.h"
#include <vector>

#if !SPINE_43()
class GdxClip {
public:
    GdxClip();
    ~GdxClip();
    void clipStart(spine::Skeleton &skeleton, spine::Slot &slot, spine::ClippingAttachment *clip);
    void clipEnd(spine::Slot &slot);
    void clipEnd();
    void clipTriangles(float *vertices, unsigned short *triangles, size_t trianglesLength, float *uvs, size_t stride);
    bool isClipping() { return clipAttachment != nullptr; }
    std::vector<float> &getClippedVertices() { return clippedVertices; }
    std::vector<unsigned short> &getClippedTriangles() { return clippedTriangles; }
    std::vector<float> &getClippedUVs() { return clippedUvs; }

private:
    struct Tri; Tri *tri;
    std::vector<float> clippingPolygon, clipOutput, clippedVertices, clippedUvs, scratch;
    std::vector<unsigned short> clippedTriangles;
    spine::ClippingAttachment *clipAttachment = nullptr;
    std::vector<std::vector<float>> *clippingPolygons = nullptr;
    bool clip(float x1, float y1, float x2, float y2, float x3, float y3, std::vector<float> &clippingArea, std::vector<float> &output);
    static void makeClockwise(std::vector<float> &polygon);
};
#endif
