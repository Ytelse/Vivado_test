def fixed_width_hex(value, bits):
    assert bits % 4 == 0, \
        "Invalid fixed width {}, must be a multiple of 4 bits for hex values".\
        format(bits)
    nibbles = bits // 4
    if value < 0:
        msb = 2**bits
        assert msb + value > 0, \
            "Value {} too small to fix in fixed width {} bits".\
            format(value, bit)
        return hex(msb + value)[2:]
    else:
        unfilled_hexstr = hex(value)[2:]
        assert len(unfilled_hexstr) <= nibbles,\
            "Value {} too large to fit in fixed width {} bits".\
            format(unfilled_hexstr, bits)
        return '0'*(nibbles - len(unfilled_hexstr)) + unfilled_hexstr

def fixed_width_bin(value, bits):
    if value < 0:
        msb = 2**bits
        assert msb + value > 0, \
            "Value {} too small to fix in fixed width {} bits".\
            format(value, bit)
        return bin(msb + value)[2:]
    else:
        unfilled_binstr = bin(value)[2:]
        assert len(unfilled_binstr) <= bits, \
            "Value {} too large to fit in fixed width {} bits".\
            format(unfilled_binstr, bits)
        return '0'*(bits - len(unfilled_binstr)) + unfilled_binstr


def reg_update_regex_str():
    return "^\\s*r(\\d+)\\s*=\\s*(.+)\\s*$"

def dmem_update_regex_str():
    return "^\\s*dmem_word\\s*\\[\\s*(.+)\\s*\\]\\s*=\\s*(.+)\\s*$"

def assert_in_range(value_kind, value, minOK, maxOK):
    assert minOK <= value <= maxOK, \
        "{} {} is outside range [{}, {}]".\
        format(value_kind, value, minOK, maxOK)
