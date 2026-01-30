#  LittleSDK Bootstrapping
SDK_PATH=deps/sdk
include $(if $(SDK_PATH),$(shell test ! -e "$(SDK_PATH)/setup.mk" && git clone git@github.com:littletoolkit/littlesdk.git "$(SDK_PATH)";echo "$(SDK_PATH)/setup.mk"))

# Override test rule to run with NOCOLOR=1
.PHONY: test
test: $(PREP_ALL) $(TEST_ALL)
	@$(call rule_pre_cmd)
	failed_tests=0; \
	for test in $(TESTS_SH); do \
		echo "$(call fmt_action,[TEST] Running $$test)"; \
		if ! NOCOLOR=1 bash "$$test"; then \
			echo "$(call fmt_error,[TEST] FAILED: $$test)"; \
			failed_tests=$$((failed_tests + 1)); \
		fi; \
	done; \
	if [ $$failed_tests -gt 0 ]; then \
		echo "$(call fmt_error,[TEST] $$failed_tests test(s) failed)"; \
		exit 1; \
	fi; \
	echo "$(call fmt_result,[TEST] All tests passed)"; \
	$(call rule_post_cmd)

# EOF -- vim: ft=make


