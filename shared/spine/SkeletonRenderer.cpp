/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated July 28, 2023. Replaces all prior versions.
 *
 * Copyright (c) 2013-2023, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software or
 * otherwise create derivative works of the Spine Runtimes (collectively,
 * "Products"), provided that each user of the Products must obtain their own
 * Spine Editor license and redistribution of the Products in any form must
 * include this license and copyright notice.
 *
 * THE SPINE RUNTIMES ARE PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES,
 * BUSINESS INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THE
 * SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#include <spine/SkeletonRenderer.h>
#include <spine/Skeleton.h>
#include <spine/Slot.h>
#include <spine/SlotData.h>
#include <spine/RegionAttachment.h>
#include <spine/MeshAttachment.h>
#include <spine/ClippingAttachment.h>
#include <spine/Bone.h>

using namespace spine;

SkeletonRenderer::SkeletonRenderer() : _allocator(4096), _worldVertices(), _quadIndices(), _clipping(), _renderCommands() {
	_quadIndices.add(0);
	_quadIndices.add(1);
	_quadIndices.add(2);
	_quadIndices.add(2);
	_quadIndices.add(3);
	_quadIndices.add(0);
}

SkeletonRenderer::~SkeletonRenderer() {
}


static RenderCommand *createRenderCommand(BlockAllocator &allocator,
                                          int numVertices,
                                          int32_t numIndices,
                                          BlendMode blendMode,
                                          void *texture)
{
    void *mem = allocator.allocate<RenderCommand>(1);

    RenderCommand *cmd = new (mem) RenderCommand();
    cmd->positions = allocator.allocate<float>(numVertices << 1);
    cmd->uvs = allocator.allocate<float>(numVertices << 1);
    cmd->colors = allocator.allocate<uint32_t>(numVertices);
    cmd->darkColors = allocator.allocate<uint32_t>(numVertices);
    cmd->numVertices = numVertices;
    cmd->indices = allocator.allocate<uint16_t>(numIndices);
    cmd->numIndices = numIndices;
    cmd->blendMode = blendMode;
    cmd->texture = texture;
    cmd->next = nullptr;

    return cmd;
}

static RenderCommand *batchSubCommands(BlockAllocator &allocator, Vector<RenderCommand *> &commands, int first, int last, int numVertices, int numIndices) {
	RenderCommand *batched = createRenderCommand(allocator, numVertices, numIndices, commands[first]->blendMode, commands[first]->texture);
	float *positions = batched->positions;
	float *uvs = batched->uvs;
	uint32_t *colors = batched->colors;
	uint32_t *darkColors = batched->darkColors;
	uint16_t *indices = batched->indices;
	int indicesOffset = 0;
	for (int i = first; i <= last; i++) {
		RenderCommand *cmd = commands[i];

        if (cmd->injectionSlotName.length() > 0)
        {
            batched->injectionSlotName = cmd->injectionSlotName;
        }

        memcpy(positions, cmd->positions, sizeof(float) * 2 * cmd->numVertices);
		memcpy(uvs, cmd->uvs, sizeof(float) * 2 * cmd->numVertices);
		memcpy(colors, cmd->colors, sizeof(int32_t) * cmd->numVertices);
		memcpy(darkColors, cmd->darkColors, sizeof(int32_t) * cmd->numVertices);
		for (int ii = 0; ii < cmd->numIndices; ii++)
			indices[ii] = cmd->indices[ii] + indicesOffset;
		indicesOffset += cmd->numVertices;
		positions += 2 * cmd->numVertices;
		uvs += 2 * cmd->numVertices;
		colors += cmd->numVertices;
		darkColors += cmd->numVertices;
		indices += cmd->numIndices;
	}
	return batched;
}

static RenderCommand *batchCommands(BlockAllocator &allocator, Vector<RenderCommand *> &commands) {
	if (commands.size() == 0) return nullptr;

	RenderCommand *root = nullptr;
	RenderCommand *last = nullptr;

	RenderCommand *first = commands[0];
	int startIndex = 0;
	int i = 1;
	int numVertices = first->numVertices;
	int numIndices = first->numIndices;
	while (i <= (int) commands.size()) {
		RenderCommand *cmd = i < (int) commands.size() ? commands[i] : nullptr;

		if (cmd && cmd->numVertices == 0 && cmd->numIndices == 0) {
			i++;
			continue;
		}

        if (cmd != nullptr && cmd->texture == first->texture &&
            (first->injectionSlotName.length() == 0 && cmd->injectionSlotName.length() == 0) &&
            cmd->blendMode == first->blendMode &&
            cmd->colors[0] == first->colors[0] &&
            cmd->darkColors[0] == first->darkColors[0] &&
            numIndices + cmd->numIndices < 0xffff)
        {
            numVertices += cmd->numVertices;
			numIndices += cmd->numIndices;
        }
        else
        {
            RenderCommand *batched = batchSubCommands(allocator, commands, startIndex, i - 1, numVertices, numIndices);
			if (!last) {
				root = last = batched;
			} else {
				last->next = batched;
				last = batched;
			}
			if (i == (int) commands.size()) break;
			first = commands[i];
			startIndex = i;
			numVertices = first->numVertices;
			numIndices = first->numIndices;
        }
        i++;
	}
	return root;
}

RenderCommand *SkeletonRenderer::render(Skeleton &skeleton, const std::vector<String> &injectionSlotNames) {
    _allocator.compress();
    _renderCommands.clear();

    SkeletonClipping &clipper = _clipping;

    for (unsigned i = 0; i < skeleton.getSlots().size(); ++i)
    {
        Slot &slot = *skeleton.getDrawOrder()[i];
        Attachment *attachment = slot.getAttachment();
        if (!attachment)
        {
            clipper.clipEnd(slot);
            continue;
        }

        // Early out if the slot color is 0 or the bone is not active,
        // unless it's a clipping attachment.
        if ((slot.getColor().a == 0 || !slot.getBone().isActive()) &&
            !attachment->getRTTI().isExactly(ClippingAttachment::rtti))
        {
            clipper.clipEnd(slot);
            continue;
        }

        Vector<float> *worldVertices = &_worldVertices;
        Vector<unsigned short> *quadIndices = &_quadIndices;
        Vector<float> *vertices = worldVertices;
        int32_t verticesCount;
        Vector<float> *uvs;
        Vector<unsigned short> *indices;
        int32_t indicesCount;
        Color *attachmentColor;
        void *texture = nullptr;

        if (attachment->getRTTI().isExactly(RegionAttachment::rtti))
        {
            RegionAttachment *regionAttachment = (RegionAttachment *)attachment;
            attachmentColor = &regionAttachment->getColor();
            if (attachmentColor->a == 0)
            {
                // Even if alpha is zero, we may need a dummy command if this slot is an injection slot
                bool isInjectionSlot = false;
                for (size_t si = 0; si < injectionSlotNames.size(); si++)
                {
                    if (slot.getData().getName() == injectionSlotNames[si])
                    {
                        isInjectionSlot = true;
                        break;
                    }
                }
                if (isInjectionSlot)
                {
                    RenderCommand *cmd = createRenderCommand( _allocator, 0, 0, slot.getData().getBlendMode(), nullptr);
                    cmd->injectionSlotName = slot.getData().getName();
                    _renderCommands.add(cmd);
                }
                clipper.clipEnd(slot);
                continue;
            }
            worldVertices->setSize(8, 0);
            regionAttachment->computeWorldVertices(slot, *worldVertices, 0, 2);
            verticesCount = 4;
            uvs = &regionAttachment->getUVs();
            indices = quadIndices;
            indicesCount = 6;
            texture = regionAttachment->getRegion()->rendererObject;
        }
        else if (attachment->getRTTI().isExactly(MeshAttachment::rtti))
        {
            MeshAttachment *mesh = (MeshAttachment *)attachment;
            attachmentColor = &mesh->getColor();
            if (attachmentColor->a == 0)
            {
                clipper.clipEnd(slot);
                continue;
            }
            worldVertices->setSize(mesh->getWorldVerticesLength(), 0);
            mesh->computeWorldVertices(slot, 0, mesh->getWorldVerticesLength(),
                                       worldVertices->buffer(), 0, 2);
            verticesCount = (int32_t)(mesh->getWorldVerticesLength() >> 1);
            uvs = &mesh->getUVs();
            indices = &mesh->getTriangles();
            indicesCount = (int32_t)(indices->size());
            texture = mesh->getRegion()->rendererObject;
        }
        else if (attachment->getRTTI().isExactly(ClippingAttachment::rtti))
        {
            ClippingAttachment *clip = (ClippingAttachment *)slot.getAttachment();
            clipper.clipStart(slot, clip);
            continue;
        }
        else
        {
            continue;
        }

        uint8_t r = static_cast<uint8_t>(skeleton.getColor().r *
                                         slot.getColor().r *
                                         attachmentColor->r * 255);
        uint8_t g = static_cast<uint8_t>(skeleton.getColor().g *
                                         slot.getColor().g *
                                         attachmentColor->g * 255);
        uint8_t b = static_cast<uint8_t>(skeleton.getColor().b *
                                         slot.getColor().b *
                                         attachmentColor->b * 255);
        uint8_t a = static_cast<uint8_t>(skeleton.getColor().a *
                                         slot.getColor().a *
                                         attachmentColor->a * 255);

        uint32_t color = (a << 24) | (r << 16) | (g << 8) | b;
        uint32_t darkColor = 0xff000000;
        if (slot.hasDarkColor())
        {
            Color &slotDarkColor = slot.getDarkColor();
            darkColor = 0xff000000 | (static_cast<uint8_t>(slotDarkColor.r * 255) << 16) | (static_cast<uint8_t>(slotDarkColor.g * 255) << 8) | (static_cast<uint8_t>(slotDarkColor.b * 255));
        }

        if (clipper.isClipping())
        {
            clipper.clipTriangles(*worldVertices, *indices, *uvs, 2);
            vertices = &clipper.getClippedVertices();
            verticesCount = (int32_t)(clipper.getClippedVertices().size() >> 1);
            uvs = &clipper.getClippedUVs();
            indices = &clipper.getClippedTriangles();
            indicesCount = (int32_t)(clipper.getClippedTriangles().size());
        }

        RenderCommand *cmd = createRenderCommand(
            _allocator,
            verticesCount,
            indicesCount,
            slot.getData().getBlendMode(),
            texture);

        // scan the vector of injectionSlotNames
        bool isInjectionSlot = false;
        for (size_t si = 0; si < injectionSlotNames.size(); si++)
        {
            if (slot.getData().getName() == injectionSlotNames[si])
            {
                isInjectionSlot = true;
                break;
            }
        }

        if (isInjectionSlot)
        {
            cmd->injectionSlotName = slot.getData().getName();
        }

        _renderCommands.add(cmd);
        memcpy(cmd->positions, vertices->buffer(), (verticesCount << 1) * sizeof(float));
        memcpy(cmd->uvs, uvs->buffer(), (verticesCount << 1) * sizeof(float));

        for (int ii = 0; ii < verticesCount; ii++)
        {
            cmd->colors[ii] = color;
            cmd->darkColors[ii] = darkColor;
        }
        memcpy(cmd->indices, indices->buffer(), indices->size() * sizeof(uint16_t));
        clipper.clipEnd(slot);
    }
    clipper.clipEnd();

    return batchCommands(_allocator, _renderCommands);
}
