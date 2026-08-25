#!/bin/bash

# Run audit checks using make commands
echo "Running audit checks..."

echo "Running install..."
make run.install
install_exit_code=$?

if [ $install_exit_code -ne 0 ]; then
  echo "Install failed!"
  exit 1
fi

# Run application audit (Brakeman)
echo "Running application security audit..."

make run.audit.app
audit_app_exit_code=$?

if [ $audit_app_exit_code -ne 0 ]; then
  echo "Application audit failed!"
  exit 1
fi

# Run dependencies audit (bundler-audit)
echo "Running dependencies audit..."
make run.audit.dependencies
audit_deps_exit_code=$?

if [ $audit_deps_exit_code -ne 0 ]; then
  echo "Dependencies audit failed!"
  exit 1
fi

echo "All audit checks passed!"
exit 0