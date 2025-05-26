#!/usr/bin/env bash

source ./print

# AAA: Arrange
export MAX_WIDTH=10

# AAA: Act
h2_output=$(h2 "Titulo H2" | tr -d '\033[[]0-9;]*[a-zA-Z]')
h3_output=$(h3 "Titulo H3" | tr -d '\033[[]0-9;]*[a-zA-Z]')

# AAA: Assert
expected_h2_line="──────────"
expected_h3_line="··········"

if ! echo "$h2_output" | grep -q "$expected_h2_line"; then
  echo "[FAIL] h2 não imprime linha lisa corretamente ($expected_h2_line)"
  exit 1
fi

if ! echo "$h3_output" | grep -q "$expected_h3_line"; then
  echo "[FAIL] h3 não imprime linha pontilhada corretamente ($expected_h3_line)"
  exit 1
fi

echo "[PASS] h2 e h3 imprimem linhas corretamente"
