# Solar2D Spine Plugin

A native Spine plugin for Solar2D, enabling seamless integration of Spine 4.2 animations into your Solar2D projects with enhanced performance and features.

### 🎉 Introduction

I’m excited to announce the Solar2D Spine Plugin!
After a long time of having this within my goals, the plugin is now available in its early stages. This native plugin allows you to incorporate Spine 4.2 animations directly into your Solar2D applications, enhancing your project’s visual appeal and performance.

The plugin is still at an early stage and not meant for production use yet. However, I will keep working on this and in the following weeks, I expect the plugin to gain more stability and have all the basic functionalities working.

See the [Roadmap](#-roadmap) section for more details on upcoming features and improvements.

### 📚 Usage

Using the Solar2D Spine Plugin is straightforward. Here’s a basic example to help you get started:

```lua
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
```

### 📈 Roadmap

Here’s what’s coming next for the Plugin:

1. Properly Update Meshes: Resolve current crashes related to mesh updates.
2. Platform Support: Extend the plugin to support to Windows and Android.
3. Make it available for free in Solar2D plugin Marketplace.
4. Add scripts to facilitate building the plugin to the different platforms.
5. Interface to Animation Mix Times: Provide controls for blending transitions.
6. Event Listeners: Implement event listeners for animation events.
7. A More Robust Update Cycle: Enhance the update mechanism for better performance and reliability. (Worth using threads?)
8. Physics Controls: Integrate new physics features from Spine 4.2.
9. Draw the Meshes Using Solar’s Native API: Utilize Solar2D’s native drawing capabilities for improved performance.
10. Correct Memory Management: Optimize memory usage to prevent leaks and crashes.
11. Interface to All Spine Utilities: Provide access to the full range of Spine utilities for comprehensive animation control.
12. Include a sample project.
13. Provide documentation.
14. Implement display object injections into spine.

### 🤝 Contributing

I warmly welcome contributions from the community! Whether you’re an expert in native code and plugins or just getting started, your help can make a significant difference.

**How to Contribute:**

 • Report Issues: If you encounter any bugs or have feature requests, please open an issue.
 • Submit Pull Requests: Feel free to fork the repository and submit pull requests with your improvements.
 • Collaborate: If you’re unsure where to start, reach out! I’m here to guide you through the code and the build process.

### 🦴 Using Spine Runtimes

This plugin utilizes the Spine Runtime to enable animation functionalities. The Spine Runtime is licensed under the [Spine Runtime License](https://esotericsoftware.com/spine-editor-license), a copy of which is available in our repository. Spine technology by Esoteric Software. Please see [Spine’s website](http://esotericsoftware.com) for more details on licensing and usage."

### 📄 License

This project is licensed under the [MIT License](https://mit-license.org).

### 📫 Contact

Feel free to reach out for any questions, collaborations, or to share your Spine animations:

- Discord: [depilz](http://discordapp.com/users/468490249710862336)
- Email: <clarospilzdw@gmail.com>

Stay tuned for more updates, and thank you for your support!
