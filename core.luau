local Core = require(script.Core); Core:Start();

local Core = {};

Core.Name = "DynamicCoreTask";
Core.Version = "1.0.0";
Core.Started = false;
Core.Destroyed = false;

Core.Registry = {};
Core.Packages = {};
Core.Modules = {};
Core.Functions = {};
Core.Services = {};
Core.Libraries = {};
Core.Security = {};
Core.Environment = {};
Core.Game = {};
Core.Events = {};
Core.Connections = {};
Core.Hooks = {};
Core.Middlewares = {};
Core.Config = {};
Core.State = {};
Core.Cache = {};
Core.Tasks = {};
Core.Metatables = {};
Core.Readonly = {};

local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");

local function Clone(value, seen);
    if type(value) ~= "table" then;
        return value;
    end;

    seen = seen or {};

    if seen[value] then;
        return seen[value];
    end;

    local result = {};
    seen[value] = result;

    for key, child in pairs(value) do;
        result[Clone(key, seen)] = Clone(child, seen);
    end;

    return setmetatable(result, getmetatable(value));
end;

local function Merge(target, source);
    for key, value in pairs(source) do;
        if type(value) == "table" and type(target[key]) == "table" then;
            Merge(target[key], value);
        else;
            target[key] = value;
        end;
    end;

    return target;
end;

local function Disconnect(connection);
    if connection and typeof(connection) == "RBXScriptConnection" then;
        if connection.Connected then;
            connection:Disconnect();
        end;
    end;
end;

local function GenerateId(prefix);
    return tostring(prefix or "ID") .. "_" .. HttpService:GenerateGUID(false);
end;

Core.Environment = {
    Game = game;
    Workspace = workspace;
    Players = Players;
    LocalPlayer = Players.LocalPlayer;
    RunService = RunService;
    HttpService = HttpService;
    UserInputService = game:GetService("UserInputService");
    ReplicatedStorage = game:GetService("ReplicatedStorage");
    TweenService = game:GetService("TweenService");
    Lighting = game:GetService("Lighting");
    StarterGui = game:GetService("StarterGui");
    CoreGui = game:GetService("CoreGui");
    IsStudio = RunService:IsStudio();
    IsClient = RunService:IsClient();
    IsServer = RunService:IsServer();
    Task = task;
    Math = math;
    String = string;
    Table = table;
    TypeOf = typeof;
    Wait = task.wait;
    Spawn = task.spawn;
    Defer = task.defer;
    Delay = task.delay;
    Clock = os.clock;
    Time = os.time;
};

Core.Services.Get = function(name);
    if Core.Services[name] then;
        return Core.Services[name];
    end;

    local success, service = pcall(game.GetService, game, name);

    if success then;
        Core.Services[name] = service;
        return service;
    end;
end;

Core.Services.Register = function(name, service);
    Core.Services[name] = service;
    return service;
end;

Core.Services.Remove = function(name);
    Core.Services[name] = nil;
end;

Core.Services.Has = function(name);
    return Core.Services[name] ~= nil;
end;

Core.Registry.Register = function(name, value, category);
    category = category or "Default";

    Core.Registry[category] = Core.Registry[category] or {};
    Core.Registry[category][name] = value;

    return value;
end;

Core.Registry.Get = function(name, category);
    category = category or "Default";

    if Core.Registry[category] then;
        return Core.Registry[category][name];
    end;
end;

Core.Registry.Has = function(name, category);
    return Core.Registry.Get(name, category) ~= nil;
end;

Core.Registry.Remove = function(name, category);
    category = category or "Default";

    if Core.Registry[category] then;
        Core.Registry[category][name] = nil;
    end;
end;

Core.Functions.Register = function(name, callback, metadata);
    assert(type(name) == "string", "Function name must be a string");
    assert(type(callback) == "function", "Callback must be a function");

    local functionObject = {
        Name = name;
        Callback = callback;
        Metadata = metadata or {};
        Calls = 0;
        Enabled = true;
    };

    function functionObject:Call(...);
        if not self.Enabled then;
            return nil;
        end;

        self.Calls += 1;

        return self.Callback(...);
    end;

    function functionObject:Enable();
        self.Enabled = true;
    end;

    function functionObject:Disable();
        self.Enabled = false;
    end;

    function functionObject:Replace(callback);
        assert(type(callback) == "function", "Callback must be a function");
        self.Callback = callback;
    end;

    function functionObject:Destroy();
        self.Enabled = false;
        self.Callback = nil;
    end;

    Core.Functions[name] = functionObject;

    return functionObject;
end;

Core.Functions.Get = function(name);
    return Core.Functions[name];
end;

Core.Functions.Call = function(name, ...);
    local functionObject = Core.Functions[name];

    if not functionObject then;
        return nil;
    end;

    return functionObject:Call(...);
end;

Core.Functions.Remove = function(name);
    local functionObject = Core.Functions[name];

    if functionObject then;
        functionObject:Destroy();
    end;

    Core.Functions[name] = nil;
end;

Core.Functions.Wrap = function(callback, before, after);
    return function(...);
        local arguments = table.pack(...);

        if before then;
            before(table.unpack(arguments, 1, arguments.n));
        end;

        local results = table.pack(callback(table.unpack(arguments, 1, arguments.n)));

        if after then;
            after(table.unpack(results, 1, results.n));
        end;

        return table.unpack(results, 1, results.n);
    end;
end;

Core.Metatables.Create = function(index, newIndex, call);
    local metatable = {};

    if index then;
        metatable.__index = index;
    end;

    if newIndex then;
        metatable.__newindex = newIndex;
    end;

    if call then;
        metatable.__call = call;
    end;

    return metatable;
end;

Core.Metatables.Apply = function(object, metatable);
    return setmetatable(object, metatable);
end;

Core.Metatables.Get = function(object);
    return getmetatable(object);
end;

Core.Metatables.Remove = function(object);
    return setmetatable(object, nil);
end;

Core.Readonly.Create = function(source);
    local proxy = {};

    setmetatable(proxy, {
        __index = source;
        __newindex = function();
            error("Attempt to modify readonly table", 2);
        end;
        __metatable = "Locked";
    });

    return proxy;
end;

Core.Readonly.Lock = function(source);
    return Core.Readonly.Create(source);
end;

Core.Readonly.Is = function(source);
    return getmetatable(source) == "Locked";
end;

Core.Hooks.Register = function(name, callback);
    Core.Hooks[name] = Core.Hooks[name] or {};
    table.insert(Core.Hooks[name], callback);

    return callback;
end;

Core.Hooks.Fire = function(name, ...);
    if not Core.Hooks[name] then;
        return;
    end;

    for _, callback in ipairs(Core.Hooks[name]) do;
        task.spawn(callback, ...);
    end;
end;

Core.Hooks.Clear = function(name);
    if name then;
        Core.Hooks[name] = nil;
    else;
        table.clear(Core.Hooks);
    end;
end;

Core.Events.Create = function(name);
    local event = {
        Name = name;
        Listeners = {};
        Destroyed = false;
    };

    function event:Connect(callback);
        if self.Destroyed then;
            return;
        end;

        local connection = {
            Connected = true;
        };

        function connection:Disconnect();
            self.Connected = false;
        end;

        table.insert(self.Listeners, {
            Callback = callback;
            Connection = connection;
        });

        return connection;
    end;

    function event:Once(callback);
        local connection;

        connection = self:Connect(function(...);
            connection:Disconnect();
            callback(...);
        end);

        return connection;
    end;

    function event:Fire(...);
        if self.Destroyed then;
            return;
        end;

        for _, listener in ipairs(self.Listeners) do;
            if listener.Connection.Connected then;
                task.spawn(listener.Callback, ...);
            end;
        end;
    end;

    function event:Destroy();
        self.Destroyed = true;
        table.clear(self.Listeners);
    end;

    Core.Events[name] = event;

    return event;
end;

Core.Connection.Add = function(signal, callback);
    local connection = signal:Connect(callback);

    table.insert(Core.Connections, connection);

    return connection;
end;

Core.Connection.Once = function(signal, callback);
    local connection;

    connection = signal:Connect(function(...);
        Disconnect(connection);
        callback(...);
    end);

    table.insert(Core.Connections, connection);

    return connection;
end;

Core.Connection.Clear = function();
    for index = #Core.Connections, 1, -1 do;
        Disconnect(Core.Connections[index]);
        Core.Connections[index] = nil;
    end;
end;

Core.Package.Register = function(name, package, metadata);
    Core.Packages[name] = {
        Module = package;
        Metadata = metadata or {};
        Loaded = false;
        Value = nil;
    };

    return Core.Packages[name];
end;

Core.Package.Require = function(name);
    local package = Core.Packages[name];

    assert(package, "Package not found: " .. tostring(name));

    if package.Loaded then;
        return package.Value;
    end;

    if type(package.Module) == "function" then;
        package.Value = package.Module(Core);
    else;
        package.Value = package.Module;
    end;

    package.Loaded = true;

    return package.Value;
end;

Core.Module.Register = function(name, module);
    Core.Modules[name] = module;
    return module;
end;

Core.Module.Get = function(name);
    return Core.Modules[name];
end;

Core.Config.Set = function(key, value);
    Core.Config[key] = value;
    return value;
end;

Core.Config.Get = function(key, default);
    if Core.Config[key] == nil then;
        return default;
    end;

    return Core.Config[key];
end;

Core.State.Set = function(key, value);
    Core.State[key] = value;
    return value;
end;

Core.State.Get = function(key, default);
    if Core.State[key] == nil then;
        return default;
    end;

    return Core.State[key];
end;

Core.Game.GetPlayer = function(name);
    return Players:FindFirstChild(name);
end;

Core.Game.GetCharacter = function(player);
    player = player or Players.LocalPlayer;
    return player and player.Character;
end;

Core.Game.GetHumanoid = function(player);
    local character = Core.Game.GetCharacter(player);
    return character and character:FindFirstChildOfClass("Humanoid");
end;

Core.Game.GetRoot = function(player);
    local character = Core.Game.GetCharacter(player);
    return character and character:FindFirstChild("HumanoidRootPart");
end;

Core.Register = function(name, value, category);
    return Core.Registry.Register(name, value, category);
end;

Core.Get = function(name, category);
    return Core.Registry.Get(name, category);
end;

Core.Require = function(name);
    return Core.Package.Require(name);
end;

Core.Use = function(name);
    return Core.Package.Require(name);
end;

Core.Connect = function(signal, callback);
    return Core.Connection.Add(signal, callback);
end;

Core.Once = function(signal, callback);
    return Core.Connection.Once(signal, callback);
end;

Core.On = function(name);
    return Core.Events[name] or Core.Events.Create(name);
end;

Core.Start = function(self);
    if self.Started then;
        return self;
    end;

    self.Started = true;

    self.Hooks.Fire("BeforeStart", self);
    self.Hooks.Fire("AfterStart", self);

    return self;
end;

Core.Stop = function(self);
    if not self.Started then;
        return;
    end;

    self.Hooks.Fire("BeforeStop", self);
    self.Connection.Clear();
    self.Hooks.Fire("AfterStop", self);

    self.Started = false;
end;

Core.Destroy = function(self);
    if self.Destroyed then;
        return;
    end;

    self:Stop();

    for _, event in pairs(self.Events) do;
        if type(event) == "table" and event.Destroy then;
            event:Destroy();
        end;
    end;

    table.clear(self.Cache);
    table.clear(self.Packages);
    table.clear(self.Modules);
    table.clear(self.Functions);
    table.clear(self.Hooks);

    self.Destroyed = true;
end;

Core.Register("Environment", Core.Environment, "Core");
Core.Register("Services", Core.Services, "Core");
Core.Register("Functions", Core.Functions, "Core");
Core.Register("Libraries", Core.Libraries, "Core");
Core.Register("Security", Core.Security, "Core");
Core.Register("Game", Core.Game, "Core");
Core.Register("Events", Core.Events, "Core");
Core.Register("Connections", Core.Connections, "Core");
Core.Register("Hooks", Core.Hooks, "Core");
Core.Register("Packages", Core.Packages, "Core");
Core.Register("Modules", Core.Modules, "Core");
Core.Register("Config", Core.Config, "Core");
Core.Register("State", Core.State, "Core");
Core.Register("Metatables", Core.Metatables, "Core");
Core.Register("Readonly", Core.Readonly, "Core");

return Core;
