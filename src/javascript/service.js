(function (root, __service, svelte) {
	// =============================================================
	// NAME: service
	// Injected dependency script for compiling Svelte.JS components
	// =============================================================

	// =============================================================
	// >>> MODULE FUNCTIONS
	// =============================================================

	function dispatchTask(id, source) {
		var compiled = "";
		try {
			compiled = svelte.compile(source, {
				format: "eval"
			}).code;

		} catch (err) {
			console.error("ERROR PROCESSING SVELTE COMPONENT:\n\n" + err);
		}

		__service.dispatchCompiled(id, compiled);
	}

	// =============================================================
	// >>> MODULE EXPORTS
	// =============================================================

	root.service = {
		dispatchTask: dispatchTask
	};

	__service.ready();
})(this, __service, svelte);