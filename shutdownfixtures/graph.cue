package shutdownfixtures

import (
	"strings"
	"spaceghost.dev/theseus/schema"
)

testDir:     *"/run/theseus-shutdown-tests" | string @tag(testDir)
testProgram: *"/usr/bin/theseus-test" | string       @tag(testProgram)
delay: schema.#CompiledService & {
	service: {
		name: "delayed"
		exec: [testProgram, "delay-term", "\(testDir)/delayed"]
		restart:     "never"
		stopGraceMs: 4000
	}
}
_delayed: schema.#GraphService & {service: delay.service}
_stubborn: schema.#GraphService & {
	service: {
		name: "stubborn"
		exec: [testProgram, "ignore-term", "\(testDir)/stubborn.ready"]
		requires: ["delayed"]
		restart:     "never"
		stopGraceMs: 1200
	}
}
_budgetServices: [
	for serviceName in ["long1", "long2", "long3"] {
		schema.#GraphService & {service: {
			name: serviceName
			exec: ["/bin/true"]
			stopGraceMs: 60000
		}}
	},
]
_target: schema.#Target & {name: "default", members: ["stubborn"]}
_exceedsBudget: schema.#Target & {name: "over-budget", members: ["long1", "long2", "long3"]}
compiled: strings.Join([_delayed.compiled, _stubborn.compiled, for s in _budgetServices {s.compiled},
	_target.compiled, _exceedsBudget.compiled], "\n") + "\n"
