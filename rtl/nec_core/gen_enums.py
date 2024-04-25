import yaml
import sys
import math
import os


def process_enum(name, desc):
    calc_bits = math.ceil(math.log2(len(desc['values'])))
    bits = desc.get('bits', calc_bits)
    if bits < calc_bits:
        raise f"Not enough bits for values ({calc_bits} needed) in {name}"
    
    symbols = {}
    sym_width = 0
    val = 0
    for v in desc['values']:
        symbol = v
        if isinstance(v, dict):
            symbol, val = list(v.items())[0]
        symbols[symbol] = val
        val = val + 1
        sym_width = max(sym_width, len(v))

    return {
        'name': name,
        'bits': bits,
        'prefix': desc.get('prefix', ''),
        'sym_width': sym_width,
        'symbols': symbols 
    }

def sorted_symbols(syms):
    return sorted(syms.items(), key=lambda x: x[1])

def enum_typedef(fp, desc):
    bits = desc['bits']
    name = desc['name']
    syms = sorted_symbols(desc['symbols'])
    width = desc['sym_width']
    prefix = desc['prefix']
    fp.write( f"typedef enum bit [{bits - 1}:0] {{\n" )
    first = True
    for symbol, value in syms:
        if not first:
            fp.write(",\n")
        first = False
        fp.write( f"    {prefix}{symbol:{width}} = {bits}'b{value:0{bits}b}")
    fp.write( f"\n}} {name} /* verilator public */;\n\n" )

def enum_stp(fp, desc):
    bits = desc['bits']
    name = desc['name']
    syms = sorted_symbols(desc['symbols'])
    fp.write(f'  <table name="{name}" width="{bits}">\n')
    for symbol, value in syms:
        fp.write( f'    <symbol name="{symbol}" value="{value:0{bits}b}" />\n')
    fp.write('  </table>\n')


def enum_filter(fp, desc):
    bits = desc['bits']
    hexdigits = (bits + 3) // 4
    syms = sorted_symbols(desc['symbols'])
    for symbol, value in syms:
        fp.write( f"{value:0{bits}b} {symbol}\n")
        fp.write( f"{value:0{hexdigits}x} {symbol}\n")


input_names = ['hdl/enums.yaml', 'hdl/opcode_enums.yaml']
output_name = 'hdl/enums.svh'
filter_dir = 'hdl/filters'
stp_name = 'hdl/filters/enum.stp'

enums_desc = {}
for input_name in input_names:
    desc = yaml.safe_load(open(input_name, 'r'))
    enums_desc.update(desc)

enums = [ process_enum(k, v) for k, v in enums_desc.items() ]

with open(output_name, 'wt') as fp:
    fp.write("// Auto-generated from {input_nane} by {sys.argv[0]}\n")
    fp.write("// DO NOT EDIT\n\n")

    for e in enums:
        enum_typedef(fp, e)

for e in enums:
    filename = f"{e['name']}.txt"
    with open(os.path.join(filter_dir, filename), 'wt') as fp:
        fp.write("# Auto-generated from {input_nane} by {sys.argv[0]}\n")
        fp.write("# DO NOT EDIT\n")
        enum_filter(fp, e)

with open( stp_name, "wt" ) as fp:
    fp.write("<session>\n<mnemonics>\n")

    for e in enums:
        enum_stp(fp, e)

    fp.write("</mnemonics>\n</session>\n")

