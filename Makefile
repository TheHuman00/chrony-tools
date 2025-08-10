# Chrony Tools Makefile

.PHONY: help install install-user install-system check clean

help:
	@echo "Chrony Tools - Available targets:"
	@echo "  install        - Install for current user"
	@echo "  install-system - Install system-wide (requires sudo)"
	@echo "  check          - Check dependencies"
	@echo "  clean          - Clean temporary files"

install: install-user

install-user:
./install.sh --user

install-system:
sudo ./install.sh --system

check:
./install.sh --check

clean:
find . -name "*.tmp" -o -name "*.log" -o -name "*~" | xargs rm -f
