# Solar2D Spine Plugin

A native Spine plugin for Solar2D, enabling seamless integration of Spine 4.2 animations into your Solar2D projects with enhanced performance and features.

🎉 Introduction

Hello everyone!

I’m thrilled to announce the Solar2D Spine Plugin! After a long journey towards this goal, the plugin is now available in its early stages. This native plugin allows you to incorporate Spine 4.2 animations directly into your Solar2D applications, enhancing your project’s visual appeal and performance.

🚀 Features

Current Status

- Platform Support:
    - iOS: Functional.
    - Mac: Functional.
- Basic Functionality:
	- Load and display Spine animations.
	- Set and control animations programmatically.

Upcoming Features

- Animation Mixing: Blend animations smoothly
- Physics Controls: Incorporate the new physics features available in Spine 4.2.
- Event Listeners: Trigger events and call listeners
- Platform Expansion: Windows and Android
- Optimizations:
	- Memory management improvements.
	- Performance enhancements.

📚 Usage

Using the Solar2D Spine Plugin is straightforward. Here’s a basic example to help you get started:

local spine = require("plugin.spine")

local jsonPath = system.pathForFile("art/raptor.json", system.ResourceDirectory)
local atlasPath = system.pathForFile("art/raptor.atlas", system.ResourceDirectory)

local spineObject = spine.create({
    skeletonFile = jsonPath,
    atlasFile = atlasPath,
    scale = 0.2
})

spineObject:setAnimation(0, "walk", true)

parent:insert(spineObject)

Parameters:

	•	skeletonFile: Path to your Spine skeleton JSON file.
	•	atlasFile: Path to your Spine atlas file.
	•	scale: (Optional) Scale factor for the Spine object.

Methods:

	•	setAnimation(trackIndex, animationName, loop): Sets the animation on the specified track.

📈 Roadmap

Here’s what’s coming next for the Solar2D Spine Plugin:

	1.	Properly Update Meshes: Resolve current crashes related to mesh updates.
	2.	Platform Support:
	•	Complete support for Android.
	•	Complete support for Windows.
  3.  Make it available for free in Solar2D plugin Marketplace
	4.	Interface to Animation Mix Times: Provide controls for managing animation transitions.
	5.	Event Listeners: Implement event handling for interactive animations.
	6.	A More Robust Update Cycle: Enhance the update mechanism for better performance and reliability.
	7.	Physics Controls: Integrate new physics features from Spine 4.2.
	8.	Draw the Meshes Using Solar’s Native API: Utilize Solar2D’s native drawing capabilities for improved performance.
	9.	Correct Memory Management: Optimize memory usage to prevent leaks and crashes.
	10.	Interface to All Spine Utilities: Provide access to the full range of Spine utilities for comprehensive animation control.
  11. Add sample project.
  12. Add documentation.
  13. Implement spine injections




🤝 Contributing

I warmly welcome contributions from the community! Whether you’re an expert in native code and plugins or just getting started, your help can make a significant difference.

How to Contribute:

	•	Report Issues: If you encounter any bugs or have feature requests, please open an issue.
	•	Submit Pull Requests: Feel free to fork the repository and submit pull requests with your improvements.
	•	Collaborate: If you’re unsure where to start, reach out! I’m here to guide you through the code and the build process.

🧪 Help Wanted

To enhance the plugin’s capabilities and ensure its stability, I need your help with testing. If you have any Spine 4.2 animations that you can share, please do! This will allow me to run more tests and improve the plugin’s functionality.

📄 License

This project is licensed under the MIT License.

📫 Contact

Feel free to reach out for any questions, collaborations, or to share your Spine animations:

	•	Discord: depilz
	•	Email: clarospilzdw@gmail.com

Stay tuned for more updates, and thank you for your support!

Note: Replace placeholders like https://github.com/yourusername/solar2d-spine-plugin.git with your actual repository link if applicable.
