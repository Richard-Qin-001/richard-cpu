import typing

# Regfile
REG_MAP = {f"x{i}": i for i in range(32)}
ABI_NAMES = {
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4, "t0": 5, "t1": 6, "t2": 7,
    "s0": 8, "fp": 8, "s1": 9, "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14,
    "a5": 15, "a6": 16, "a7": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21,
    "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27, "t3": 28,
    "t4": 29, "t5": 30, "t6": 31
}
REG_MAP.update(ABI_NAMES)

INST_LOOKUP = {
    # R-type: opcode, funct3, funct7
    "add":  {"type": "R", "op": 0x33, "f3": 0x0, "f7": 0x00},
    "sub":  {"type": "R", "op": 0x33, "f3": 0x0, "f7": 0x20},
    "and":  {"type": "R", "op": 0x33, "f3": 0x7, "f7": 0x00},
    "or":   {"type": "R", "op": 0x33, "f3": 0x6, "f7": 0x00},
    
    # I-type: opcode, funct3
    "addi": {"type": "I", "op": 0x13, "f3": 0x0},
    "lw":   {"type": "I", "op": 0x03, "f3": 0x2},
    "jalr": {"type": "I", "op": 0x67, "f3": 0x0},
    
    # S-type: opcode, funct3
    "sw":   {"type": "S", "op": 0x23, "f3": 0x2},
    
    # B-type: opcode, funct3
    "beq":  {"type": "B", "op": 0x63, "f3": 0x0},
    "bne":  {"type": "B", "op": 0x63, "f3": 0x1},
}

def preprocess_line(line : str) -> list[str]:
    line = line.split('#')[0]
    line = line.replace(',', ' ')
    line = line.replace('(', ' ').replace(')', ' ')
    tokens = line.split()
    return tokens

