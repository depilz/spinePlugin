// Native microbenchmark / probes for the line's vendored spine-cpp SkeletonRenderer.
// Scratch only. Links the line's vendored runtime objects (runtime/spine-4.x/spine/*.cpp) unchanged.
//   bench [frames] [ref]   ref: only refBench per example (tools/perf/bench-ref.sh times it in the plain build)
#include "SpineCompat.h"
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <new>
#include <string>
#include <vector>
#include <map>
#include <memory>
#include <set>

using namespace spine;

// ---------- allocation counting ----------
static long g_newCount = 0, g_spineAllocCount = 0;
void *operator new(size_t n) { ++g_newCount; void *p = std::malloc(n ? n : 1); if (!p) throw std::bad_alloc(); return p; }
void *operator new[](size_t n) { ++g_newCount; void *p = std::malloc(n ? n : 1); if (!p) throw std::bad_alloc(); return p; }
void operator delete(void *p) noexcept { std::free(p); }
void operator delete[](void *p) noexcept { std::free(p); }
void operator delete(void *p, size_t) noexcept { std::free(p); }
void operator delete[](void *p, size_t) noexcept { std::free(p); }

class CountingExtension : public DefaultSpineExtension {
protected:
    void *_alloc(size_t size, const char *file, int line) override { ++g_spineAllocCount; return DefaultSpineExtension::_alloc(size, file, line); }
    void *_calloc(size_t size, const char *file, int line) override { ++g_spineAllocCount; return DefaultSpineExtension::_calloc(size, file, line); }
    void *_realloc(void *ptr, size_t size, const char *file, int line) override { ++g_spineAllocCount; return DefaultSpineExtension::_realloc(ptr, size, file, line); }
};
SpineExtension *spine::getDefaultExtension() { return new CountingExtension(); }

struct StubLoader : public TextureLoader {
    int next = 1;
    void load(AtlasPage &page, const String &) override { page.texture = (void *)(intptr_t)(next++); }
    void unload(void *) override {}
};
static StubLoader g_loader;

typedef std::chrono::high_resolution_clock Clock;
static double ms(Clock::time_point a, Clock::time_point b) { return std::chrono::duration<double, std::milli>(b - a).count(); }

struct Loaded { Atlas *atlas; SkeletonData *data; };
// read: the skeleton data at path, read (and freed) by reader; exits on a load failure
template <class Reader> static SkeletonData *read(Reader *reader, const std::string &path) {
    std::unique_ptr<Reader> owned(reader);
    SkeletonData *data = reader->readSkeletonDataFile(path.c_str());
    if (!data) { std::fprintf(stderr, "load failed %s: %s\n", path.c_str(), reader->getError().buffer()); std::exit(1); }
    return data;
}
// load(name): the example <name>/<name>.skel; loadJson(base): <base>.json; each with <base>.atlas
static Loaded load(const std::string &name) {
    std::string base = name + "/" + name;
    Atlas *atlas = new Atlas((base + ".atlas").c_str(), &g_loader, true);
    return {atlas, read(spc::newBinary(atlas), base + ".skel")};
}
static Loaded loadJson(const std::string &base) {
    Atlas *atlas = new Atlas((base + ".atlas").c_str(), &g_loader, true);
    return {atlas, read(spc::newJson(atlas), base + ".json")};
}

// Count what upstream eb6a973f9 batchCommands would produce from the vendored (never-batching) command list.
static int upstreamBatchCount(RenderCommand *cmd) {
    int n = 0;
    while (cmd) {
        RenderCommand *first = cmd; int idx = cmd->numIndices; cmd = cmd->next; n++;
        while (cmd && cmd->texture == first->texture && cmd->blendMode == first->blendMode &&
               cmd->numVertices > 0 && first->numVertices > 0 &&
               cmd->colors[0] == first->colors[0] && cmd->darkColors[0] == first->darkColors[0] &&
               idx + cmd->numIndices < 0xffff) { idx += cmd->numIndices; cmd = cmd->next; }
    }
    return n;
}

static void benchSkeleton(const std::string &name, int frames) {
    Loaded L = load(name);
    std::unique_ptr<Skeleton> ownSkeleton(spc::newSkeleton(L.data));
    Skeleton &skeleton = *ownSkeleton;
    std::unique_ptr<AnimationStateData> stateData(spc::newStateData(L.data));
    std::unique_ptr<AnimationState> ownState(spc::newState(stateData.get()));
    AnimationState &state = *ownState;
    auto &anims = L.data->getAnimations();
    SkeletonRenderer persistent;
    std::vector<int> noInj;

    double tUpd = 0, tRenderPersist = 0, tRenderNew = 0;
    long newPersist = 0, spinePersist = 0, newNew = 0, spineNew = 0;
    long darkCmds = 0; long cmds = 0, small = 0, upstream = 0, verts = 0, idxs = 0, framesTotal = 0;
    int maxSmallAnim = -1; long maxSmall = 0; std::string smallAnim;
    std::set<void *> textures;
    int slotsWithAttachment = 0;
    for (size_t ai = 0; ai < anims.size(); ++ai) {
        state.clearTracks();
        spc::setToSetupPose(&skeleton);
        spc::setAnimation(&state, 0, anims[ai], true);
        long smallThis = 0;
        for (int f = 0; f < frames; ++f) {
            float dt = 1.0f / 60.0f;
            auto t0 = Clock::now();
            state.update(dt); state.apply(skeleton); skeleton.update(dt); skeleton.updateWorldTransform(Physics_Update);
            auto t1 = Clock::now();
            long n0 = g_newCount, s0 = g_spineAllocCount;
            RenderCommand *c = persistent.render(skeleton, noInj);
            auto t2 = Clock::now();
            newPersist += g_newCount - n0; spinePersist += g_spineAllocCount - s0;
            n0 = g_newCount; s0 = g_spineAllocCount;
            auto t3 = Clock::now();
            { SkeletonRenderer fresh; RenderCommand *c2 = fresh.render(skeleton, noInj); (void)c2; }
            auto t4 = Clock::now();
            newNew += g_newCount - n0; spineNew += g_spineAllocCount - s0;
            tUpd += ms(t0, t1); tRenderPersist += ms(t1, t2); tRenderNew += ms(t3, t4);
            upstream += upstreamBatchCount(c);
            for (RenderCommand *x = c; x; x = x->next) {
                cmds++; verts += x->numVertices; idxs += x->numIndices; textures.insert(x->texture);
                if (x->numIndices < 3) { small++; smallThis++; }
                if (x->numVertices > 0 && x->darkColors[0] != 0xff000000) darkCmds++;
            }
            framesTotal++;
        }
        if (smallThis > maxSmall) { maxSmall = smallThis; smallAnim = anims[ai]->getName().buffer(); }
    }
    for (size_t i = 0; i < skeleton.getSlots().size(); ++i) if (spc::applied(*skeleton.getSlots()[i]).getAttachment()) slotsWithAttachment++;
    double F = (double)framesTotal;
    std::printf("%-17s anims=%2zu frames=%5ld | cmds/frame=%6.1f upstreamBatched/frame=%5.1f  <3idx cmds total=%4ld (worst anim '%s': %ld) | verts/frame=%6.0f idx/frame=%6.0f pages=%zu\n",
                name.c_str(), anims.size(), framesTotal, cmds / F, upstream / F, small, smallAnim.c_str(), maxSmall, verts / F, idxs / F, textures.size());
    std::printf("%-17s   tint-black commands (darkColor != black): %.1f%% of commands\n", "", cmds ? 100.0 * darkCmds / cmds : 0.0);
    std::printf("%-17s   us/frame: update+apply+uwt=%7.2f render(persistent)=%7.2f render(new per frame, as plugin)=%7.2f | allocs/frame persistent: spine=%.1f new=%.1f ; per-frame-renderer: spine=%.1f new=%.1f\n",
                "", 1000 * tUpd / F, 1000 * tRenderPersist / F, 1000 * tRenderNew / F, spinePersist / F, newPersist / F, spineNew / F, newNew / F);
}

// the pass-through renderer of tests/splitfx/ref_renderer.cpp (the line's SkeletonRenderer, never batching)
RenderCommand *refRenderCommands(Skeleton &sk, const std::vector<int> &injectionSlots);

// refBench: render() time per frame of the line's batching SkeletonRenderer vs the pass-through reference, both
// persistent, on the same poses (every animation, frames frames each); which one renders first alternates per frame
static void refBench(const std::string &name, int frames) {
    Loaded L = load(name);
    std::unique_ptr<Skeleton> ownSkeleton(spc::newSkeleton(L.data));
    Skeleton &skeleton = *ownSkeleton;
    std::unique_ptr<AnimationStateData> stateData(spc::newStateData(L.data));
    std::unique_ptr<AnimationState> ownState(spc::newState(stateData.get()));
    AnimationState &state = *ownState;
    auto &anims = L.data->getAnimations();
    SkeletonRenderer batched;
    std::vector<int> noInj;
    double t[2] = {0, 0}; long cmds[2] = {0, 0}, n = 0; // [0] batched, [1] pass-through
    for (size_t ai = 0; ai < anims.size(); ++ai) {
        state.clearTracks();
        spc::setToSetupPose(&skeleton);
        spc::setAnimation(&state, 0, anims[ai], true);
        for (int f = 0; f < frames; ++f, ++n) {
            float dt = 1.0f / 60.0f;
            state.update(dt); state.apply(skeleton); skeleton.update(dt); skeleton.updateWorldTransform(Physics_Update);
            for (int k = 0; k < 2; ++k) {
                int which = (k + n) % 2;
                auto t0 = Clock::now();
                RenderCommand *c = which ? refRenderCommands(skeleton, noInj) : batched.render(skeleton, noInj);
                t[which] += ms(t0, Clock::now());
                for (; c; c = c->next) cmds[which]++;
            }
        }
    }
    double F = (double)n;
    std::printf("ref %s us/frame batched=%.2f passthrough=%.2f cmds/frame batched=%.1f passthrough=%.1f frames=%ld\n",
                name.c_str(), 1000 * t[0] / F, 1000 * t[1] / F, cmds[0] / F, cmds[1] / F, n);
}

// ---------- physics gravity direction probe ----------
static void gravityProbe() {
    Loaded L = load("cloud-pot");
    const char *boneName = "rain-blue";
    bool lineYDown = Bone::isYDown();
    struct Cfg { const char *label; float scaleY; bool yDown; };
    Cfg cfgs[] = {{"y-up reference (scaleY=+1, yDown=false)", 1, false},
                  {"plugin 1.5.0 (scaleY=-1, yDown=false)", -1, false},
                  {"upstream y-down (scaleY=+1, Bone::setYDown(true))", 1, true}};
    std::printf("\nGravity probe: cloud-pot bone '%s' (physics constraint rain/rain-blue: x,y, strength 0, gravity 70), setup pose, no animation, 30 frames @60Hz, Physics_Update\n", boneName);
    for (auto &cfg : cfgs) {
        Bone::setYDown(cfg.yDown);
        std::unique_ptr<Skeleton> owned(spc::newSkeleton(L.data));
        Skeleton &sk = *owned; sk.setScaleY(cfg.scaleY); spc::setToSetupPose(&sk);
        sk.updateWorldTransform(Physics_Reset);
        Bone *b = sk.findBone(boneName);
        float y0 = spc::applied(*b).getWorldY();
        for (int f = 0; f < 30; ++f) { sk.update(1 / 60.f); sk.updateWorldTransform(Physics_Update); }
        float y1 = spc::applied(*b).getWorldY();
        // world space is y-down when effective scaleY (getScaleY) < 0
        bool worldYDown = sk.getScaleY() < 0;
        float screenDown = worldYDown ? (y1 - y0) : (y0 - y1);
        std::printf("  %-52s worldY %8.2f -> %8.2f  => moved %s on screen by %.2f units\n", cfg.label, y0, y1, screenDown > 0 ? "DOWN" : "UP", std::fabs(screenDown));
    }
    Bone::setYDown(lineYDown);
}

// ---------- sequence probe ----------
// the line's sequence rig (the base path of its JSON export), the animation and the slot it keys a sequence on. 4.3: the
// diamond example under the cwd; 4.2 has no Esoteric sequence rig: the generated fixture, found from this source's path.
struct SequenceRig { std::string base; const char *animation, *slot; };
static SequenceRig sequenceRig() {
#if SPINE_43()
    return {"diamond/diamond", "idle-still", "top-shine"};
#else
    std::string dir = __FILE__;
    return {dir.substr(0, dir.rfind('/')) + "/../lifecycle/assets/4.2/sequence/sequence", "flip", "seq"};
#endif
}

// sequenceRegion: the region a region or mesh sequence attachment shows on the slot, nullptr without a sequence
template <class A> static void *sequenceRegion(Slot &slot, A &a) {
#if SPINE_43()
    Sequence &seq = a.getSequence();
    return seq.getRegions().size() > 1 ? seq.getRegion(seq.resolveIndex(slot.getAppliedPose())) : nullptr;
#else
    (void)slot;
    return a.getSequence() ? a.getRegion() : nullptr;
#endif
}

static void sequenceProbe() {
    SequenceRig rig = sequenceRig();
    Loaded L = loadJson(rig.base);
    std::unique_ptr<Skeleton> owned(spc::newSkeleton(L.data));
    Skeleton &sk = *owned;
    std::unique_ptr<AnimationStateData> sd(spc::newStateData(L.data));
    std::unique_ptr<AnimationState> ownState(spc::newState(sd.get()));
    AnimationState &st = *ownState;
    spc::setAnimation(&st, 0, L.data->findAnimation(rig.animation), true);
    SkeletonRenderer r; std::vector<int> none;
    std::map<std::string, std::set<void *>> regions;
    std::set<std::pair<void *, float>> texUv;
    for (int f = 0; f < 120; ++f) {
        st.update(1 / 60.f); st.apply(sk); sk.update(1 / 60.f); sk.updateWorldTransform(Physics_Update);
        RenderCommand *c = r.render(sk, none);
        for (; c; c = c->next) texUv.insert({c->texture, c->uvs[0]});
        for (size_t i = 0; i < sk.getSlots().size(); ++i) {
            Slot &slot = *sk.getSlots()[i];
            Attachment *a = spc::applied(slot).getAttachment();
            void *region = nullptr;
            if (a && a->getRTTI().isExactly(RegionAttachment::rtti)) region = sequenceRegion(slot, *(RegionAttachment *)a);
            else if (a && a->getRTTI().isExactly(MeshAttachment::rtti)) region = sequenceRegion(slot, *(MeshAttachment *)a);
            if (region) regions[slot.getData().getName().buffer()].insert(region);
        }
    }
    std::printf("\nSequence probe (%s, anim '%s', 120 frames):\n", rig.base.c_str(), rig.animation);
    for (auto &kv : regions) std::printf("  slot %-14s distinct regions rendered: %zu\n", kv.first.c_str(), kv.second.size());
    if (regions[rig.slot].size() < 2) { std::fprintf(stderr, "sequence probe: slot %s rendered fewer than 2 regions\n", rig.slot); std::exit(1); }
}

int main(int argc, char **argv) {
    Bone::setYDown(true); // the plugin's configuration (SPINE_PLUGIN_LUAOPEN in shared/Lua_Spine.cpp)
    int frames = argc > 1 ? std::atoi(argv[1]) : 300;
    const char *names[] = {"spineboy", "raptor", "goblins", "mix-and-match", "alien", "coin", "tank", "powerup",
                           "celestial-circus", "cloud-pot", "sack", "snowglobe", "chibi-stickers", "owl", "stretchyman", "vine", "windmill", "speedy"};
    const char *only = getenv("ONLY");
    bool ref = argc > 2 && !std::strcmp(argv[2], "ref");
    for (const char *n : names) if (!only || strstr(only, n)) (ref ? refBench : benchSkeleton)(n, frames);
    if (only || ref) return 0;
    gravityProbe();
    sequenceProbe();
    return 0;
}
