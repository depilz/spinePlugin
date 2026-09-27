#pragma once
// One binding tree, two spine-cpp runtimes: the runtime on the include path (runtime/spine-4.x) decides
// through spine/Version.h, no build flag. Bindings call spc:: wherever the 4.2 and 4.3 APIs differ.
#include <spine/spine.h>
#include <spine/Version.h>
#include <utility>

// Function-like on purpose: #if SPINE_43() without this header is a preprocessor error, not a silent 0.
#define SPINE_43() (SPINE_MAJOR_VERSION > 4 || (SPINE_MAJOR_VERSION == 4 && SPINE_MINOR_VERSION >= 3))

// The Lua entry of the line's plugin: luaopen_plugin_spine42 / luaopen_plugin_spine43.
#define SPC_CAT2(a, b) a##b
#define SPC_CAT(a, b) SPC_CAT2(a, b)
#define SPINE_PLUGIN_LUAOPEN SPC_CAT(SPC_CAT(luaopen_plugin_spine, SPINE_MAJOR_VERSION), SPINE_MINOR_VERSION)

#if SPINE_43()
namespace spine { template <typename T> using Vector = Array<T>; } // 4.3 renamed Vector -> Array
#endif

namespace spc {
using namespace spine;
typedef std::pair<RenderCommand *, RenderCommand *> CommandPair;

#if SPINE_43()
// 4.3 splits bones/slots/constraints into setup data, an unconstrained pose and an applied pose.
inline BoneLocal &pose(Bone &b) { return b.getPose(); }
inline BonePose &applied(Bone &b) { return b.getAppliedPose(); }
inline SlotPose &pose(Slot &s) { return s.getPose(); }
inline SlotPose &applied(Slot &s) { return s.getAppliedPose(); }
inline IkConstraintPose &pose(IkConstraint &c) { return c.getPose(); }
inline PhysicsConstraintPose &pose(PhysicsConstraint &c) { return c.getPose(); }
inline float appliedRotation(Bone &b) { return b.getAppliedPose().getRotation(); }
inline void setAppliedRotation(Bone &b, float v) { b.getAppliedPose().setRotation(v); }
inline SkeletonData &data(Skeleton &s) { return s.getData(); }
inline Animation &anim(TrackEntry &e) { return e.getAnimation(); }
// Event values as 1.5.0 reports them: the EventData's (4.3: its setup pose), not the keyed ones.
inline Event &eventSetup(Event &e) { return const_cast<EventData &>(e.getData()).getSetupPose(); }
inline int eventInt(Event &e) { return eventSetup(e).getInt(); }
inline float eventFloat(Event &e) { return eventSetup(e).getFloat(); }
inline const String &eventString(Event &e) { return eventSetup(e).getString(); }
inline float eventVolume(Event &e) { return eventSetup(e).getVolume(); }
inline float eventBalance(Event &e) { return eventSetup(e).getBalance(); }
inline bool pathClosed(PathAttachment &p) { return p.getClosed(); }
inline bool pathConstantSpeed(PathAttachment &p) { return p.getConstantSpeed(); }
inline void regionWorldVertices(RegionAttachment &r, Slot &slot, float *out) {
    r.computeWorldVertices(slot, r.getOffsets(slot.getAppliedPose()).buffer(), out, 0, 2);
}
inline void vertexWorldVertices(VertexAttachment &v, Slot &slot, Array<float> &out) {
    v.computeWorldVertices(slot.getSkeleton(), slot, 0, v.getWorldVerticesLength(), out, 0, 2);
}
inline void addSkin(Skin *dst, Skin *src) { dst->addSkin(*src); }
inline void copySkin(Skin *dst, Skin *src) { dst->copySkin(*src); }
inline Attachment *copy(Attachment *a) { return &a->copy(); }
inline const String &entryName(Skin::AttachmentMap::Entry &e) { return e._placeholder; }
inline SkeletonJson *newJson(Atlas *a) { return new SkeletonJson(*a); }
inline SkeletonBinary *newBinary(Atlas *a) { return new SkeletonBinary(*a); }
inline Skeleton *newSkeleton(SkeletonData *d) { return new Skeleton(*d); }
inline AnimationStateData *newStateData(SkeletonData *d) { return new AnimationStateData(*d); }
inline AnimationState *newState(AnimationStateData *d) { return new AnimationState(*d); }
inline void setToSetupPose(Skeleton *s) { s->setupPose(); }
inline void setBonesToSetupPose(Skeleton *s) { s->setupPoseBones(); }
inline void setSlotsToSetupPose(Skeleton *s) { s->setupPoseSlots(); }
inline TrackEntry *setAnimation(AnimationState *st, int t, Animation *a, bool loop) { return &st->setAnimation(t, *a, loop); }
inline TrackEntry *addAnimation(AnimationState *st, int t, Animation *a, bool loop, float delay) {
    return &st->addAnimation(t, *a, loop, delay);
}
inline TrackEntry *current(AnimationState *st, int t) { return st->getTrack(t); }
inline void setMix(AnimationStateData *d, Animation *from, Animation *to, float dur) { d->setMix(*from, *to, dur); }
inline IkConstraint *findIk(Skeleton *s, const String &name) { return s->findConstraint<IkConstraint>(name); }
template <class F> void forEachIk(Skeleton *s, F f) {
    Array<Constraint *> &c = s->getConstraints();
    for (size_t i = 0; i < c.size(); i++)
        if (c[i]->getRTTI().instanceOf(IkConstraint::rtti)) f(static_cast<IkConstraint *>(c[i]));
}
template <class F> void forEachIkData(SkeletonData *d, F f) {
    Array<ConstraintData *> &c = d->getConstraints();
    for (size_t i = 0; i < c.size(); i++)
        if (c[i]->getRTTI().instanceOf(IkConstraintData::rtti)) f(c[i]);
}
inline void getBounds(Skeleton *s, float &x, float &y, float &w, float &h) { s->getBounds(x, y, w, h); }
inline Array<Slot *> &drawOrder(Skeleton *s) { return s->getDrawOrder().getAppliedPose(); }
inline Bone *boneOf(BonePose *p) { return &p->getBone(); }
inline Bone *ikTarget(IkConstraint &c) { return &c.getTarget(); }
inline void setIkTarget(IkConstraint &c, Bone *b) { c.setTarget(*b); }
inline CommandPair renderSplit(SkeletonRenderer &r, Skeleton &s, const std::vector<int> &injections,
                               const std::vector<int> &split, Array<RenderCommand *> &in, Array<RenderCommand *> &out) {
    return r.render(s, injections, split, in, out);
}
#else
// 4.2: the object is its own pose.
inline Bone &pose(Bone &b) { return b; }
inline Bone &applied(Bone &b) { return b; }
inline Slot &pose(Slot &s) { return s; }
inline Slot &applied(Slot &s) { return s; }
inline IkConstraint &pose(IkConstraint &c) { return c; }
inline PhysicsConstraint &pose(PhysicsConstraint &c) { return c; }
inline float appliedRotation(Bone &b) { return b.getAppliedRotation(); }
inline void setAppliedRotation(Bone &b, float v) { b.setAppliedRotation(v); }
inline SkeletonData &data(Skeleton &s) { return *s.getData(); }
inline Animation &anim(TrackEntry &e) { return *e.getAnimation(); }
inline int eventInt(Event &e) { return e.getData().getIntValue(); }
inline float eventFloat(Event &e) { return e.getData().getFloatValue(); }
inline const String &eventString(Event &e) { return e.getData().getStringValue(); }
inline float eventVolume(Event &e) { return e.getData().getVolume(); }
inline float eventBalance(Event &e) { return e.getData().getBalance(); }
inline bool pathClosed(PathAttachment &p) { return p.isClosed(); }
inline bool pathConstantSpeed(PathAttachment &p) { return p.isConstantSpeed(); }
inline void regionWorldVertices(RegionAttachment &r, Slot &slot, float *out) { r.computeWorldVertices(slot, out, 0, 2); }
inline void vertexWorldVertices(VertexAttachment &v, Slot &slot, Vector<float> &out) { v.computeWorldVertices(slot, out); }
inline void addSkin(Skin *dst, Skin *src) { dst->addSkin(src); }
inline void copySkin(Skin *dst, Skin *src) { dst->copySkin(src); }
inline Attachment *copy(Attachment *a) { return a->copy(); }
inline const String &entryName(Skin::AttachmentMap::Entry &e) { return e._name; }
inline SkeletonJson *newJson(Atlas *a) { return new SkeletonJson(a); }
inline SkeletonBinary *newBinary(Atlas *a) { return new SkeletonBinary(a); }
inline Skeleton *newSkeleton(SkeletonData *d) { return new Skeleton(d); }
inline AnimationStateData *newStateData(SkeletonData *d) { return new AnimationStateData(d); }
inline AnimationState *newState(AnimationStateData *d) { return new AnimationState(d); }
inline void setToSetupPose(Skeleton *s) { s->setToSetupPose(); }
inline void setBonesToSetupPose(Skeleton *s) { s->setBonesToSetupPose(); }
inline void setSlotsToSetupPose(Skeleton *s) { s->setSlotsToSetupPose(); }
inline TrackEntry *setAnimation(AnimationState *st, int t, Animation *a, bool loop) { return st->setAnimation(t, a, loop); }
inline TrackEntry *addAnimation(AnimationState *st, int t, Animation *a, bool loop, float delay) {
    return st->addAnimation(t, a, loop, delay);
}
inline TrackEntry *current(AnimationState *st, int t) { return st->getCurrent(t); }
inline void setMix(AnimationStateData *d, Animation *from, Animation *to, float dur) { d->setMix(from, to, dur); }
inline IkConstraint *findIk(Skeleton *s, const String &name) { return s->findIkConstraint(name); }
template <class F> void forEachIk(Skeleton *s, F f) {
    Vector<IkConstraint *> &c = s->getIkConstraints();
    for (size_t i = 0; i < c.size(); i++) f(c[i]);
}
template <class F> void forEachIkData(SkeletonData *d, F f) {
    Vector<IkConstraintData *> &c = d->getIkConstraints();
    for (size_t i = 0; i < c.size(); i++) f(c[i]);
}
inline void getBounds(Skeleton *s, float &x, float &y, float &w, float &h) {
    Vector<float> outVertexBuffer;
    s->getBounds(x, y, w, h, outVertexBuffer);
}
inline Vector<Slot *> &drawOrder(Skeleton *s) { return s->getDrawOrder(); }
inline Bone *boneOf(Bone *b) { return b; }
inline Bone *ikTarget(IkConstraint &c) { return c.getTarget(); }
inline void setIkTarget(IkConstraint &c, Bone *b) { c.setTarget(b); }
// The 4.2 renderer hands out a heap pair per split render, never freed (as in 1.5.0).
inline CommandPair renderSplit(SkeletonRenderer &r, Skeleton &s, const std::vector<int> &injections,
                               const std::vector<int> &split, Vector<RenderCommand *> &in, Vector<RenderCommand *> &out) {
    return *r.render(s, injections, split, in, out);
}
#endif
} // namespace spc
