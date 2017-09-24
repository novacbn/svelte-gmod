(function (root, __runtime, document) {
	// =============================================================
	// NAME: runtime
	// Injected dependency script for integrating Svelte.JS components
	// =============================================================

	// =============================================================
	// >>> UTILITY VARIABLES
	// =============================================================

	var handles	= {};	// Function handler cache
	var main	= null;	// Main component cache

	// =============================================================
	// >>> MODULE FUNCTIONS
	// =============================================================

	function dispatch(name, data) {
		if (main) {
			main.fire(name, JSON.parse(data));
		}

		__runtime.callback(id);
		__runtime.release(id);
	}

	function get(id, name) {
		var value = null;
		if (main) {
			value = main.get(name);
		}

		__runtime.callback(id, value);
		__runtime.release(id);
	}

	function observe(id, name) {
		if (main) {
			var listener = main.observe(name, function (value) {
				__runtime.callback(id, value);
			});

			handles[id] = function () {
				listener.cancel();
				__runtime.release(id);
			};
		}
	}

	function on(id, name) {
		if (main) {
			var listener = main.observe(name, function (value) {
				value = JSON.stringify(value);
				__runtime.callback(id, value);
			});

			handles[id] = function () {
				listener.cancel();
				__runtime.release(id);
			};
		}
	}

	function release(id) {
		if (main) {
			var handle = handles[id];
			if (handle) {
				handle();
			}
		}
	}

	function set(id, data) {
		if (main) {
			main.set(JSON.parse(data));
		}

		__runtime.callback(id);
		__runtime.release(id);
	}

	function setMainComponent(script) {
		var component = eval(script);
		main = new component({
			target: document.body
		});

		__runtime.create();
	}

	function setSubComponents(scripts) {
		var data = JSON.parse(scripts);
		for (var name in data) {
			root[name] = eval(data[name]);
		}
	}

	// =============================================================
	// >>> MODULE EXPORTS
	// =============================================================

	root.runtime = {
		// Functions
		dispatch:			dispatch,
		get:				get,
		observe:			observe,
		on:					on,
		release:			release,
		set:				set,
		setMainComponent:	setMainComponent,
		setSubComponents:	setSubComponents
	};

	__runtime.ready();
})(this, __runtime, document);