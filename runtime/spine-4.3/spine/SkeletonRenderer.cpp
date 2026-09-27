/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated April 5, 2025. Replaces all prior versions.
 *
 * Copyright (c) 2013-2025, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software
 * or otherwise create derivative works of the Spine Runtimes (collectively,
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
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THE SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#include <spine/SkeletonRenderer.h>
#include <spine/Skeleton.h>
#include <spine/Slot.h>
#include <spine/SlotData.h>
#include <spine/RegionAttachment.h>
#include <spine/MeshAttachment.h>
#include <spine/ClippingAttachment.h>
#include <spine/Bone.h>
#include <algorithm>

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

static RenderCommand *createRenderCommand(BlockAllocator &allocator, int numVertices, int32_t numIndices, BlendMode blendMode, void *texture) {
	RenderCommand *cmd = allocator.allocate<RenderCommand>(1);
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
	cmd->injectionSlotIndex = -1;
	return cmd;
}

static RenderCommand *batchSubCommands(BlockAllocator &allocator, Array<RenderCommand *> &commands, int first, int last, int numVertices,
									   int numIndices) {
	RenderCommand *batched = createRenderCommand(allocator, numVertices, numIndices, commands[first]->blendMode, commands[first]->texture);
	float *positions = batched->positions;
	float *uvs = batched->uvs;
	uint32_t *colors = batched->colors;
	uint32_t *darkColors = batched->darkColors;
	uint16_t *indices = batched->indices;
	int indicesOffset = 0;
	for (int i = first; i <= last; i++) {
		RenderCommand *cmd = commands[i];
		memcpy(positions, cmd->positions, sizeof(float) * 2 * cmd->numVertices);
		memcpy(uvs, cmd->uvs, sizeof(float) * 2 * cmd->numVertices);
		memcpy(colors, cmd->colors, sizeof(int32_t) * cmd->numVertices);
		memcpy(darkColors, cmd->darkColors, sizeof(int32_t) * cmd->numVertices);
		for (int ii = 0; ii < cmd->numIndices; ii++) indices[ii] = cmd->indices[ii] + indicesOffset;
		indicesOffset += cmd->numVertices;
		positions += 2 * cmd->numVertices;
		uvs += 2 * cmd->numVertices;
		colors += cmd->numVertices;
		darkColors += cmd->numVertices;
		indices += cmd->numIndices;
	}
	batched->injectionSlotIndex = commands[first]->injectionSlotIndex;
	return batched;
}

static RenderCommand *batchCommands(BlockAllocator &allocator, Array<RenderCommand *> &commands) {
	if (commands.size() == 0) return nullptr;

	RenderCommand *root = nullptr;
	RenderCommand *last = nullptr;
	for (int first = 0; first < (int) commands.size();) {
		RenderCommand *command = commands[first];
		if (command->numVertices == 0 && command->numIndices == 0) {
			if (last)
				last->next = command;
			else
				root = command;
			last = command;
			first++;
			continue;
		}

		int end = first;
		int numVertices = command->numVertices;
		int numIndices = command->numIndices;
		while (end + 1 < (int) commands.size()) {
			RenderCommand *next = commands[end + 1];
			if (next->numVertices == 0 || next->texture != command->texture || next->blendMode != command->blendMode ||
				next->injectionSlotIndex != command->injectionSlotIndex || next->colors[0] != command->colors[0] ||
				next->darkColors[0] != command->darkColors[0] || numIndices + next->numIndices >= 0xffff)
				break;
			numVertices += next->numVertices;
			numIndices += next->numIndices;
			end++;
		}

		RenderCommand *batched = batchSubCommands(allocator, commands, first, end, numVertices, numIndices);
		if (last)
			last->next = batched;
		else
			root = batched;
		last = batched;
		first = end + 1;
	}
	return root;
}

static bool contains(const std::vector<int> &values, int value) {
	return std::find(values.begin(), values.end(), value) != values.end();
}

void SkeletonRenderer::buildCommands(
	Skeleton &skeleton,
	const std::vector<int> &injectionSlotIndices,
	const std::vector<int> *splitSlotIndices,
	Array<RenderCommand *> &commandsInSplit,
	Array<RenderCommand *> &commandsNotInSplit) {
	_allocator.compress();
	commandsInSplit.clear();
	commandsNotInSplit.clear();

	SkeletonClipping &clipper = _clipping;

	Array<Slot *> &drawOrder = skeleton.getDrawOrder().getAppliedPose();
	for (unsigned i = 0; i < drawOrder.size(); ++i) {
		Slot &slot = *drawOrder[i];
		Attachment *attachment = slot.getAppliedPose().getAttachment();
		if (!attachment) {
			clipper.clipEnd(slot);
			continue;
		}

		// Early out if the slot color is 0 or the bone is not active
		if ((slot.getAppliedPose().getColor().a == 0 || !slot.getBone().isActive()) && !attachment->getRTTI().isExactly(ClippingAttachment::rtti)) {
			clipper.clipEnd(slot);
			continue;
		}

		Array<float> *worldVertices = &_worldVertices;
		Array<unsigned short> *quadIndices = &_quadIndices;
		Array<float> *vertices = worldVertices;
		int32_t verticesCount;
		Array<float> *uvs;
		Array<unsigned short> *indices;
		int32_t indicesCount;
		Color *attachmentColor;
		void *texture;

		if (attachment->getRTTI().isExactly(RegionAttachment::rtti)) {
			RegionAttachment *regionAttachment = (RegionAttachment *) attachment;
			attachmentColor = &regionAttachment->getColor();

			if (attachmentColor->a == 0) {
				int slotIndex = slot.getData().getIndex();
				if (contains(injectionSlotIndices, slotIndex)) {
					RenderCommand *command = createRenderCommand(_allocator, 0, 0, slot.getData().getBlendMode(), nullptr);
					command->injectionSlotIndex = slotIndex;
					if (splitSlotIndices && contains(*splitSlotIndices, slotIndex))
						commandsInSplit.add(command);
					else
						commandsNotInSplit.add(command);
				}
				clipper.clipEnd(slot);
				continue;
			}

			Sequence &sequence = regionAttachment->getSequence();
			int sequenceIndex = sequence.resolveIndex(slot.getAppliedPose());
			TextureRegion *region = sequence.getRegion(sequenceIndex);
			worldVertices->setSize(8, 0);
			regionAttachment->computeWorldVertices(slot, regionAttachment->getOffsets(slot.getAppliedPose()), *worldVertices, 0, 2);
			verticesCount = 4;
			uvs = &sequence.getUVs(sequenceIndex);
			indices = quadIndices;
			indicesCount = 6;
			texture = region->_rendererObject;

		} else if (attachment->getRTTI().isExactly(MeshAttachment::rtti)) {
			MeshAttachment *mesh = (MeshAttachment *) attachment;
			attachmentColor = &mesh->getColor();

			if (attachmentColor->a == 0) {
				clipper.clipEnd(slot);
				continue;
			}

			Sequence &sequence = mesh->getSequence();
			int sequenceIndex = sequence.resolveIndex(slot.getAppliedPose());
			TextureRegion *region = sequence.getRegion(sequenceIndex);
			worldVertices->setSize(mesh->getWorldVerticesLength(), 0);
			mesh->computeWorldVertices(skeleton, slot, 0, mesh->getWorldVerticesLength(), worldVertices->buffer(), 0, 2);
			verticesCount = (int32_t) (mesh->getWorldVerticesLength() >> 1);
			uvs = &sequence.getUVs(sequenceIndex);
			indices = &mesh->getTriangles();
			indicesCount = (int32_t) indices->size();
			texture = region->_rendererObject;

		} else if (attachment->getRTTI().isExactly(ClippingAttachment::rtti)) {
			ClippingAttachment *clip = (ClippingAttachment *) slot.getAppliedPose().getAttachment();
			clipper.clipStart(skeleton, slot, clip);
			continue;
		} else
			continue;

		Color &solarColor = slot.getSolarColor();
		uint8_t r = static_cast<uint8_t>(
			skeleton.getColor().r * slot.getAppliedPose().getColor().r * solarColor.r * attachmentColor->r * 255);
		uint8_t g = static_cast<uint8_t>(
			skeleton.getColor().g * slot.getAppliedPose().getColor().g * solarColor.g * attachmentColor->g * 255);
		uint8_t b = static_cast<uint8_t>(
			skeleton.getColor().b * slot.getAppliedPose().getColor().b * solarColor.b * attachmentColor->b * 255);
		uint8_t a = static_cast<uint8_t>(
			skeleton.getColor().a * slot.getAppliedPose().getColor().a * solarColor.a * attachmentColor->a * 255);
		uint32_t color = (a << 24) | (r << 16) | (g << 8) | b;
		uint32_t darkColor = 0xff000000;
		if (slot.getAppliedPose().hasDarkColor()) {
			Color &slotDarkColor = slot.getAppliedPose().getDarkColor();
			darkColor = 0xff000000 | (static_cast<uint8_t>(slotDarkColor.r * 255) << 16) | (static_cast<uint8_t>(slotDarkColor.g * 255) << 8) |
				static_cast<uint8_t>(slotDarkColor.b * 255);
		}

		if (clipper.isClipping()) {
			clipper.clipTriangles(*worldVertices, *indices, *uvs, 2);
			vertices = &clipper.getClippedVertices();
			verticesCount = (int32_t) (clipper.getClippedVertices().size() >> 1);
			uvs = &clipper.getClippedUVs();
			indices = &clipper.getClippedTriangles();
			indicesCount = (int32_t) (clipper.getClippedTriangles().size());
		}

		RenderCommand *cmd = createRenderCommand(_allocator, verticesCount, indicesCount, slot.getData().getBlendMode(), texture);
		int slotIndex = slot.getData().getIndex();
		if (contains(injectionSlotIndices, slotIndex)) cmd->injectionSlotIndex = slotIndex;
		if (splitSlotIndices && contains(*splitSlotIndices, slotIndex))
			commandsInSplit.add(cmd);
		else
			commandsNotInSplit.add(cmd);
		memcpy(cmd->positions, vertices->buffer(), (verticesCount << 1) * sizeof(float));
		memcpy(cmd->uvs, uvs->buffer(), (verticesCount << 1) * sizeof(float));
		for (int ii = 0; ii < verticesCount; ii++) {
			cmd->colors[ii] = color;
			cmd->darkColors[ii] = darkColor;
		}
		memcpy(cmd->indices, indices->buffer(), indices->size() * sizeof(uint16_t));
		clipper.clipEnd(slot);
	}
	clipper.clipEnd();
}

RenderCommand *SkeletonRenderer::render(Skeleton &skeleton) {
	static const std::vector<int> noSlots;
	return render(skeleton, noSlots);
}

RenderCommand *SkeletonRenderer::render(Skeleton &skeleton, const std::vector<int> &injectionSlotIndices) {
	Array<RenderCommand *> unused;
	buildCommands(skeleton, injectionSlotIndices, nullptr, unused, _renderCommands);
	return batchCommands(_allocator, _renderCommands);
}

std::pair<RenderCommand *, RenderCommand *> SkeletonRenderer::render(
	Skeleton &skeleton,
	const std::vector<int> &injectionSlotIndices,
	const std::vector<int> &splitSlotIndices,
	Array<RenderCommand *> &commandsInSplit,
	Array<RenderCommand *> &commandsNotInSplit) {
	buildCommands(skeleton, injectionSlotIndices, &splitSlotIndices, commandsInSplit, commandsNotInSplit);
	return std::make_pair(batchCommands(_allocator, commandsNotInSplit), batchCommands(_allocator, commandsInSplit));
}
