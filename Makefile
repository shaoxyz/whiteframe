.PHONY: fmt
fmt:
	dart format .

.PHONY: on
on:
	./start_simulator.sh

.PHONY: clean
clean:
	dart run build_runner clean

.PHONY: prebuild
prebuild:
	dart run build_runner build --delete-conflicting-outputs

.PHONY: dev
dev:
	flutter run --hot 