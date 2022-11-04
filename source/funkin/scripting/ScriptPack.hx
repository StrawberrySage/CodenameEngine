package funkin.scripting;

import funkin.scripting.events.CancellableEvent;

@:access(CancellableEvent)
class ScriptPack extends Script {
    public var scripts:Array<Script> = [];
    public var additionalDefaultVariables:Map<String, Dynamic> = [];
    public var publicVariables:Map<String, Dynamic> = [];
    public var parent:Dynamic = null;

    public override function load() {
        for(e in scripts) {
            e.load();
        }
    }

    public function new(name:String) {
        additionalDefaultVariables["importScript"] = importScript;
        super(name);
    }

    public function importScript(path:String):Script {
        var script = Script.create(Paths.script(path));
        if (script is DummyScript) {
            throw 'Script at ${path} does not exist.';
            return null;
        }
        add(script);
        script.load();
        return script;
    }

    public override function call(func:String, ?parameters:Array<Dynamic>):Dynamic {
        for(e in scripts)
            e.call(func, parameters);
        return null;
    }

    /**
     * Sends an event to every single script, and returns the event.
     * @param func Function to call
     * @param event Event (will be the first parameter of the function)
     * @return (modified by scripts)
     */
    public function event<T:CancellableEvent>(func:String, event:T):T {
        for(e in scripts) {
            e.call(func, [event]);
            @:privateAccess
            if (event.cancelled && event.__continueCalls) break;
        }
        return event;
    }

    public override function get(val:String):Dynamic {
        for(e in scripts) {
            var v = e.get(val);
            if (v != null) return v;
        }
        return null;
    }

    public override function reload() {
        for(e in scripts) e.reload();
    }

    public override function set(val:String, value:Dynamic) {
        for(e in scripts) e.set(val, value);
    }

    public override function setParent(parent:Dynamic) {
        this.parent = parent;
        for(e in scripts) e.setParent(parent);
    }

    public override function onDestroy() {
        for(e in scripts) e.destroy();
    }
    
    public override function onCreate(path:String) {}

    public function add(script:Script) {
        scripts.push(script);
        __configureNewScript(script);
    }

    public function remove(script:Script) {
        scripts.remove(script);
    }

    public function insert(pos:Int, script:Script) {
        scripts.insert(pos, script);
        __configureNewScript(script);
    }

    private function __configureNewScript(script:Script) {
        if (parent != null) script.setParent(parent);
        script.setPublicMap(publicVariables);
        for(k=>e in additionalDefaultVariables) script.set(k, e);
    }
}