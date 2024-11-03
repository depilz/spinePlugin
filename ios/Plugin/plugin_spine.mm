#import <Foundation/Foundation.h>
#import "CoronaLua.h"
#import "CoronaMacros.h"
#import "spine_skeleton.h"

@interface PluginSpine : NSObject

- (int)open:(lua_State*)L;

@end

@implementation PluginSpine

static PluginSpine *plugin;

// Implement the open function
- (int)open:(lua_State*)L {
    const luaL_Reg lua_functions[] = {
        {"create", create}, // 'create' function from 'spine_skeleton.cpp'
        {NULL, NULL}
    };

    const char *plugin_name = lua_tostring(L, 1);
    luaL_register(L, plugin_name, lua_functions);

    NSLog(@"Spine plugin initialized");

    plugin = self;

    return 1;
}

// Export the plugin
CORONA_EXPORT int luaopen_plugin_spine(lua_State *L) {
    PluginSpine *pluginInstance = [[PluginSpine alloc] init];
    plugin = pluginInstance;
    return [pluginInstance open:L];
}

@end