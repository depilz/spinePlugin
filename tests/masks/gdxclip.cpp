// The 4.2 line's reference clipper: a C++ port of spine-libgdx 4.2 (e7dc1435f) utils/SkeletonClipping.java
// (clipStart/clipEnd/clipTrianglesUnpacked/clip/makeClockwise) and utils/Triangulator.java, i.e. the editor's clipping.
// Java semantics kept: short indices, ShortArray.setSize(negative) throws, setSize(smaller) truncates. build.sh compiles
// it with -ffp-contract=off (Java never fuses multiply-add). The 4.3 line's reference is its own SkeletonClipping.
#include "gdxclip.h"
#if !SPINE_43()
#include <cmath>
#include <stdexcept>

using namespace spine;

struct GdxClip::Tri {
    std::vector<std::vector<float>> convexPolygons;
    std::vector<std::vector<short>> convexPolygonsIndices;
    std::vector<short> indices;
    std::vector<bool> isConcaveArray;
    std::vector<short> triangles;

    static bool positiveArea(float p1x, float p1y, float p2x, float p2y, float p3x, float p3y) {
        return p1x * (p3y - p2y) + p2x * (p1y - p3y) + p3x * (p2y - p1y) >= 0;
    }
    static int winding(float p1x, float p1y, float p2x, float p2y, float p3x, float p3y) {
        float px = p2x - p1x, py = p2y - p1y;
        return p3x * py - p3y * px + px * p1y - p1x * py >= 0 ? 1 : -1;
    }
    static bool isConcave(int index, int vertexCount, const float *vertices, const short *indices) {
        int previous = indices[(vertexCount + index - 1) % vertexCount] << 1;
        int current = indices[index] << 1;
        int next = indices[(index + 1) % vertexCount] << 1;
        return !positiveArea(vertices[previous], vertices[previous + 1], vertices[current], vertices[current + 1], vertices[next],
                             vertices[next + 1]);
    }

    std::vector<short> &triangulate(std::vector<float> &verticesArray) {
        const float *vertices = verticesArray.data();
        int vertexCount = (int) verticesArray.size() >> 1;
        indices.assign(vertexCount, 0);
        for (short i = 0; i < vertexCount; i++) indices[i] = i;
        isConcaveArray.assign(vertexCount, false);
        for (int i = 0, n = vertexCount; i < n; ++i) isConcaveArray[i] = isConcave(i, vertexCount, vertices, indices.data());
        triangles.clear();
        while (vertexCount > 3) {
            int previous = vertexCount - 1, i = 0, next = 1;
            while (true) {
                bool brokeOuter = false;
                if (!isConcaveArray[i]) {
                    int p1 = indices[previous] << 1, p2 = indices[i] << 1, p3 = indices[next] << 1;
                    float p1x = vertices[p1], p1y = vertices[p1 + 1];
                    float p2x = vertices[p2], p2y = vertices[p2 + 1];
                    float p3x = vertices[p3], p3y = vertices[p3 + 1];
                    for (int ii = (next + 1) % vertexCount; ii != previous; ii = (ii + 1) % vertexCount) {
                        if (!isConcaveArray[ii]) continue;
                        int v = indices[ii] << 1;
                        float vx = vertices[v], vy = vertices[v + 1];
                        if (positiveArea(p3x, p3y, p1x, p1y, vx, vy)) {
                            if (positiveArea(p1x, p1y, p2x, p2y, vx, vy)) {
                                if (positiveArea(p2x, p2y, p3x, p3y, vx, vy)) { brokeOuter = true; break; }
                            }
                        }
                    }
                    if (!brokeOuter) break;
                }
                if (next == 0) {
                    do {
                        if (!isConcaveArray[i]) break;
                        i--;
                    } while (i > 0);
                    break;
                }
                previous = i;
                i = next;
                next = (next + 1) % vertexCount;
            }
            triangles.push_back(indices[(vertexCount + i - 1) % vertexCount]);
            triangles.push_back(indices[i]);
            triangles.push_back(indices[(i + 1) % vertexCount]);
            indices.erase(indices.begin() + i);
            isConcaveArray.erase(isConcaveArray.begin() + i);
            vertexCount--;
            int previousIndex = (vertexCount + i - 1) % vertexCount;
            int nextIndex = i == vertexCount ? 0 : i;
            isConcaveArray[previousIndex] = isConcave(previousIndex, vertexCount, vertices, indices.data());
            isConcaveArray[nextIndex] = isConcave(nextIndex, vertexCount, vertices, indices.data());
        }
        if (vertexCount == 3) {
            triangles.push_back(indices[2]);
            triangles.push_back(indices[0]);
            triangles.push_back(indices[1]);
        }
        return triangles;
    }

    std::vector<std::vector<float>> &decompose(std::vector<float> &verticesArray, std::vector<short> &tris) {
        const float *vertices = verticesArray.data();
        convexPolygons.clear();
        convexPolygonsIndices.clear();
        std::vector<short> polygonIndices;
        std::vector<float> polygon;
        int fanBaseIndex = -1, lastWinding = 0;
        for (size_t i = 0, n = tris.size(); i < n; i += 3) {
            int t1 = tris[i] << 1, t2 = tris[i + 1] << 1, t3 = tris[i + 2] << 1;
            float x1 = vertices[t1], y1 = vertices[t1 + 1];
            float x2 = vertices[t2], y2 = vertices[t2 + 1];
            float x3 = vertices[t3], y3 = vertices[t3 + 1];
            bool merged = false;
            if (fanBaseIndex == t1) {
                int o = (int) polygon.size() - 4;
                const float *p = polygon.data();
                int winding1 = winding(p[o], p[o + 1], p[o + 2], p[o + 3], x3, y3);
                int winding2 = winding(x3, y3, p[0], p[1], p[2], p[3]);
                if (winding1 == lastWinding && winding2 == lastWinding) {
                    polygon.push_back(x3);
                    polygon.push_back(y3);
                    polygonIndices.push_back((short) t3);
                    merged = true;
                }
            }
            if (!merged) {
                if (!polygon.empty()) {
                    convexPolygons.push_back(polygon);
                    convexPolygonsIndices.push_back(polygonIndices);
                }
                polygon.clear();
                polygon.push_back(x1); polygon.push_back(y1);
                polygon.push_back(x2); polygon.push_back(y2);
                polygon.push_back(x3); polygon.push_back(y3);
                polygonIndices.clear();
                polygonIndices.push_back((short) t1);
                polygonIndices.push_back((short) t2);
                polygonIndices.push_back((short) t3);
                lastWinding = winding(x1, y1, x2, y2, x3, y3);
                fanBaseIndex = t1;
            }
        }
        if (!polygon.empty()) {
            convexPolygons.push_back(polygon);
            convexPolygonsIndices.push_back(polygonIndices);
        }
        for (int i = 0, n = (int) convexPolygons.size(); i < n; i++) {
            std::vector<short> &pi = convexPolygonsIndices[i];
            if (pi.empty()) continue;
            int firstIndex = pi.front();
            int lastIndex = pi.back();
            std::vector<float> &poly = convexPolygons[i];
            int o = (int) poly.size() - 4;
            float prevPrevX = poly[o], prevPrevY = poly[o + 1];
            float prevX = poly[o + 2], prevY = poly[o + 3];
            float firstX = poly[0], firstY = poly[1];
            float secondX = poly[2], secondY = poly[3];
            int wind = winding(prevPrevX, prevPrevY, prevX, prevY, firstX, firstY);
            for (int ii = 0; ii < n; ii++) {
                if (ii == i) continue;
                std::vector<short> &otherIndices = convexPolygonsIndices[ii];
                if (otherIndices.size() != 3) continue;
                int otherFirstIndex = otherIndices[0];
                int otherSecondIndex = otherIndices[1];
                int otherLastIndex = otherIndices[2];
                std::vector<float> &otherPoly = convexPolygons[ii];
                float x3 = otherPoly[otherPoly.size() - 2], y3 = otherPoly[otherPoly.size() - 1];
                if (otherFirstIndex != firstIndex || otherSecondIndex != lastIndex) continue;
                int winding1 = winding(prevPrevX, prevPrevY, prevX, prevY, x3, y3);
                int winding2 = winding(x3, y3, firstX, firstY, secondX, secondY);
                if (winding1 == wind && winding2 == wind) {
                    otherPoly.clear();
                    otherIndices.clear();
                    poly.push_back(x3);
                    poly.push_back(y3);
                    pi.push_back((short) otherLastIndex);
                    prevPrevX = prevX;
                    prevPrevY = prevY;
                    prevX = x3;
                    prevY = y3;
                    ii = 0;
                }
            }
        }
        for (int i = (int) convexPolygons.size() - 1; i >= 0; i--) {
            if (convexPolygons[i].empty()) {
                convexPolygons.erase(convexPolygons.begin() + i);
                convexPolygonsIndices.erase(convexPolygonsIndices.begin() + i);
            }
        }
        return convexPolygons;
    }
};

GdxClip::GdxClip() : tri(new Tri()) {}
GdxClip::~GdxClip() { delete tri; }

void GdxClip::clipStart(Skeleton &, Slot &slot, ClippingAttachment *clip) {
    if (clipAttachment != nullptr) return;
    int n = (int) clip->getWorldVerticesLength();
    if (n < 6) return;
    clipAttachment = clip;
    clippingPolygon.assign(n, 0);
    clip->computeWorldVertices(slot, 0, n, clippingPolygon.data(), 0, 2);
    makeClockwise(clippingPolygon);
    std::vector<short> &triangles = tri->triangulate(clippingPolygon);
    clippingPolygons = &tri->decompose(clippingPolygon, triangles);
    for (auto &polygon : *clippingPolygons) {
        makeClockwise(polygon);
        polygon.push_back(polygon[0]);
        polygon.push_back(polygon[1]);
    }
}

void GdxClip::clipEnd(Slot &slot) {
    if (clipAttachment != nullptr && clipAttachment->getEndSlot() == &slot.getData()) clipEnd();
}

void GdxClip::clipEnd() {
    if (clipAttachment == nullptr) return;
    clipAttachment = nullptr;
    clippingPolygons = nullptr;
    clippedVertices.clear();
    clippedUvs.clear();
    clippedTriangles.clear();
    clippingPolygon.clear();
}

// clipTrianglesUnpacked(vertices, 0, triangles, trianglesLength, uvs); stride fixed at 2 in libgdx.
void GdxClip::clipTriangles(float *vertices, unsigned short *triangles, size_t trianglesLength, float *uvs, size_t) {
    std::vector<std::vector<float>> &polygons = *clippingPolygons;
    int polygonsCount = (int) polygons.size();
    short index = 0;
    clippedVertices.clear();
    clippedUvs.clear();
    clippedTriangles.clear();
    for (size_t i = 0; i < trianglesLength; i += 3) {
        int vertexOffset = triangles[i] << 1;
        float x1 = vertices[vertexOffset], y1 = vertices[vertexOffset + 1];
        float u1 = uvs[vertexOffset], v1 = uvs[vertexOffset + 1];
        vertexOffset = triangles[i + 1] << 1;
        float x2 = vertices[vertexOffset], y2 = vertices[vertexOffset + 1];
        float u2 = uvs[vertexOffset], v2 = uvs[vertexOffset + 1];
        vertexOffset = triangles[i + 2] << 1;
        float x3 = vertices[vertexOffset], y3 = vertices[vertexOffset + 1];
        float u3 = uvs[vertexOffset], v3 = uvs[vertexOffset + 1];
        for (int p = 0; p < polygonsCount; p++) {
            int s = (int) clippedVertices.size();
            if (clip(x1, y1, x2, y2, x3, y3, polygons[p], clipOutput)) {
                int clipOutputLength = (int) clipOutput.size();
                if (clipOutputLength == 0) continue;
                float d0 = y2 - y3, d1 = x3 - x2, d2 = x1 - x3, d4 = y3 - y1;
                float d = 1 / (d0 * d2 + d1 * (y1 - y3));
                int clipOutputCount = clipOutputLength >> 1;
                clippedVertices.resize(s + clipOutputCount * 2);
                clippedUvs.resize(s + clipOutputCount * 2);
                for (int ii = 0; ii < clipOutputLength; ii += 2, s += 2) {
                    float x = clipOutput[ii], y = clipOutput[ii + 1];
                    clippedVertices[s] = x;
                    clippedVertices[s + 1] = y;
                    float c0 = x - x3, c1 = y - y3;
                    float a = (d0 * c0 + d1 * c1) * d;
                    float b = (d4 * c0 + d2 * c1) * d;
                    float cc = 1 - a - b;
                    clippedUvs[s] = u1 * a + u2 * b + u3 * cc;
                    clippedUvs[s + 1] = v1 * a + v2 * b + v3 * cc;
                }
                s = (int) clippedTriangles.size();
                int newSize = s + 3 * (clipOutputCount - 2);
                if (newSize < 0) throw std::runtime_error("gdx ShortArray.setSize negative");
                clippedTriangles.resize(newSize);
                clipOutputCount--;
                for (int ii = 1; ii < clipOutputCount; ii++, s += 3) {
                    clippedTriangles[s] = index;
                    clippedTriangles[s + 1] = (short) (index + ii);
                    clippedTriangles[s + 2] = (short) (index + ii + 1);
                }
                index += clipOutputCount + 1;
            } else {
                clippedVertices.resize(s + 3 * 2);
                clippedUvs.resize(s + 3 * 2);
                clippedVertices[s] = x1; clippedVertices[s + 1] = y1;
                clippedVertices[s + 2] = x2; clippedVertices[s + 3] = y2;
                clippedVertices[s + 4] = x3; clippedVertices[s + 5] = y3;
                clippedUvs[s] = u1; clippedUvs[s + 1] = v1;
                clippedUvs[s + 2] = u2; clippedUvs[s + 3] = v2;
                clippedUvs[s + 4] = u3; clippedUvs[s + 5] = v3;
                s = (int) clippedTriangles.size();
                clippedTriangles.resize(s + 3);
                clippedTriangles[s] = index;
                clippedTriangles[s + 1] = (short) (index + 1);
                clippedTriangles[s + 2] = (short) (index + 2);
                index += 3;
                break;
            }
        }
    }
}

bool GdxClip::clip(float x1, float y1, float x2, float y2, float x3, float y3, std::vector<float> &clippingArea,
                   std::vector<float> &out) {
    std::vector<float> *originalOutput = &out, *output = &out;
    bool clipped = false;
    std::vector<float> *input;
    if (clippingArea.size() % 4 >= 2) {
        input = output;
        output = &scratch;
    } else
        input = &scratch;
    input->clear();
    input->push_back(x1); input->push_back(y1);
    input->push_back(x2); input->push_back(y2);
    input->push_back(x3); input->push_back(y3);
    input->push_back(x1); input->push_back(y1);
    output->clear();
    int clippingVerticesLast = (int) clippingArea.size() - 4;
    const float *clippingVertices = clippingArea.data();
    for (int i = 0;; i += 2) {
        float edgeX = clippingVertices[i], edgeY = clippingVertices[i + 1];
        float ex = edgeX - clippingVertices[i + 2], ey = edgeY - clippingVertices[i + 3];
        int outputStart = (int) output->size();
        const float *inputVertices = input->data(); // input and output never alias inside one pass (only output grows)
        for (int ii = 0, nn = (int) input->size() - 2; ii < nn;) {
            float inputX = inputVertices[ii], inputY = inputVertices[ii + 1];
            ii += 2;
            float inputX2 = inputVertices[ii], inputY2 = inputVertices[ii + 1];
            bool s2 = ey * (edgeX - inputX2) > ex * (edgeY - inputY2);
            float s1 = ey * (edgeX - inputX) - ex * (edgeY - inputY);
            if (s1 > 0) {
                if (s2) {
                    output->push_back(inputX2);
                    output->push_back(inputY2);
                    continue;
                }
                float ix = inputX2 - inputX, iy = inputY2 - inputY, t = s1 / (ix * ey - iy * ex);
                if (t >= 0 && t <= 1) {
                    output->push_back(inputX + ix * t);
                    output->push_back(inputY + iy * t);
                } else {
                    output->push_back(inputX2);
                    output->push_back(inputY2);
                    continue;
                }
            } else if (s2) {
                float ix = inputX2 - inputX, iy = inputY2 - inputY, t = s1 / (ix * ey - iy * ex);
                if (t >= 0 && t <= 1) {
                    output->push_back(inputX + ix * t);
                    output->push_back(inputY + iy * t);
                    output->push_back(inputX2);
                    output->push_back(inputY2);
                } else {
                    output->push_back(inputX2);
                    output->push_back(inputY2);
                    continue;
                }
            }
            clipped = true;
        }
        if (outputStart == (int) output->size()) {
            originalOutput->clear();
            return true;
        }
        float o0 = (*output)[0], o1 = (*output)[1];
        output->push_back(o0);
        output->push_back(o1);
        if (i == clippingVerticesLast) break;
        std::vector<float> *temp = output;
        output = input;
        output->clear();
        input = temp;
    }
    if (originalOutput != output) {
        originalOutput->assign(output->begin(), output->end() - 2);
    } else
        originalOutput->resize(originalOutput->size() - 2);
    return clipped;
}

void GdxClip::makeClockwise(std::vector<float> &polygon) {
    float *vertices = polygon.data();
    int verticeslength = (int) polygon.size();
    float area = vertices[verticeslength - 2] * vertices[1] - vertices[0] * vertices[verticeslength - 1], p1x, p1y, p2x, p2y;
    for (int i = 0, n = verticeslength - 3; i < n; i += 2) {
        p1x = vertices[i];
        p1y = vertices[i + 1];
        p2x = vertices[i + 2];
        p2y = vertices[i + 3];
        area += p1x * p2y - p2x * p1y;
    }
    if (area < 0) return;
    for (int i = 0, lastX = verticeslength - 2, n = verticeslength >> 1; i < n; i += 2) {
        float x = vertices[i], y = vertices[i + 1];
        int other = lastX - i;
        vertices[i] = vertices[other];
        vertices[i + 1] = vertices[other + 1];
        vertices[other] = x;
        vertices[other + 1] = y;
    }
}
#endif
