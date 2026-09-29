// Masks comparator, on the runtime line build.sh compiles. Poses a skeleton frame by frame and compares, bit for bit,
// what the line's SkeletonRenderer::render hands the plugin (REAL) with a reference render of the same pose:
//   the editor's render loop (spine-libgdx SkeletonRenderer.draw) with the plugin's early outs: a slot on an inactive
//   bone draws nothing and ends a clip, even when it holds the clipping attachment (D-A); a bounding box, point or path
//   attachment ends a clip whose end slot it is (D-B);
//   clipped by the editor's clipper: on 4.2 the spine-libgdx port in gdxclip.cpp (C1/C3, no fused multiply-add), on
//   4.3 the line's own SkeletonClipping (upstream's, already the editor's).
// Both sides are flattened to one vertex stream (positions, uvs, color, texture, blend mode, indices), so the 4.3
// renderer's batching does not count.
//   comparator run <atlas> <skeleton .skel|.json> [--skins all] [--set slot:attachment]... [--inactive-bone bone]
//                  [--setup-attachment slot:attachment] [--need-clips]
//   comparator tri <dump_*.txt>   tritest43: the line's Triangulator on a dumped clip polygon ("poly <n> <hex floats>")
//                                 must cover it exactly (the 4.3 Triangulator's fused multiply-add flipped an ear)
// run exits 0 when every frame matched (and, with --need-clips, a clip started); tri when the triangulation is exact;
// --inactive-bone and --setup-attachment edit the loaded data: the bone becomes skin-required (bone "skin": true) and
// the slot gets the attachment in the setup pose.
#include "SpineCompat.h"
#include "gdxclip.h"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <string>
#include <vector>

using namespace spine;

SpineExtension *spine::getDefaultExtension() { return new DefaultSpineExtension(); }
struct StubLoader : public TextureLoader {
    void load(AtlasPage &page, const String &) override { page.texture = &page; }  // one texture per page
    void unload(void *) override {}
};

// Line differences of the render loop (the plugin's spc:: seam covers the rest)
#if SPINE_43()
typedef SkeletonClipping RefClip;
template <class A> static float *attachmentUVs(A &a, Slot &slot, void *&texture) {
    Sequence &sequence = a.getSequence();
    int index = sequence.resolveIndex(slot.getAppliedPose());
    texture = sequence.getRegion(index)->getRendererObject();
    return sequence.getUVs(index).buffer();
}
static void meshWorldVertices(Skeleton &skeleton, MeshAttachment &m, Slot &slot, float *out) {
    m.computeWorldVertices(skeleton, slot, 0, m.getWorldVerticesLength(), out, 0, 2);
}
#else
typedef GdxClip RefClip;
template <class A> static float *attachmentUVs(A &a, Slot &, void *&texture) {
    texture = a.getRegion()->rendererObject;
    return a.getUVs().buffer();
}
static void meshWorldVertices(Skeleton &, MeshAttachment &m, Slot &slot, float *out) {
    m.computeWorldVertices(slot, 0, m.getWorldVerticesLength(), out, 0, 2);
}
#endif

// One frame's draws as a single vertex stream
struct Stream {
    std::vector<float> positions, uvs;
    std::vector<uint32_t> colors;
    std::vector<const void *> textures;
    std::vector<int> blends;
    std::vector<size_t> indices;

    void clear() { *this = Stream(); }
    template <class I> void add(const float *pos, const float *uv, size_t vertices, const I *idx, size_t count, const void *texture, int blend) {
        size_t base = positions.size() / 2;
        positions.insert(positions.end(), pos, pos + vertices * 2);
        uvs.insert(uvs.end(), uv, uv + vertices * 2);
        textures.insert(textures.end(), vertices, texture);
        blends.insert(blends.end(), vertices, blend);
        for (size_t i = 0; i < count; i++) indices.push_back(base + idx[i]);
    }
};

// items(container): the first element of a clipper's output, std::vector (GdxClip) or spine::Vector
template <class T> static T *items(std::vector<T> &v) { return v.data(); }
template <class T> static T *items(Vector<T> &v) { return v.buffer(); }

static bool sameBits(const std::vector<float> &a, const std::vector<float> &b) {
    return a.size() == b.size() && (a.empty() || !memcmp(a.data(), b.data(), a.size() * sizeof(float)));
}

// difference(real, reference): the first stream field that differs, or null
static const char *difference(const Stream &a, const Stream &b) {
    if (a.indices != b.indices) return "indices";
    if (!sameBits(a.positions, b.positions)) return "positions";
    if (!sameBits(a.uvs, b.uvs)) return "uvs";
    if (a.colors != b.colors) return "colors";
    if (a.textures != b.textures) return "textures";
    if (a.blends != b.blends) return "blend modes";
    return nullptr;
}

// triangulationError(polygon): |sum of triangle areas - polygon area| of the line's Triangulator on the polygon, made
// clockwise as SkeletonClipping does. A triangle wound against the polygon (a misclassified ear) makes it non-zero.
static double triangulationError(Vector<float> polygon, double &polygonArea) {
    size_t n = polygon.size();
    float area = polygon[n - 2] * polygon[1] - polygon[0] * polygon[n - 1];
    for (size_t i = 0; i + 3 < n; i += 2) area += polygon[i] * polygon[i + 3] - polygon[i + 2] * polygon[i + 1];
    if (area >= 0)
        for (size_t i = 0, last = n - 2, half = n >> 1; i < half; i += 2) {
            std::swap(polygon[i], polygon[last - i]);
            std::swap(polygon[i + 1], polygon[last - i + 1]);
        }
    double twice = 0;
    for (size_t i = 0, v = n / 2; i < v; i++) {
        size_t j = (i + 1) % v;
        twice += (double)polygon[2 * i] * polygon[2 * j + 1] - (double)polygon[2 * j] * polygon[2 * i + 1];
    }
    polygonArea = std::fabs(twice) * 0.5;
    Triangulator triangulator;
    Vector<int> &triangles = triangulator.triangulate(polygon);
    double sum = 0;
    for (size_t i = 0; i + 2 < triangles.size(); i += 3) {
        const float *a = &polygon[2 * triangles[i]], *b = &polygon[2 * triangles[i + 1]], *c = &polygon[2 * triangles[i + 2]];
        sum += std::fabs(((double)b[0] - a[0]) * ((double)c[1] - a[1]) - ((double)c[0] - a[0]) * ((double)b[1] - a[1])) * 0.5;
    }
    return std::fabs(sum - polygonArea);
}

struct Counts {
    long frames = 0, mismatchFrames = 0, clipStarts = 0;
};

// The reference render of the posed skeleton into out
static void referenceFrame(Skeleton &skeleton, RefClip &clipper, Stream &out, Counts &n) {
    static unsigned short quad[6] = {0, 1, 2, 2, 3, 0};
    Vector<float> world;
    Vector<Slot *> &drawOrder = spc::drawOrder(&skeleton);
    out.clear();
    for (size_t i = 0; i < drawOrder.size(); ++i) {
        Slot &slot = *drawOrder[i];
        Attachment *attachment = spc::applied(slot).getAttachment();
        if (!attachment || !slot.getBone().isActive()) {
            clipper.clipEnd(slot);
            continue;
        }
        bool isClip = attachment->getRTTI().isExactly(ClippingAttachment::rtti);
        if ((spc::applied(slot).getColor().a == 0 || slot.getSolarColor().a == 0) && !isClip) {
            clipper.clipEnd(slot);
            continue;
        }
        if (isClip) {
            bool started = clipper.isClipping();
            clipper.clipStart(skeleton, slot, (ClippingAttachment *)attachment);
            if (!started && clipper.isClipping()) n.clipStarts++;
            continue;
        }
        Color *attachmentColor;
        const float *uvs;
        const unsigned short *triangles;
        size_t vertexCount, triangleCount;
        void *texture;
        if (attachment->getRTTI().isExactly(RegionAttachment::rtti)) {
            RegionAttachment &region = *(RegionAttachment *)attachment;
            attachmentColor = &region.getColor();
            if (attachmentColor->a == 0) {
                clipper.clipEnd(slot);
                continue;
            }
            world.setSize(8, 0);
            spc::regionWorldVertices(region, slot, world.buffer());
            uvs = attachmentUVs(region, slot, texture);
            vertexCount = 4;
            triangles = quad;
            triangleCount = 6;
        } else if (attachment->getRTTI().isExactly(MeshAttachment::rtti)) {
            MeshAttachment &mesh = *(MeshAttachment *)attachment;
            attachmentColor = &mesh.getColor();
            if (attachmentColor->a == 0) {
                clipper.clipEnd(slot);
                continue;
            }
            world.setSize(mesh.getWorldVerticesLength(), 0);
            meshWorldVertices(skeleton, mesh, slot, world.buffer());
            uvs = attachmentUVs(mesh, slot, texture);
            vertexCount = mesh.getWorldVerticesLength() >> 1;
            triangles = mesh.getTriangles().buffer();
            triangleCount = mesh.getTriangles().size();
        } else {
            clipper.clipEnd(slot);
            continue;
        }
        Color &skeletonColor = skeleton.getColor(), &slotColor = spc::applied(slot).getColor(), &solar = slot.getSolarColor();
        uint8_t r = static_cast<uint8_t>(skeletonColor.r * slotColor.r * solar.r * attachmentColor->r * 255);
        uint8_t g = static_cast<uint8_t>(skeletonColor.g * slotColor.g * solar.g * attachmentColor->g * 255);
        uint8_t b = static_cast<uint8_t>(skeletonColor.b * slotColor.b * solar.b * attachmentColor->b * 255);
        uint8_t a = static_cast<uint8_t>(skeletonColor.a * slotColor.a * solar.a * attachmentColor->a * 255);
        uint32_t color = (a << 24) | (r << 16) | (g << 8) | b;
        int blend = slot.getData().getBlendMode();
        size_t before = out.positions.size() / 2;
        if (clipper.isClipping()) {
            clipper.clipTriangles(world.buffer(), (unsigned short *)triangles, triangleCount, (float *)uvs, 2);
            out.add(items(clipper.getClippedVertices()), items(clipper.getClippedUVs()), clipper.getClippedVertices().size() / 2,
                    items(clipper.getClippedTriangles()), clipper.getClippedTriangles().size(), texture, blend);
        } else {
            out.add(world.buffer(), uvs, vertexCount, triangles, triangleCount, texture, blend);
        }
        out.colors.insert(out.colors.end(), out.positions.size() / 2 - before, color);
        clipper.clipEnd(slot);
    }
    clipper.clipEnd();
}

// What the line's renderer hands the plugin for the posed skeleton, into out
static void realFrame(Skeleton &skeleton, Stream &out) {
    static const std::vector<int> noInjections;
    SkeletonRenderer renderer;
    out.clear();
    for (RenderCommand *c = renderer.render(skeleton, noInjections); c; c = c->next) {
        out.add(c->positions, c->uvs, c->numVertices, c->indices, c->numIndices, c->texture, c->blendMode);
        out.colors.insert(out.colors.end(), c->colors, c->colors + c->numVertices);
    }
}

struct Options {
    std::vector<std::string> skins;                             // empty: the setup (no skin set)
    std::vector<std::pair<std::string, std::string>> shown;     // --set, after the skin and after every apply
    bool needClips = false;
};

static std::pair<std::string, std::string> slotAttachment(const std::string &arg) {
    size_t colon = arg.find(':');
    return {arg.substr(0, colon), colon == std::string::npos ? "" : arg.substr(colon + 1)};
}

// runAnimation: one loop of the animation at 30 fps in a fresh skeleton, both renders compared every frame
static void runAnimation(SkeletonData *data, const std::string &skin, Animation *animation, const Options &o, Counts &n) {
    Skeleton *skeleton = spc::newSkeleton(data);
    AnimationStateData *stateData = spc::newStateData(data);
    AnimationState *state = spc::newState(stateData);
    if (!skin.empty()) skeleton->setSkin(String(skin.c_str()));
    spc::setSlotsToSetupPose(skeleton);
    for (auto &s : o.shown) skeleton->setAttachment(String(s.first.c_str()), String(s.second.c_str()));
    spc::setAnimation(state, 0, animation, true);
    RefClip clipper;
    Stream real, reference;
    int frames = std::max(1, (int)std::ceil(animation->getDuration() * 30) + 1);
    for (int f = 0; f < frames; f++) {
        float delta = f == 0 ? 0 : 1.0f / 30;
        state->update(delta);
        state->apply(*skeleton);
        skeleton->update(delta);
        for (auto &s : o.shown) skeleton->setAttachment(String(s.first.c_str()), String(s.second.c_str()));
        skeleton->updateWorldTransform(Physics_Update);
        realFrame(*skeleton, real);
        const char *field = "(reference threw)";
        try {
            referenceFrame(*skeleton, clipper, reference, n);
            field = difference(real, reference);
        } catch (std::exception &) {
            clipper.clipEnd();
        }
        n.frames++;
        if (field && n.mismatchFrames++ < 3)
            fprintf(stderr, "skin %s animation %s frame %d: %s differ\n", skin.empty() ? "(setup)" : skin.c_str(),
                    animation->getName().buffer(), f, field);
    }
    delete state;
    delete stateData;
    delete skeleton;
}

static SkeletonData *load(Atlas *atlas, const std::string &path) {
    bool json = path.size() > 5 && path.compare(path.size() - 5, 5, ".json") == 0;
    SkeletonData *data;
    if (json) {
        SkeletonJson *reader = spc::newJson(atlas);
        data = reader->readSkeletonDataFile(String(path.c_str()));
        if (!data) fprintf(stderr, "cannot load %s: %s\n", path.c_str(), reader->getError().buffer());
        delete reader;
    } else {
        SkeletonBinary *reader = spc::newBinary(atlas);
        data = reader->readSkeletonDataFile(String(path.c_str()));
        if (!data) fprintf(stderr, "cannot load %s: %s\n", path.c_str(), reader->getError().buffer());
        delete reader;
    }
    return data;
}

static int run(int argc, char **argv) {
    StubLoader loader;
    Atlas atlas(String(argv[2]), &loader);
    SkeletonData *data = load(&atlas, argv[3]);
    if (!data) return 1;
    Options o;
    for (int i = 4; i < argc; i++) {
        std::string arg = argv[i], value = i + 1 < argc ? argv[i + 1] : "";
        if (arg == "--need-clips") { o.needClips = true; continue; }
        i++;
        if (arg == "--skins" && value == "all") {
            for (size_t s = 0; s < data->getSkins().size(); s++) o.skins.push_back(data->getSkins()[s]->getName().buffer());
        } else if (arg == "--set") {
            o.shown.push_back(slotAttachment(value));
        } else if (arg == "--inactive-bone" && data->findBone(String(value.c_str()))) {
            data->findBone(String(value.c_str()))->setSkinRequired(true);
        } else if (arg == "--setup-attachment" && data->findSlot(String(slotAttachment(value).first.c_str()))) {
            data->findSlot(String(slotAttachment(value).first.c_str()))->setAttachmentName(String(slotAttachment(value).second.c_str()));
        } else {
            fprintf(stderr, "comparator: bad option %s %s\n", arg.c_str(), value.c_str());
            return 2;
        }
    }
    if (o.skins.empty()) o.skins.push_back("");
    Counts n;
    Vector<Animation *> &animations = data->getAnimations();
    for (auto &skin : o.skins)
        for (size_t a = 0; a < animations.size(); a++) runAnimation(data, skin, animations[a], o, n);
    printf("frames=%ld mismatchFrames=%ld clipStarts=%ld\n", n.frames, n.mismatchFrames, n.clipStarts);
    delete data;
    return n.frames > 0 && !n.mismatchFrames && (!o.needClips || n.clipStarts) ? 0 : 1;
}

static int tri(const char *path) {
    FILE *f = fopen(path, "r");
    char tag[16], value[64];
    size_t count = 0;
    if (!f || fscanf(f, "%15s %zu", tag, &count) != 2 || strcmp(tag, "poly")) {
        fprintf(stderr, "comparator: no poly line in %s\n", path);
        return 2;
    }
    Vector<float> polygon;
    for (size_t i = 0; i < count && fscanf(f, "%63s", value) == 1; i++) polygon.add(strtof(value, nullptr));
    fclose(f);
    if (polygon.size() < 6) {
        fprintf(stderr, "comparator: %s holds no polygon\n", path);
        return 2;
    }
    double area = 0, error = triangulationError(polygon, area);
    printf("%s: area %.3f, triangulation off by %.3f\n", path, area, error);
    return error <= 1e-4 * area + 1e-3 ? 0 : 1;
}

int main(int argc, char **argv) {
    Bone::setYDown(true);  // the plugin's configuration on both lines (SPINE_PLUGIN_LUAOPEN)
    if (argc >= 4 && !strcmp(argv[1], "run")) return run(argc, argv);
    if (argc == 3 && !strcmp(argv[1], "tri")) return tri(argv[2]);
    fprintf(stderr, "usage: comparator run <atlas> <skeleton> [options] | comparator tri <dump>\n");
    return 2;
}
