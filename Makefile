SEMINAR := Seminar

.PHONY: seminar

seminar:
	@mkdir -p $(SEMINAR)/$(shell date -u +%Y-%m-%d)
	@cp -r $(SEMINAR)/template/* $(SEMINAR)/$(shell date -u +%Y-%m-%d)


submit:
	@git add .
	@git commit -m "feat: add $(shell date -u +%Y-%m-%d) seminar"
	@git push
