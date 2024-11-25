#import <Foundation/Foundation.h>
#import "CoronaLua.h"
#import "CoronaMacros.h"
#import "Lua_Spine.h"

@interface PluginSpine : NSObject

- (int)open:(lua_State*)L;

@end

@implementation PluginSpine

static PluginSpine *plugin;

- (int)open:(lua_State*)L {
    return luaopen_spine(L);
}

// Export the plugin
CORONA_EXPORT int luaopen_plugin_spine(lua_State *L) {
    PluginSpine *pluginInstance = [[PluginSpine alloc] init];
    plugin = pluginInstance;
    return [pluginInstance open:L];
}

@end
