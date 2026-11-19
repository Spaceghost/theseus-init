package pid1fixtures

import "spaceghost.dev/theseus/schema"

_openrcService: schema.#GraphService & {
	service: {
		name: "openrc-client"
		exec: ["/opt/theseus/bin/pid1-openrc-test"]
		restart: "never"
	}
}

_openrcTarget: schema.#Target & {
	name: "default"
	members: ["openrc-client"]
}

openrcCompiled: _openrcService.compiled + "\n" + _openrcTarget.compiled
