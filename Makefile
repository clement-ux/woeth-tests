-include .env

.EXPORT_ALL_VARIABLES:
MAKEFLAGS += --no-print-directory

default:
	forge fmt && forge build

# Always keep Forge up to date
install:
	foundryup
	forge soldeer install

clean:
	@rm -rf broadcast cache out

clean-all:
	@rm -rf broadcast cache out dependencies node_modules soldeer.lock

# Tests
test-std:
	@forge test --summary --fail-fast

test:
	@make test-std

t:
	@make test

test-f-%:
	@FOUNDRY_MATCH_TEST=$* make test-std

test-c-%:
	@FOUNDRY_MATCH_CONTRACT=$* make test-std

test-all:
	@make test-std


# Override default `test` target
.PHONY: test 
