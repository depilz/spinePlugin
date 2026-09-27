#pragma once
// Skins-test accessors for native model state the bindings never read, on either runtime line; the plugin's own
// line seam (shared/SpineCompat.h, spc::) covers the rest. Included by skins_fixture.cpp and skins_probe.cpp.
#include "SpineCompat.h"
#include <spine/DeformTimeline.h>
#include <spine/SequenceTimeline.h>

namespace skc {
using namespace spine;

#if SPINE_43()
inline MeshAttachment *parentMesh(MeshAttachment &m) { return m.getSourceMesh(); }
// 4.3 gives every region and mesh a Sequence; the export declared one iff it has a path suffix.
inline bool hasSequence(RegionAttachment &r) { return r.getSequence().hasPathSuffix(); }
inline bool hasSequence(MeshAttachment &m) { return m.getSequence().hasPathSuffix(); }
inline Attachment *timelineAttachment(DeformTimeline &t) { return &t.getAttachment(); }
inline Attachment *timelineAttachment(SequenceTimeline &t) { return &t.getAttachment(); }
inline size_t updateCacheCount(Skeleton &s) { return s.getUpdateCache().size(); }
// f(kind, name, active) per constraint. Constraint::_active (set by updateCache) is protected, so active means
// updateCache sorted it in; PosedActive::isActive() is not cleared by updateCache on 4.3.
template <class F> void forEachConstraint(Skeleton &s, F f) {
    Array<Constraint *> &cs = s.getConstraints();
    Array<Update *> &cache = s.getUpdateCache();
    for (size_t i = 0; i < cs.size(); i++) {
        const RTTI &t = cs[i]->getRTTI();
        const char *kind = t.instanceOf(IkConstraint::rtti)          ? "ik"
                           : t.instanceOf(TransformConstraint::rtti) ? "transform"
                           : t.instanceOf(PathConstraint::rtti)      ? "path"
                           : t.instanceOf(PhysicsConstraint::rtti)   ? "physics"
                                                                     : "slider";
        f(kind, cs[i]->getData().getName(), cache.contains(static_cast<Update *>(cs[i])));
    }
}
#else
inline MeshAttachment *parentMesh(MeshAttachment &m) { return m.getParentMesh(); }
inline bool hasSequence(RegionAttachment &r) { return r.getSequence() != nullptr; }
inline bool hasSequence(MeshAttachment &m) { return m.getSequence() != nullptr; }
inline Attachment *timelineAttachment(DeformTimeline &t) { return t.getAttachment(); }
inline Attachment *timelineAttachment(SequenceTimeline &t) { return t.getAttachment(); }
inline size_t updateCacheCount(Skeleton &s) { return s.getUpdateCacheList().size(); }
template <class F, class C> void forEachOf(Vector<C *> &cs, const char *kind, F f) {
    for (size_t i = 0; i < cs.size(); i++) f(kind, cs[i]->getData().getName(), cs[i]->isActive());
}
template <class F> void forEachConstraint(Skeleton &s, F f) {
    forEachOf(s.getIkConstraints(), "ik", f);
    forEachOf(s.getTransformConstraints(), "transform", f);
    forEachOf(s.getPathConstraints(), "path", f);
    forEachOf(s.getPhysicsConstraints(), "physics", f);
}
#endif
} // namespace skc
