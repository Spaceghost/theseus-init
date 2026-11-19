package pid1fixtures

import (
	"strings"

	"spaceghost.dev/theseus/schema"
)

_services: [
	schema.#GraphService & {
		service: {
			name: "tree"
			exec: ["/opt/theseus/bin/control-test", "tree", "/run/theseus-init"]
			restart: "never"
		}
	},
	schema.#GraphService & {
		service: {
			name: "boot-check"
			exec: ["/opt/theseus/bin/pid1-test"]
			restart: "never"
			requires: ["tree"]
		}
	},
]
_target: schema.#Target & {
	name: "default"
	members: ["boot-check"]
}

compiled: strings.Join([for service in _services {service.compiled}], "\n") + "\n" + _target.compiled
