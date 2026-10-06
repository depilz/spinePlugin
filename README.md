# Solar2D Spine Plugin

A native Spine plugin for Solar2D, enabling seamless integration of Spine animations into your Solar2D projects with enhanced performance and features.

The plugin ships one plugin per Spine line; pick the one that matches the Spine editor you export from:

| Spine line | Plugin | Version | Documentation |
|---|---|---|---|
| 4.2 | `plugin.spine42` | 2.0.1 | [spineplugin.readthedocs.io/en/4.2](https://spineplugin.readthedocs.io/en/4.2/) |
| 4.3 | `plugin.spine43` | 3.0.1 | [spineplugin.readthedocs.io/en/4.3](https://spineplugin.readthedocs.io/en/4.3/) |
| legacy | `plugin.spine` | 1.2 | [spineplugin.readthedocs.io/en/1.2](https://spineplugin.readthedocs.io/en/1.2/) |

The plugin works on Android, iOS, macOS, and Windows platforms, supporting both Spine JSON and binary formats.

For detailed information on the plugin's API, please refer to the [plugin's documentation](https://spineplugin.readthedocs.io/)

### 📦 Installing plugin.spine42

Add this entry to the plugins table of your project's `build.settings`. The Simulator and the build download the plugin from the [Solar2D Free Plugin Directory](https://plugins.solar2d.com/):

```lua
settings =
{
    plugins =
    {
        ["plugin.spine42"] =
        {
            publisherId = "com.studycat",
        },
    },
}
```

Then load it with `local spine = require("plugin.spine42")`. The [4.2 documentation](https://spineplugin.readthedocs.io/en/4.2/) covers the rest.

### 📦 Installing plugin.spine43

For skeletons exported with Spine 4.3, add this entry instead. The Simulator and the build download the plugin from the Solar2D Free Plugin Directory:

```lua
settings =
{
    plugins =
    {
        ["plugin.spine43"] =
        {
            publisherId = "com.studycat",
        },
    },
}
```

Then load it with `local spine = require("plugin.spine43")`. The [4.3 documentation](https://spineplugin.readthedocs.io/en/4.3/) covers the rest, and its [migration page](https://spineplugin.readthedocs.io/en/4.3/migration.html) lists what changes from 4.2.

To stay on one release, add `version = "v1"` to the entry: `v1` is plugin.spine42 2.0.0 and plugin.spine43 3.0.0. The same archives stay attached to this repository's [spine42-2.0.0](https://github.com/depilz/spinePlugin/releases/tag/spine42-2.0.0) and [spine43-3.0.0](https://github.com/depilz/spinePlugin/releases/tag/spine43-3.0.0) releases as a fallback: list their URLs in the entry's `supportedPlatforms` to install from there instead.


### 🤝 Contributing

I warmly welcome contributions from the community! Whether you’re an expert in native code and plugins or just getting started, your help can make a significant difference.

**How to Contribute:**

 • Report Issues: If you encounter any bugs or have feature requests, please open an issue.
 • Submit Pull Requests: Feel free to fork the repository and submit pull requests with your improvements.
 • Collaborate: If you’re unsure where to start, reach out! I’m here to guide you through the code and the build process.

### 🦴 Using the plugin

This plugin utilizes the Spine Runtime to enable animation functionalities. The Spine Runtime is licensed under the [Spine Runtime License](https://esotericsoftware.com/spine-editor-license), a copy of which is available in our repository. Spine technology by Esoteric Software. Please see [Spine’s website](http://esotericsoftware.com) for more details on licensing and usage.

A Spine license is required to use this Solar2D plugin.

### 📄 License

This project is licensed under the [MIT License](https://mit-license.org).

### 📫 Contact

Feel free to reach out for any questions, collaborations, or to share your Spine animations:

- Discord: [depilz](http://discordapp.com/users/468490249710862336)
- Email: <depilz.dev@gmail.com>

Stay tuned for more updates, and thank you for your support!
