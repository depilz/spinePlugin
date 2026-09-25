#include "spine/spine.h"
#include "spine/Extension.h"
#include <cassert>
#include <cstdio>
using namespace spine;
SpineExtension *spine::getDefaultExtension() { return new DefaultSpineExtension(); }

static int regionsDeleted = 0;
static int meshesDeleted = 0;
struct CountedRegion : RegionAttachment {
    CountedRegion() : RegionAttachment("region") {}
    ~CountedRegion() override { ++regionsDeleted; }
};
struct CountedMesh : MeshAttachment {
    CountedMesh() : MeshAttachment("parent") {}
    ~CountedMesh() override { ++meshesDeleted; }
};

int main() {
    for (int i = 0; i < 100; ++i) {
        SkeletonData data;
        auto *bone = new BoneData(0, "root", nullptr);
        data.getBones().add(bone);
        auto *slotData = new SlotData(0, "slot", *bone);
        slotData->setAttachmentName("key");
        data.getSlots().add(slotData);
        Skin skin("temporary");
        auto *region = new CountedRegion();
        skin.setAttachment(0, "key", region);
        Skeleton skeleton(&data);
        skeleton.setSkin(&skin);
        Slot *slot = skeleton.getSlots()[0];
        region->reference(); // the same reference held by a Lua attachment wrapper
        skin.removeAttachment(0, "key");
        assert(regionsDeleted == i);
        assert(slot->getAttachment() == region);
        slot->setAttachment(nullptr);
        assert(regionsDeleted == i);
        region->dereference();
        assert(region->getRefCount() == 0);
        delete region;
        assert(regionsDeleted == i + 1);

        auto *parent = new CountedMesh();
        skin.setAttachment(0, "mesh", parent);
        MeshAttachment *linked = parent->newLinkedMesh();
        Skin copied("copy");
        copied.setAttachment(0, "mesh", linked);
        slot->setAttachment(linked);
        skin.removeAttachment(0, "mesh");
        copied.removeAttachment(0, "mesh");
        assert(meshesDeleted == i);
        assert(linked->getParentMesh()->getName() == "parent");
        assert(linked->getTimelineAttachment() == parent);
        // Further copying must remain valid after all source entries disappear.
        Attachment *next = linked->copy();
        slot->setAttachment(next);
        assert(meshesDeleted == i);
        slot->setAttachment(nullptr);
        assert(meshesDeleted == i + 1);

        // Setup resets release the displayed attachment even without a default skin.
        auto *last = new RegionAttachment("last");
        slot->setAttachment(last);
        skeleton.setSkin((Skin *)nullptr);
        slot->setToSetupPose();
        assert(slot->getAttachment() == nullptr);
    }
    std::puts("Native attachment lifetime regressions passed (100 cycles)");
}
