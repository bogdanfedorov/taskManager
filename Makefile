# --- tasks: one per line in $(TASKS):  - [ ] B1 [status] text ---
#   make tasks [S=status] [Q=text]   list, filter by status / search
#   make task-find Q=text            search (case-insensitive, ID + text)
#   make task-add ID=B1 T="text"     add (status todo)
#   make task-st ID=B1 S=docs        set status
#   make task-next ID=B1             advance to next status
#   make task-rm ID=B1               remove

TASKS    ?= TASKS.md
STATUSES := todo docs model tests code done

tasks:
	@if [ -s $(TASKS) ]; then \
	  awk -v s="$(S)" -v q="$(Q)" 'BEGIN{q=tolower(q)} \
	    { line=$$0; sub(/^- \[.\] /, "", line); \
	      split(line, a, " "); \
	      id=a[1]; st=substr(a[2],2,length(a[2])-2); \
	      txt=substr(line, index(line,a[2])+length(a[2])+1); \
	      if (s!="" && st!=s) next; \
	      if (q!="" && index(tolower(id" "txt),q)==0) next; \
	      printf "%-6s %-6s %s\n", id, st, txt; n++ } \
	    END{ if(!n) print "no matches" }' $(TASKS); \
	else echo "no tasks"; fi

task-find:
	@if [ -z "$(Q)" ]; then echo 'usage: make task-find Q=text'; exit 1; fi
	@$(MAKE) --no-print-directory tasks Q="$(Q)"

task-add:
	@if [ -z "$$ID" ] || [ -z "$$T" ]; then echo 'usage: make task-add ID=B1 T="text"'; exit 1; fi; \
	ID=$$(echo "$$ID" | tr a-z A-Z); \
	echo "$$ID" | grep -Eq '^[A-Z]+[0-9]+$$' || { echo "bad ID '$$ID' (expected like B1, C5)"; exit 1; }; \
	if grep -q "^- \[.\] $$ID \[" $(TASKS) 2>/dev/null; then echo "$$ID already exists"; exit 1; fi; \
	printf -- '- [ ] %s [todo] %s\n' "$$ID" "$$T" >> $(TASKS); \
	echo "added $$ID: $$T"

task-st:
	@if [ -z "$$ID" ] || [ -z "$$S" ]; then echo 'usage: make task-st ID=B1 S=docs'; exit 1; fi; \
	case " $(STATUSES) " in *" $$S "*) ;; *) echo "status must be one of: $(STATUSES)"; exit 1;; esac; \
	ID=$$(echo "$$ID" | tr a-z A-Z); \
	grep -q "^- \[.\] $$ID \[" $(TASKS) 2>/dev/null || { echo "no task $$ID"; exit 1; }; \
	mark=" "; [ "$$S" = done ] && mark=x; \
	sed "s/^- \[.\] $$ID \[[a-z]*\]/- [$$mark] $$ID [$$S]/" $(TASKS) > $(TASKS).tmp && mv $(TASKS).tmp $(TASKS); \
	echo "$$ID -> $$S"

task-next:
	@if [ -z "$$ID" ]; then echo 'usage: make task-next ID=B1'; exit 1; fi; \
	ID=$$(echo "$$ID" | tr a-z A-Z); \
	cur=$$(grep "^- \[.\] $$ID \[" $(TASKS) 2>/dev/null | sed 's/^- \[.\] [A-Za-z0-9]* \[\([a-z]*\)\].*/\1/'); \
	[ -n "$$cur" ] || { echo "no task $$ID"; exit 1; }; \
	nxt=$$(echo "$(STATUSES)" | tr ' ' '\n' | awk -v c="$$cur" 'f{print;exit} $$0==c{f=1}'); \
	[ -n "$$nxt" ] || { echo "$$ID is already done"; exit 1; }; \
	$(MAKE) --no-print-directory task-st ID=$$ID S=$$nxt

task-rm:
	@if [ -z "$$ID" ]; then echo 'usage: make task-rm ID=B1'; exit 1; fi; \
	ID=$$(echo "$$ID" | tr a-z A-Z); \
	grep -q "^- \[.\] $$ID \[" $(TASKS) 2>/dev/null || { echo "no task $$ID"; exit 1; }; \
	echo "removed: $$(grep "^- \[.\] $$ID \[" $(TASKS) | cut -c7-)"; \
	grep -v "^- \[.\] $$ID \[" $(TASKS) > $(TASKS).tmp; mv $(TASKS).tmp $(TASKS)
