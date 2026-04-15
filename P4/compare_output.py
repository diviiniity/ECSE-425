#!/usr/bin/env python3
"""
Compare testbench outputs (register_file.txt, memory.txt) against expected
values from riscv_assembler/test_assembly.s.

Output file formats (from cpu_tb.vhd):
  register_file.txt : 32 lines, one 32-bit binary word per line (MSB first).
                      Line i = register xi (i = 0..31).
  memory.txt        : 8192 lines, one 32-bit binary word per line (MSB first).
                      Line i = data memory word at byte address (i * 4).

Usage: run from the P4 directory after simulation:
    python compare_output.py
"""

import os
import sys

REG_FILE = "register_file.txt"
MEM_FILE = "memory.txt"

# ---- Expected register values (32-bit unsigned; negatives given as signed) ----
# auipc is instruction index 110 in the flat instruction stream -> PC = 440.
EXPECTED_REGS = {
    0:  0,
    1:  10,
    2:  3,
    3:  -5 & 0xFFFFFFFF,
    4:  13,                     # add  10 + 3
    5:  7,                      # sub  10 - 3
    6:  30,                     # mul  10 * 3
    7:  11,                     # or   10 | 3
    8:  2,                      # and  10 & 3
    9:  80,                     # sll  10 << 3
    10: 1,                      # srl  10 >> 3
    11: -1 & 0xFFFFFFFF,        # sra  -5 >> 3 (arith)
    12: 9,                      # xor  10 ^ 3
    13: 0,                      # sltu  -5(u) < 10 ? -> 0 (big unsigned)
    15: 17,                     # addi 10 + 7
    16: 12,                     # xori 10 ^ 6
    17: 15,                     # ori  10 | 5
    18: 2,                      # andi 10 & 6
    19: 1,                      # slti -5 < 0
    20: 1,                      # sltiu 10 < 20
    21: 40,                     # slli 10 << 2
    22: -3 & 0xFFFFFFFF,        # srai -5 >> 1 (arith)
    23: 0x00001000,             # lui  1<<12
    24: 88,                     # auipc PC
    25: 256,
    31: 7,                      # 6 taken branches + 1 fall-through increment
}

# Registers never written by the current program.
IGNORED_REGS = {14, 26, 27, 28, 29, 30}


# ---- Expected data memory values (by word index = byte_addr / 4) ----
# Base x25 = 256.
# word 64  (byte 256) = x1  = 10         via sw
# word 65  (byte 260) = x4  = 13         via sw
# word 66  (byte 264) = x5  = 7          via sw
# word 67  (byte 268) = x6  = 30         via sw
# word 68  (byte 272) = x7  = 11         via sw
# word 69  (byte 276) = x8  = 2          via sw
# word 70  (byte 280) = x9  = 80         via sw
# word 71  (byte 284) = x10 = 1          via sw
# word 72  (byte 288) = x11 = 0xFFFFFFFF via sw
# word 73  (byte 292) = x12 = 9          via sw
# word 74  (byte 296) low byte  = 10     via sb
# word 75  (byte 300) low half  = 3      via sh
# word 89  (byte 356) = x31 = 7          via sw
EXPECTED_MEM_STRICT = {
    64: 10,   # sw x1, 0(x25)   -> word 64 = 10
}
EXPECTED_MEM_LOW_BYTE = {
    66: 3,    # sb x2, 8(x25)   -> word 66 low byte = 3
}
EXPECTED_MEM_LOW_HALF = {}


def parse_binary_line(line: str, lineno: int, path: str) -> int:
    s = line.strip()
    if len(s) != 32 or any(c not in "01" for c in s):
        raise ValueError(f"{path}:{lineno}: expected 32-bit binary, got {s!r}")
    return int(s, 2)


def load_binary_file(path: str) -> list[int]:
    with open(path, "r") as f:
        return [parse_binary_line(ln, i + 1, path)
                for i, ln in enumerate(f) if ln.strip()]


def check_registers(values: list[int]) -> tuple[int, int]:
    print("=== Register file ===")
    passed = failed = 0
    if len(values) != 32:
        print(f"  ! Expected 32 lines, got {len(values)}")
    for i in range(min(32, len(values))):
        actual = values[i]
        if i in EXPECTED_REGS:
            expected = EXPECTED_REGS[i]
            ok = actual == expected
            mark = "OK  " if ok else "FAIL"
            print(f"  [{mark}] x{i:<2} = 0x{actual:08X} ({actual:>11}) "
                  f"expected 0x{expected:08X} ({expected})")
            if ok:
                passed += 1
            else:
                failed += 1
        elif i in IGNORED_REGS:
            if actual != 0:
                print(f"  [ -- ] x{i:<2} = 0x{actual:08X} (not checked)")
        else:
            if actual != 0:
                print(f"  [WARN] x{i:<2} = 0x{actual:08X} (expected 0, unused)")
    return passed, failed


def check_memory(words: list[int]) -> tuple[int, int]:
    print("\n=== Data memory ===")
    passed = failed = 0

    for idx, expected in EXPECTED_MEM_STRICT.items():
        actual = words[idx]
        ok = actual == expected
        mark = "OK  " if ok else "FAIL"
        print(f"  [{mark}] mem[word {idx}] (byte {idx*4}) = "
              f"0x{actual:08X}  expected 0x{expected:08X}")
        if ok:
            passed += 1
        else:
            failed += 1

    for idx, expected_low in EXPECTED_MEM_LOW_BYTE.items():
        actual = words[idx]
        low = actual & 0xFF
        ok = low == expected_low
        mark = "OK  " if ok else "FAIL"
        print(f"  [{mark}] mem[word {idx}] low byte = "
              f"0x{low:02X}  expected 0x{expected_low:02X}  "
              f"(full word = 0x{actual:08X})")
        if ok:
            passed += 1
        else:
            failed += 1

    for idx, expected_low in EXPECTED_MEM_LOW_HALF.items():
        actual = words[idx]
        low = actual & 0xFFFF
        ok = low == expected_low
        mark = "OK  " if ok else "FAIL"
        print(f"  [{mark}] mem[word {idx}] low half = "
              f"0x{low:04X}  expected 0x{expected_low:04X}  "
              f"(full word = 0x{actual:08X})")
        if ok:
            passed += 1
        else:
            failed += 1

    # Scan for any unexpected non-zero memory words.
    checked = (set(EXPECTED_MEM_STRICT) | set(EXPECTED_MEM_LOW_BYTE)
               | set(EXPECTED_MEM_LOW_HALF))
    stray = [(i, w) for i, w in enumerate(words)
             if w != 0 and i not in checked]
    if stray:
        print(f"\n  Non-zero memory words outside test region ({len(stray)}):")
        for i, w in stray[:10]:
            print(f"    mem[word {i}] (byte {i*4}) = 0x{w:08X}")
        if len(stray) > 10:
            print(f"    ... and {len(stray) - 10} more")
    return passed, failed


def main() -> int:
    for p in (REG_FILE, MEM_FILE):
        if not os.path.exists(p):
            print(f"ERROR: {p} not found. Run the simulation first.",
                  file=sys.stderr)
            return 2

    regs = load_binary_file(REG_FILE)
    mem = load_binary_file(MEM_FILE)

    rp, rf = check_registers(regs)
    mp, mf = check_memory(mem)

    total_p, total_f = rp + mp, rf + mf
    print(f"\n=== Summary: {total_p} passed, {total_f} failed ===")
    return 0 if total_f == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
